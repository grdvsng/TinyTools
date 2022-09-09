#! /usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Data::Dumper;


use_ok('TinyTools::Array::Utils');

my @array = ( 'hello', 'world' );

TinyTools::Array::Utils::splice( 1, 0, 'dear', \@array );

ok( eq_array( [ 'hello', 'dear', 'world' ], [@array] ),
    "Should be equal array [ 'hello', 'dear', 'world' ]"
);

TinyTools::Array::Utils::splice( 2, 1, 'friend', \@array );

ok( eq_array( [ 'hello', 'dear', 'friend' ], [@array] ),
    "Should be equal array [ 'hello', 'dear', 'friend' ]"
);

TinyTools::Array::Utils::splice( 0, 2, 'bye', \@array );

ok( eq_array( [ 'bye', 'friend' ], \@array ),
    "Should be equal array [ 'bye', 'friend' ]"
);

# ? Last
TinyTools::Array::Utils::splice( -1, 0, '!', \@array );

ok( eq_array( [ 'bye', 'friend', '!' ], [@array] ),
    "Should be equal array [ 'bye', 'friend', '!' ]"
);

# ? Last pre pre last
TinyTools::Array::Utils::splice( -3, 1, 'mom', \@array );

ok( eq_array( [ 'bye', 'mom', '!' ], \@array ),
    "Should be equal array [ 'bye', 'mom', '!' ]"
);

&done_testing;

