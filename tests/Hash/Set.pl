#! /usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Exception;

require_ok( 'TinyTools::Hash::Set' );

my $hash = new_ok( 'TinyTools::Hash::Set' );

ok( $hash->isEmpty, 'Should be empty' );

ok( $hash->insert( 1 ), 'Insert new uniq elem' );

ok( !$hash->isEmpty, 'Should be not empty' );

is( $hash->length, 1, 'Should have 1 length' );

ok( !$hash->insert( 1 ), 'Insert not uniq elem' );

is( $hash->length, 1, 'Should have 1 length' );

ok( $hash->insert( 2 ), 'Insert uniq elem' );

is( $hash->length, 2, 'Should have 2 length' );

ok( $hash->insert( 3 ), 'Insert uniq elem' );

is( $hash->length, 3, 'Should have 3 length' );

ok( eq_array( $hash->toArray, [ 1, 2, 3 ] ), 'Should be equal array' );

ok( $hash->replace( 2, 4 ), 'Replcae elem to another' );

ok( eq_array( $hash->toArray, [ 1, 4, 3 ] ), 'Should be equal array' );

dies_ok { $hash->replace( 2, 4 ) } '2 not exists!';

is( $hash->remove( 2 ), undef, 'Remove not exists key' );

is( $hash->length, 3, 'Should have 3 length' );

is( $hash->remove( 1 ), 1, 'Remove exists key' );

is( $hash->length, 2, 'Should have 2 length' );

ok( eq_array( $hash->toArray, [ 4, 3 ] ), 'Should be equal array' );

lives_ok { $hash->clear } 'Clear hash';

is( $hash->length, 0, 'Should have 0 length' );

ok( $hash->isEmpty, 'Should be empty' );

&done_testing;