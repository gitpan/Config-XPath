#!/usr/bin/perl -w

use strict;

use Test::More tests => 7;
use Test::Exception;

use Config::XPath;

my $c;

$c = Config::XPath->new( "t/data.xml" );
ok( defined $c, 'defined $c' );
is( ref $c, "Config::XPath", 'ref $c' );

my $aref;

$aref = $c->get_attrs( "/data/ccc/dd[\@name=\"one\"]" );
ok( defined $aref, 'attributes defined $aref' );
is_deeply( $aref, { '+' => "dd", name => "one", value => "1" }, 'attributes values' );

throws_ok( sub { $aref = $c->get_attrs( "/data/nonexistent" ) },
           'Config::XPath::ConfigNotFoundException',
           'get_config_attrs nonexistent throws exception' );

throws_ok( sub { $aref = $c->get_attrs( "/data/ccc/dd" ) },
           'Config::XPath::BadConfigException',
           'get_config_attrs multiple nodes throws exception' );

throws_ok( sub { $aref = $c->get_attrs( "/data/aaa/\@str" ) },
           'Config::XPath::BadConfigException',
           'get_config_attrs attribute throws exception' );
