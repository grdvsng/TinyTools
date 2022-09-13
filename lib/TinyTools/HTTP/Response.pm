package TinyTools::HTTP::Response {
    use Moose;
    use feature 'say';
    use TinyTools::HTTP::Parser qw( parse_status parse_header );

    has 'version' =>
        ( is => 'ro', isa => 'Str', writer => '_set_version' );
    has 'status_code' =>
        ( is => 'rw', isa => 'Int', writer => '_set_status_code' );
    has 'status_message' =>
        ( is => 'rw', isa => 'Str', writer => '_set_status_message' );

    has 'socket' => ( is => 'ro', isa => 'IO::Socket', required => 1 );

    has 'body' => (
        is      => 'ro',
        isa     => 'Str',
        writer  => '_set_body',
        default => ''
    );

    has 'headers' => (
        is      => 'rw',
        isa     => 'HashRef[ArrayRef[Str|Int]|Int|Str|Undef]',
        traits  => ['Hash'],
        writer  => '_set_header',
        default => sub { {} },
        handles => {
            has_header     => 'exists',
            get_header     => 'get',
            has_no_headers => 'is_empty',
            header_count   => 'count',
            header_pairs   => 'kv',
        },
    );

    has 'handle' =>
        ( is => 'ro', lazy => 1, default => sub { $_[0]->_read } );

    sub new {
        my $cls  = shift;
        my $self = $cls->SUPER::new(@_);

        return $self;
    }

    sub _read_body {
        my $self = shift;
        my $sock = shift;

        $self->_set_body( $self->body . $_ ) while <$sock>;
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
