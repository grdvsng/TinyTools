package TinyTools::HTTP::Async::Response;
{
    use Moose;
    use Future;
    use feature 'say';
    use MooseX::ClassAttribute;
    use IO::Async::Timer::Periodic;
    use TinyTools::HTTP::Parser qw( parse_status parse_header );

    extends 'TinyTools::HTTP::Response', 'TinyTools::Event::Emiter';

    class_has 'supported_events' => (
        is      => 'rw',
        isa     => 'ArrayRef[Str]',
        default => sub { return [qw( error data end )]; },
    );

    has 'future' => (
        is      => 'ro',
        isa     => 'Future',
        lazy    => 1,
        default => sub { Future->new }
    );

    has 'handle' => (
        is      => 'ro',
        isa     => 'Future',
        lazy    => 1,
        default => sub { $_[0]->_read }
    );

    has 'timer' => (
        is      => 'ro',
        isa     => 'IO::Async::Timer::Periodic',
        lazy    => 1,
        default => sub {
            my $self = shift;

            return IO::Async::Timer::Periodic->new(
                interval       => 0.001,
                first_interval => 0,
                on_tick        => sub {
                    eval {
                        my $sock  = $self->socket;
                        my $chunk = <$sock>;

                        if ( !defined($chunk) ) {
                            $self->emit( 'end', $self );
                        } else {
                            $self->emit( 'data', $chunk );
                            $self->_set_body( $self->body . $chunk );
                        }
                    };

                    $self->throw($@) if $@;
                },
            );
        }
    );

    sub new {
        my $cls  = shift;
        my $self = $cls->SUPER::new(@_);

        $self->on(
            'end',
            sub {
                my $self = shift;

                $self->timer->stop;
                $self->loop->stop;

                $self->future->done( $self->body );
            }
        );

        return $self;
    }

    sub throw {
        my $self    = shift;
        my $message = shift;

        $self->future->fail($message);

        $self->emit( 'error', $message );
        $self->emit( 'end',   $self );
    }

    sub _read_body {
        my $self  = shift;
        my $sock  = shift;
        my $chunk = '';
        my $loop  = $self->loop;
        my $lines = 0;

        $self->timer->start;
        $loop->add( $self->timer );
        $loop->run;

        return $self->future;
    }

    sub _read {
        my $self           = shift;
        my $sock           = $self->socket;
        my $cursor         = 0;
        my $header_started = 1;

        while (<$sock>) {
            if ( $cursor == 0 ) {
                my ( $v, $c, $m ) = parse_status($_);

                $self->_set_version($v);
                $self->_set_status_code( int($c) );
                $self->_set_status_message($m);
            } elsif ( $_ eq "\r\n" ) {
                return $self->_read_body($sock);
            } else {
                my ( $k, $v ) = parse_header($_);

                $self->_set_header(
                    { %{ $self->headers }, "$k" => $v || undef } );
            }

            $cursor++;
        }
    }
};
1;
