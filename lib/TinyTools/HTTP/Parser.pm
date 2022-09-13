package TinyTools::HTTP::Parser;
{
    use Moose;
    use Exporter 'import';
    use String::Util 'trim';

    our @EXPORT_OK = qw( parse_status parse_header );

    sub parse_status {
        my $line = shift;
        my ( $v, $code, @message ) = split( /\s+/, $line );

        return ( trim($v), $code, trim( join( ' ', @message ) ) );
    }

    sub parse_header {
        my $line = shift;
        my ( $k, @v ) = split( /\: /, $line );

        return ( trim($k), trim( join( ': ', @v ) ) );
    }
};
1;
