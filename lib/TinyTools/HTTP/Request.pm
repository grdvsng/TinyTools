package TinyTools::HTTP::Request;
{
    use URI;
    use Moose;
    use JSON::PP;
    use XML::Hash;
    use IO::Socket;
    use Data::Dumper;
    use Log::Log4perl;
    use feature 'say';
    use Carp 'confess';
    use TinyTools::HTTP::Response;
    use TinyTools::HTTP::Constants;
    use Types::Standard qw(Enum);
    use URI::Split      qw(uri_join);
    use MooseX::Types::PortNumber 'PortNumber';

    has 'uri' => (
        is       => 'ro',
        isa      => 'URI::http',
        required => 1,
        handles  => [qw( host path port query query_form )],
    );

    has 'method' => (
        is      => 'ro',
        isa     => Enum [@TinyTools::HTTP::Constants::METHODS],
        default => 'GET'
    );

    has 'data' => ( is => 'rw', isa => 'Str' );

    has 'endpoint' => (
        is      => 'ro',
        isa     => 'Str',
        lazy    => 1,
        default => sub {
            my $self = shift;

            return !$self->query
                ? $self->path
                : $self->path . '?' . $self->query;
        }
    );

    has 'timeout' => ( is => 'ro', isa => 'Int', default => 2 );

    has 'socket' => (
        is      => 'ro',
        isa     => 'Maybe[IO::Socket]',
        lazy    => 1,
        default => sub {
            my $self = shift;

            $self->logger->debug(
                "Crete socker " . $self->host . ":" . $self->port );

            return new IO::Socket::INET(
                PeerAddr => $self->host,
                PeerPort => $self->port . '',
                Proto    => 'tcp',
                Timeout  => $self->timeout
            );
        }
    );

    has 'headers' => (
        is      => 'rw',
        isa     => 'HashRef[ArrayRef[Str|Int]|Int|Str|Undef]',
        traits  => ['Hash'],
        handles => {
            has_header     => 'exists',
            get_header     => 'get',
            has_no_headers => 'is_empty',
            header_count   => 'count',
            delete_header  => 'delete',
            header_pairs   => 'kv',
        },
        default => sub { {} },
    );

    has 'logger' => (
        is      => 'ro',
        isa     => 'Log::Log4perl::Logger',
        default => sub {
            my $logger
                = Log::Log4perl->get_logger( '' . ref(__PACKAGE__) );

            $logger->level(
                Log::Log4perl::Level::to_priority(
                    $ENV{APP_LOG_LEVEL} || 'DEBUG'
                )
            );

            return $logger;
        }
    );

    sub set_header {
        my $self   = shift;
        my $key    = ucfirst( lc(shift) );
        my $value  = shift;
        my $unique = shift || 0;

        if ( exists $self->headers->{$key} && !$unique ) {
            $self->headers->{$key}
                = [ @{ $self->headers->{$key} }, $value ];
        } else {
            $self->headers->{$key} = $value;
        }

        return $self;
    }

    sub chunks {
        my $self   = shift;
        my @buffer = ();

        push( @buffer,
                  $self->method . " "
                . ( $self->endpoint || '/' )
                . " HTTP/1.0\r\n" );

        push( @buffer, 'Host: ' . $self->host . "\r\n" );

        $self->set_header( 'Content-length', length( $self->data ), 1 )
            if $self->data;

        for my $title ( keys( %{ $self->headers } ) ) {
            my $values = $self->get_header($title);
            my @values = ref $values eq "ArrayRef" ? @$values : ($values);

            for my $value (@values) {
                my $header
                    = !defined($value)
                    ? $title
                    : $title . ": " . $value . "\r\n";

                push( @buffer, $header );
            }
        }

        push( @buffer, "\r\n" );

        push( @buffer, $self->data ) if $self->data;

        return \@buffer;
    }

    sub as_string {
        return join( '', @{ $_[0]->chunks } );
    }

    sub send {
        my $self = shift;
        my $sock = $self->socket;

        confess "Could not create socket: $!" unless $sock;

        for my $chunk ( @{ $self->chunks } ) {
            $self->logger->debug($chunk);

            print( $sock $chunk );
        }

        my $response
            = TinyTools::HTTP::Response->new( { socket => $sock } );

        close($sock);

        return $response;
    }

    sub FROM_URL {
        my $cls    = shift;
        my $uri    = shift;
        my $method = shift || 'GET';
        my $data   = shift;

        confess "uri param must be typeof URI" if ref $uri ne "URI::http";

        my $params = { uri => $uri, method => $method };

        $params->{data} = $data if $data;

        return $cls->new($params);
    }

    sub FROM_STR {
        my $cls    = shift;
        my $url    = URI->new(shift);
        my $method = shift || 'GET';
        my $data   = shift;

        return $cls->FROM_URL( $url, $method, $data );
    }

    sub GET {
        my $cls = shift;

        return $cls->FROM_STR( shift, 'GET' );
    }

    sub DELETE {
        my $cls = shift;

        return $cls->FROM_STR( shift, 'DELETE' );
    }

    sub POST {
        my $cls = shift;

        return $cls->FROM_STR( shift, 'POST', shift );
    }

    sub PUT {
        my $cls = shift;

        return $cls->FROM_STR( shift, 'PUT', shift );
    }

    sub json {
        my $self = shift;
        my $data = encode_json(shift);

        $self->set_header( 'Content-type', 'application/json' );
        $self->data($data);

        return $self;
    }

    sub xml {
        my $self = shift;
        my $xml  = XML::Hash->new;
        my $data = $xml->fromHashtoXMLString(shift);

        $self->set_header( 'Content-type', 'application/xml' );
        $self->data($data);

        return $self;
    }
};
1;
