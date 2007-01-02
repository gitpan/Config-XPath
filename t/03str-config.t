#!/usr/bin/perl -w

use strict;

use Test::More tests => 12;
use Test::Exception;

use Config::XPath;

my $c;

$c = Config::XPath->new( "t/data.xml" );
ok( defined $c, 'defined $c' );
is( ref $c, "Config::XPath", 'ref $c' );

my $s;

$s = $c->get_config_string( "/data/aaa/bbb" );
is( $s, "Content", 'content' );

$s = $c->get_config_string( "/data/aaa/\@str" );
is( $s, "hello", 'attribute' );

$s = $c->get_config_string( "/data/eee/ff[\@name=\"one\"]" );
is( $s, "1", 'content by selector' );

$s = $c->get_config_string( "/data/ccc/dd[\@name=\"one\"]/\@value" );
is( $s, "1", 'attribute by selector' );

throws_ok( sub { $s = $c->get_config_string( "/data/nonexistent" ) },
           'Config::XPath::ConfigNotFoundException',
           'nonexistent throws exception' );

throws_ok( sub { $s = $c->get_config_string( "/data/eee/ff" ) },
           'Config::XPath::BadConfigException',
           'multiple nodes throws exception' );

throws_ok( sub { $s = $c->get_config_string( "/data/eee" ) },
           'Config::XPath::BadConfigException',
           'multiple children throws exception' );

throws_ok( sub { $s = $c->get_config_string( "/data/ggg" ) },
           'Config::XPath::BadConfigException',
           'unrepresentable throws exception' );

throws_ok( sub { $s = $c->get_config_string( "/data/comment()" ) },
           'Config::XPath::BadConfigException',
           'comment throws exception' );

$s = $c->get_config_string( "/data/empty" );
is( $s, "", 'empty' );
