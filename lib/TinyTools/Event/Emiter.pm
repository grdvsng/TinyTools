package TinyTools::Event::Emiter;
{
    use Moose;
    use Future;
    use Carp 'confess';
    use IO::Async::Loop;
    use IO::Async::Function;
    use MooseX::ClassAttribute;
    use TinyTools::Event::Listener;
    use TinyTools::Array::Utils qw( index_of );

    has 'listeners' => (
        is      => 'rw',
        isa     => 'HashRef[Str,ArrayRef[TinyTools::Event::Listener]]',
        writer  => '_set_listeners',
        default => sub { return {}; },
    );

    has 'event_listeners_max_count' => (
        is      => 'rw',
        isa     => 'Int',
        default => 10,
    );

    class_has 'supported_events' => (
        is      => 'rw',
        isa     => 'ArrayRef[Str]',
        default => sub { return []; },
    );

    sub check_event {
        my $self  = shift;
        my $event = shift;
        my $cls   = ref $self;

        my $supported_events = eval( "$cls" . '->supported_events' );

        confess $@ if $@;

        if ( scalar(@$supported_events) > 0
            && index_of( $event, @$supported_events ) == -1 )
        {
            confess 'Event is not supporting';
        }

        return $event;
    }

    sub _add_event_listener {
        my $self     = shift;
        my $event    = $self->check_event(shift);
        my $handler  = shift;
        my $type     = shift;
        my $listener = TinyTools::Event::Listener->new(
            'event'    => $event,
            'sub_type' => $type,
            'handler'  => $handler,
        );

        my $listeners = $self->listeners->{$event} || [];
        my $total     = scalar(@$listeners);

        if ( $total > $self->event_listeners_max_count ) {
            warn
                "Event $event allready has $total listeners, max listeners for event is "
                . $self->event_listeners_max_count;
        } else {
            push( @$listeners, $handler );

            $self->set_listeners(
                { %{ $self->listeners }, "$event" => $listeners, } );
        }

        return $self;
    }

    sub remove_all_listeners {
        my $self = shift;

        $self->set_listeners( {} );
    }

    sub on {
        my $self    = shift;
        my $event   = shift;
        my $handler = shift;

        return $self->_add_event_listener( $event, $handler, 'regular' );
    }

    sub once {
        my $self    = shift;
        my $event   = shift;
        my $handler = shift;

        return $self->_add_event_listener( $event, $handler, 'once' );
    }

    sub emit {
        my $self      = shift;
        my $event     = $self->check_event(shift);
        my @params    = @_;
        my @listeners = @{ $self->listeners->{$event} || [] };
        my $loop      = IO::Async::Loop->new;
        my @promises  = map( {
                my $function = IO::Async::Function->new(
                    code => sub {
                        $_->handler(@_);

                        if ( $_->is_once ) {
                            $_->removed(1);
                        }
                    }
                );

                $loop->add($function);

                $function->call( args => \@params )
        } @listeners );

        Future->wait_all(@promises)->await;

        $self->set_listeners(
            {   %{ $self->listeners },
                "$event" => [ grep( { !$_->removed } @listeners ) ],
            }
        );

        return $self;
    }

    sub remove_event_listener {
        my $self      = shift;
        my $event     = $self->check_event(shift);
        my $handler   = shift;
        my @listeners = grep( { $_ != $handler }
            @{ $self->listeners->{$event} || [] } );

        $self->set_listeners(
            { %{ $self->listeners }, "$event" => \@listeners, } );

        return $self;
    }
};
1;
