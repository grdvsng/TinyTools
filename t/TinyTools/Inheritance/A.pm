package A;
{
    use strict;
    use warnings;
    use feature 'say';

    sub tree {
        say( sprintf( "| %s |", __PACKAGE__ ) );
    }
};
1;
