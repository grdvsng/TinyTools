#! /usr/bin/env perl
use strict;
use warnings;
use JSON::PP;
use DateTime;
use Test::More;
use Data::Dumper;
use feature 'say';

use_ok('TinyTools::Hash::Utils');

my @WITHOT_DUPLICATES = sort( { $a <=> $b } ( 0 .. 98 ) );
my $total             = 1_000_000;
my %WITH_DUPLICATES   = ();

$WITH_DUPLICATES{"item$_"} = $_ < 99 ? $_ : 1 for ( 0 .. $total - 1 );

say("Start dedupe $total rows");

my $start    = DateTime->now->epoch;
my %cleaned  = TinyTools::Hash::Utils::dedupe_values(%WITH_DUPLICATES);
my $worktime = DateTime->now->epoch - $start;

say("End dedupe worktime $worktime seconds");

ok( eq_array(
        [@WITHOT_DUPLICATES], [ sort( { $a <=> $b } values(%cleaned) ) ],
    ),
    'Mock should be eq with dedupe'
);

&done_testing;
