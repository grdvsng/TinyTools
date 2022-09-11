#! /usr/bin/env perl

use DBI;
use strict;
use warnings;
use Test::More;
use File::Spec;
use Data::Dumper;
use feature 'say';
use File::Basename;
use Test::Exception;
use Test::Exception;
use IO::Async::Loop;
use File::Temp 'tempdir';
use IO::Async::Timer::Countdown;

use_ok('TinyTools::DB::Query::Stream');

my $TEST_DB_FILE
    = File::Spec->join( dirname(&tempdir), "TinyTools.test.db" );

my $TEST_TABLE_NAME = 'test';

my $TEST_ROWS_COUNT = 1_000_000;

my $get_dbh = sub {
    return DBI->connect(
        "dbi:SQLite:uri=file:$TEST_DB_FILE?mode=rwc",
        "", "",
        {   PrintError => 0,
            PrintWarn  => 0,
            RaiseError => 1,
            AutoCommit => 1,
        }
    );
};

unlink($TEST_DB_FILE);

ok( my $dbh = $get_dbh->(), "Connect to db" );

lives_ok {
    $dbh->do( "
CREATE TABLE $TEST_TABLE_NAME(
    rowid INTEGER PRIMARY KEY,    
    title TEXT UNIQUE, 
    description TEXT,
    price INTEGER
)
" )
}
"Create test table";

my $inserted = 0;

ok( my $stream = TinyTools::DB::Query::Stream->insert(
        dbh            => $get_dbh,
        table          => $TEST_TABLE_NAME,
        max_store_size => 10_000,
    ),
    "Create insert stream"
);

$stream->on(
    'insert',
    sub {
        $inserted += shift;
        diag("inserted $inserted test rows\r");
    }
);

$stream->on(
    'error',
    sub {
        warn shift;
        exit;
    }
);

for my $i ( 1 .. $TEST_ROWS_COUNT ) {
    $stream->push(
        { title => "item-$i", description => "...", price => rand(1000) }
    );
}

$stream->end;

my ($count) = @{
    $dbh->selectcol_arrayref(
        "SELECT COUNT(*) as total FROM $TEST_TABLE_NAME")
};

is( $count, $TEST_ROWS_COUNT, "check inserted count" );

ok( my $pool = TinyTools::DB::Query::Stream->select(
        dbh            => $get_dbh,
        table          => $TEST_TABLE_NAME,
        max_store_size => 100_000,
        fields         => [qw( rowid )],
        order          => { -asc => 'rowid' },
    ),
    "Create select stream"
);

my $last_rowid = 0;

$pool->on(
    'data',
    sub {
        my $row = shift;

        $last_rowid = $row->{rowid};
    }
);

$pool->on(
    'error',
    sub {
        warn shift;
        $pool->stop;
        exit;
    }
);

my $loop  = IO::Async::Loop->new;
my $timer = IO::Async::Timer::Countdown->new(
    delay     => 20,
    on_expire => sub {
        diag("Timeout end(whaiter of select)");
        $loop->stop;
    },
);

$timer->start;

$loop->add($timer);

$loop->run;

is( $last_rowid, $TEST_ROWS_COUNT,
    'Check that select stream handle all rows' );

diag("Test error catchig");

ok( my $fail_stream = TinyTools::DB::Query::Stream->select(
        dbh            => $get_dbh,
        table          => $TEST_TABLE_NAME,
        max_store_size => 5,
        fields         => [qw( rowidss )],
        order          => { -asc => 'rowidss' },
    ),
    "Create bad select stream"
);

my $error = '';

$fail_stream->once( 'error', sub { $error = shift; } );

$loop  = IO::Async::Loop->new;
$timer = IO::Async::Timer::Countdown->new(
    delay     => 5,
    on_expire => sub {
        $loop->stop;
    },
);

$timer->start;

$loop->add($timer);

$loop->run;

ok( $error ne '', 'Check that error catched' );

unlink($TEST_DB_FILE);

&done_testing;
