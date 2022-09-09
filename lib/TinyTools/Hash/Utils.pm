package TinyTools::Hash::Utils;
{
    use strict;
    use warnings;
    use Exporter 'import';
    use TinyTools::Hash::Set;
    use feature qw( signatures say );

    our @EXPORT_OK = qw( dedupe_values );

    sub dedupe_values (%hash) {
        my %result = ();
        my @keys   = keys(%hash);
        my $store  = TinyTools::Hash::Set->new;

        while ( my $key = pop(@keys) ) {
            my $value = delete $hash{$key};

            if ( !$store->contains($value) ) {
                $result{$key} = $value;

                $store->insert($value);
            }
        }

        return %result;
    }
};
1;
