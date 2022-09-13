#! /usr/bin/env perl
use strict;
use Future;
use warnings;
use Test::More;
use Data::Dumper;
use feature 'say';
use IO::Async::Loop;
use Test::Exception;
use String::Util 'trim';
use IO::Async::Timer::Countdown;

require_ok('TinyTools::HTTP::Async::Request');

my $get
    = TinyTools::HTTP::Async::Request->GET("http://metacpan.org/search");
my $post = TinyTools::HTTP::Async::Request->POST("http://metacpan.org")
    ->json( { hello => 'world' } );
my $put = TinyTools::HTTP::Async::Request->PUT("http://metacpan.org/")
    ->xml( { hello => 'world' } );
my $delete
    = TinyTools::HTTP::Async::Request->DELETE("http://metacpan.org/");

is( $get->method,    'GET',    'Method shoud eq GET' );
is( $post->method,   'POST',   'Method shoud eq POST' );
is( $put->method,    'PUT',    'Method shoud eq PUT' );
is( $delete->method, 'DELETE', 'Method shoud eq DELETE' );

is( $post->get_header('Content-type'),
    'application/json', 'Check header in POST request' );
is( $put->get_header('Content-type'),
    'application/xml', 'Check header in PUT request' );

lives_ok { $get->query_form( 'q' => 'Moose' ) }
'Set query params to GET request';

is( $get->endpoint, '/search?q=Moose', 'Check builded url' );

is( $get->as_string,
    'GET /search?q=Moose HTTP/1.0' . "\r\n"
        . 'Host: metacpan.org' . "\r\n" . "\r\n",
    'Check GET request'
);

is( trim( $post->as_string ),
    trim(
              'POST / HTTP/1.0' . "\r\n"
            . 'Host: metacpan.org' . "\r\n"
            . 'Content-length: 17' . "\r\n"
            . 'Content-type: application/json'
            . "\r\n\r\n"
            . '{"hello":"world"}'
    ),
    'Check POST request'
);

my $error = undef;
my $end   = 0;

ok( my $request = TinyTools::HTTP::Async::Request->GET(
        "http://docs.adaptivecomputing.com/9-0-1/MWS/Content/topics/moabWebServices/7-references/clientCodeSamples/perl.htm"
    )->set_timeout(1),
    'Make real GET request'
);

my $response_chunks = '';

$request->once(
    'response',
    sub {
        my $response = shift;

        $response->on( 'data', sub { $response_chunks .= shift; } );
    }
)->on( 'end', sub { $end = 1; } )
    ->on( 'error', sub { $error = shift; say $error } );

ok( my $response = $request->send->await->result, 'Wait result' );

is( $response->status_code, 200, 'Check status code' );
is( $response->body, $response_chunks,
    'Check that catched by handler content eq thet handled via listener' );

&done_testing;
