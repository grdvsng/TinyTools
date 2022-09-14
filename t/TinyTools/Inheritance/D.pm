package D;
{
    use strict;
    use FindBin;
    use warnings;
    use Data::Dumper;
    use feature 'say';
    use lib "$FindBin::Bin";

    use parent qw( B C );

    sub tree {
        my $cls    = shift;
        my $single = !defined(shift);

        if ($single) {
            $cls->SUPER::tree;
        } else {
            $cls->B::tree;
            $cls->C::tree(1);
        }

        say( sprintf( "| %s |", __PACKAGE__ ) );
    }
};
1;
