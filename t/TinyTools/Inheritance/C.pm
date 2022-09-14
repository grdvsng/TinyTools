package C;
{
    use strict;
    use FindBin;
    use warnings;
    use feature 'say';
    use lib "$FindBin::Bin";

    use parent 'A';

    sub tree {
        my $cls    = shift;
        my $single = shift;

        $cls->SUPER::tree if !$single;

        say( sprintf( "| %s |", __PACKAGE__ ) );
    }
};
1;
