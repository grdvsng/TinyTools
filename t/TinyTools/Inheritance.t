#! /usr/bin/env perl
use strict;
use FindBin;
use warnings;
use Test::More;
use Test::Output;
use feature 'say';
use lib "$FindBin::Bin/Inheritance";
use D;


stdout_is { D->tree } "| A |\n| B |\n| D |\n",
    "if B and C have equal method B will use in priority when D extends B,C";

stdout_is { D->tree(1) } "| A |\n| B |\n| C |\n| D |\n",
    "But we can call 1 same method on different parents";

&done_testing;
