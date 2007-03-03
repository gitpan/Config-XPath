#!/usr/bin/perl -w

use strict;

use Test::More tests => 15;
use Test::Exception;

use Config::XPath;

throws_ok( sub { Config::XPath->new( ) },
           'Config::XPath::Exception',
           'no filename throws exception' );

my $c;

$c = Config::XPath->new( filename => "t/data.xml" );
ok( defined $c, 'defined $c' );
is( ref $c, "Config::XPath", 'ref $c' );

my $s;

$s = $c->get_string( "/data/aaa/bbb" );
is( $s, "Content", 'content' );

$s = $c->get_string( "/data/aaa/\@str" );
is( $s, "hello", 'attribute' );

$s = $c->get_string( "/data/eee/ff[\@name=\"one\"]" );
is( $s, "1", 'content by selector' );

$s = $c->get_string( "/data/ccc/dd[\@name=\"one\"]/\@value" );
is( $s, "1", 'attribute by selector' );

$s = $c->get_string( "name(/data/aaa)" );
is( $s, "aaa", 'function' );

throws_ok( sub { $s = $c->get_string( "/data/nonexistent" ) },
           'Config::XPath::ConfigNotFoundException',
           'nonexistent throws exception' );

lives_and( sub {
              $s = $c->get_string( "/data/nonexistent", default => "somevalue" );
              is( $s, "somevalue" );
           },
           'nonexistent with default' );

throws_ok( sub { $s = $c->get_string( "/data/eee/ff" ) },
           'Config::XPath::BadConfigException',
           'multiple nodes throws exception' );

throws_ok( sub { $s = $c->get_string( "/data/eee" ) },
           'Config::XPath::BadConfigException',
           'multiple children throws exception' );

throws_ok( sub { $s = $c->get_string( "/data/ggg" ) },
           'Config::XPath::BadConfigException',
           'unrepresentable throws exception' );

throws_ok( sub { $s = $c->get_string( "/data/comment()" ) },
           'Config::XPath::BadConfigException',
           'comment throws exception' );

$s = $c->get_string( "/data/empty" );
is( $s, "", 'empty' );
