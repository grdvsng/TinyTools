#! /usr/bin/env perl
use strict;
use FindBin;
use JSON::PP;
use warnings;
use Test::More;
use Data::Dumper;
use feature 'say';
use Benchmark 'cmpthese';
use TinyTools::Array::Int 'index_of';
use TinyTools::File::Utils 'read_file';

my $FIXTURE_PATH = "$FindBin::Bin/fixtures/ints_list.json";
my $large_array  = read_file($FIXTURE_PATH);
my @large_array  = @{ decode_json($large_array) };

my $cases = [
    [ [ 1, 2, 44, 66, 78, 90 ], 1,  0 ],
    [ [ 1, 2, 44, 66, 78, 90 ], 2,  1 ],
    [ [ 1, 2, 44, 66, 78, 90 ], 44, 2 ],
    [ [ 1, 2, 44, 66, 78, 90 ], 66, 3 ],
    [ [ 1, 2, 44, 66, 78, 90 ], 78, 4 ],
    [ [ 1, 2, 44, 66, 78, 90 ], 90, 5 ],
    [ [ 1, 2, 44, 66, 78, 90 ], 33, -1 ],
    [ \@large_array, 51218,   25609 ],
    [ \@large_array, 1999824, 999912 ],
    [ [],            33,      -1 ],
    [ [1],           1,       0 ],
    [ [ 0, 55 ],     55,      1 ],

];

diag("index_of test");

for my $case (@$cases) {
    my ( $array, $value, $result ) = @$case;

    is( index_of( $array, $value ), $result, "Should return $result" );
}

cmpthese(
    -5,
    {   'TinyTools::Array::Int' => sub {
            index_of( \@large_array, 1999976 );
        },
        'Usual search' => sub {
            for ( my $i = 0; $i < scalar(@large_array); $i++ ) {
                return if $large_array[$i] == 1999976;
            }
        }
    },
);

&done_testing;
