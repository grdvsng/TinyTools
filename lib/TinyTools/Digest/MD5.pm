package TinyTools::Digest::MD5;
{
    use strict;
    use warnings;
    use Digest::MD5;
    use Data::Dumper;
    use Exporter 'import';
    use feature qw( signatures );

    our @EXPORT_OK = qw( md5sum );

    sub md5sum ($item) {
        my $ctx   = Digest::MD5->new;
        my $terse = $Data::Dumper::Terse;

        $Data::Dumper::Terse = 1;

        $ctx->add( Dumper($item) );

        my $hex = $ctx->hexdigest;

        $Data::Dumper::Terse = $terse;

        return $hex;
    }
};
1;
