package TinyTools::File::Utils;
{
    use strict;
    use Encode;
    use warnings;
    use JSON::PP;
    use Carp     'confess';
    use Exporter 'import';
    use feature  'signatures';

    our @EXPORT_OK = qw( read_file read_json write_file write_json );

    sub read_file( $path, $encoding="UTF-8" )
    {
        my $content = '';

        open(my $fh,"<:encoding($encoding)", $path ) or confess "Error opening $path: $!";

        $content .= $_ while ( <$fh> );

        close( $fh );

        return $content;
    }

    sub write_file( $path, $data, $encoding="UTF-8" )
    {
        my $content = '';

        `echo >> $path` if ! -e $path;

        open( my $fh,">:encoding($encoding)", $path ) or confess "Error opening $path: $!";

        print( $fh $data );

        close( $fh );

        return $content;
    }

    sub read_json( $path )
    {
        return JSON::PP->new->canonical->utf8->decode( 
            read_file( $path ),     
        );
    }

    sub write_json( $path, $data, $pretty )
    {
        my $builder = JSON::PP->new->utf8->canonical;

        $builder = $builder->pretty if $pretty;

        write_file( $path, $builder->encode( $data ) );
    }
};
1;