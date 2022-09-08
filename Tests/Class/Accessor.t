#! /usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Data::Dumper;
use feature 'say';
use Test::Exception;
use Test::Exception;
use TinyTools::Tests::Class::BasicClass;

lives_ok { BasicClass->category    } 'Category is static';

is( BasicClass->category, "Other", "Check Category value" );

lives_ok { BasicClass->category( "New" ) } 'Update Category';

is( BasicClass->category, "New", "Check Category value" );

dies_ok  { BasicClass->title       } 'Title is non static';
dies_ok  { BasicClass->description } 'Description is non static';
dies_ok  { BasicClass->price       } 'Price is non static';
dies_ok  { BasicClass->count       } 'Count is private';

lives_ok { BasicClass->set_count( 10 ) } 'Set Count';
is( BasicClass->get_count, 10, "Check Count value" );

lives_ok { BasicClass->set_count( 22 ) } 'Set Count';
is( BasicClass->get_count, 22, "Check Count value" );

my $instance = BasicClass->new;

dies_ok  { $instance->category } 'Category is static';

is( $instance->title      , "Item", "Check Title value"       );
is( $instance->price      , 1     , "Check Price value"       );
is( $instance->description, undef , "Check Description value" );

dies_ok  { $instance->count  } 'Count is private';

lives_ok { $instance->description( "New item" ) } 'Set description before instalized';
lives_ok { $instance->price      ( 10         ) } 'Set price';

dies_ok { $instance->title      ( "New" ) } 'Title is read only';
dies_ok { $instance->description( "New" ) } 'Description is read only';
dies_ok { $instance->price      ( undef ) } 'Price is non nullable';

lives_ok{ $instance->price      ( 12 ) } 'Update Price';

is( $instance->price, 12, "Check Price value" );

&done_testing;
