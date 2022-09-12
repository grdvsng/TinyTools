#! /usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Data::Dumper;
use feature 'say';
use Test::Exception;
use Proc::ProcessTable;
use Devel::Size 'total_size';

my $LOOP_TIME = 2;
my $t         = Proc::ProcessTable->new();

my $get_ram = sub {
    foreach my $p ( @{ $t->table } ) {
        if ( $p->pid() == $$ ) {
            return $p->size();
            last;
        }
    }
};

my $start_ram = $get_ram->();

sub with_leaks() {
    my $start = time;

    while (1) {
        my $a = {};

        $a->{func} = sub {
            $a->{cnt}++;
        };

        $a->{func}->();

        if ( time - $start > $LOOP_TIME ) {
            return $get_ram->();
        }
    }
}

sub without_leaks() {
    my $start = time;

    while (1) {
        my $a = {};

        $a->{func} = sub {
            $_[0]->{cnt}++;
        };

        $a->{func}->();

        if ( time - $start > $LOOP_TIME ) {
            return $get_ram->();
        }
    }
}

my $with_leaks    = &with_leaks - $start_ram;
my $without_leaks = &without_leaks - $with_leaks - $start_ram;

ok( $without_leaks == 0, "Without leaks ram should be 0" );
ok( $with_leaks > 0,     "With leaks ram should greater than 0" );
