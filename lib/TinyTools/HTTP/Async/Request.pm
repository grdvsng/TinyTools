package TinyTools::HTTP::Async::Request;
{
    use Moose;
    use Future;
    use JSON::PP;
    use XML::Hash;
    use IO::Socket;
    use Data::Dumper;
    use feature 'say';
    use Carp 'confess';
    use IO::Socket::INET;
    use String::Util 'trim';
    use IO::Async::Function;
    use MooseX::ClassAttribute;
    use TinyTools::HTTP::Async::Response;

    extends 'TinyTools::HTTP::Request', 'TinyTools::Event::Emiter';

    class_has 'supported_events' => (
        is      => 'rw',
        isa     => 'ArrayRef[Str]',
        default => sub { return [qw( error socket response end )]; },
    );

    has 'response' => (
        is     => 'rw',
        isa    => 'TinyTools::HTTP::Async::Response',
        writer => '_set_response'
    );

    has 'future' => (
        is      => 'ro',
        isa     => 'Future',
        lazy    => 1,
        default => sub { Future->new }
    );

    sub new {
        my $cls  = shift;
        my $self = $cls->SUPER::new(@_);

        $self->on(
            'end',
            sub {
                my $self = shift;
                my $sock = $self->socket;

                close($sock) if $sock;

                $self->loop->stop;
            }
        );

        return $self;
    }

    sub end {
        my $self = shift;

        $self->emit( 'end', $self );
    }

    sub throw {
        my $self    = shift;
        my $message = shift;

        $self->logger->warn($message);

        $self->promise->fail($message);

        $self->emit( 'error', $message );
        $self->emit( 'end',   $self );
    }

    sub send {
        my $self = shift;
        my $sock = $self->socket;

        unless ($sock) {
            $self->throw("Could not create socket: $!");
        } else {
            eval {
                $self->emit( 'socket', $sock );

                for my $chunk ( @{ $self->chunks } ) {
                    $self->logger->debug($chunk) if trim($chunk);

                    print( $sock $chunk );
                }

                my $response
                    = TinyTools::HTTP::Async::Response->new(
                    { socket => $sock } );

                $response->once(
                    'end',
                    sub {
                        $self->emit( 'end', $self );
                    }
                )->on( 'error' => sub { $self->throw(shift); } );

                $self->_set_response($response);
                $self->emit( 'response', $response, $sock );

                $response->handle->on_fail(
                    sub {
                        $self->throw(shift);
                    }
                )->on_done(
                    sub {
                        $self->future->done($response);
                    }
                );
            };

            $self->throw($@) if $@;
        }

        return $self->future;
    }
};
1;
