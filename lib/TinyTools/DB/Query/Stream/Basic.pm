package TinyTools::DB::Query::Stream::Basic;
{
    use Moose;
    use Future;
    use Data::Dumper;
    use feature 'say';
    use Carp 'confess';
    use IO::Async::Timer::Periodic;

    extends 'TinyTools::Event::Emiter';

    has 'dbh' => ( isa => 'CodeRef', is => 'rw' );
    has 'closed' => ( isa => 'Bool', is => 'rw', default => 0 );

    sub new {
        my $cls  = shift;
        my $self = $cls->SUPER::new(@_);

        $self->once(
            'end',
            sub {
                my $self = shift;

                $self->closed(1);
                $self->loop->stop;
                $self->remove_all_listeners;
            }
        );

        $cls->meta->add_before_method_modifier(
            _write => sub {
                my $self = shift;
                
                confess "Stream allready ended" if $self->closed;
            },
        );

        return $self;
    }

    sub _write { }

    sub end {
        my $self = shift;

        $self->emit( 'end', $self );
    }
};
1;
