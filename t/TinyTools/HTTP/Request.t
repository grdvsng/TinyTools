#! /usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Data::Dumper;
use feature 'say';
use Test::Exception;
use Log::Log4perl qw(:easy);

require_ok('TinyTools::HTTP::Request');

my $get  = TinyTools::HTTP::Request->GET("http://metacpan.org/search");
my $post = TinyTools::HTTP::Request->POST("http://metacpan.org")
    ->json( { hello => 'world' } );
my $put = TinyTools::HTTP::Request->PUT("http://metacpan.org/")
    ->xml( { hello => 'world' } );
my $delete = TinyTools::HTTP::Request->DELETE("http://metacpan.org/");

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

is( $post->as_string,
    'POST / HTTP/1.0' . "\r\n"
        . 'Host: metacpan.org' . "\r\n"
        . 'Content-length: 17' . "\r\n"
        . 'Content-type: application/json'
        . "\r\n\r\n"
        . '{"hello":"world"}',
    'Check POST request'
);

ok( my $response = TinyTools::HTTP::Request->GET(
        "http://docs.adaptivecomputing.com/9-0-1/MWS/Content/topics/moabWebServices/7-references/clientCodeSamples/perl.htm"
    )->send,
    'Make real GET request'
);

is( $response->status_code, 200, 'Check valide response status code' );
is( $response->status_message, 'OK',
    'Check valide response status message' );

&done_testing;
