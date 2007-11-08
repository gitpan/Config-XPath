#!/usr/bin/perl -w

use strict;

use Test::More tests => 9;
use Test::Exception;
use Test::Warn;

use Config::XPath;

my $c;

$c = Config::XPath->new( filename => "t/data.xml" );
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

warning_is( sub { $aref = $c->get_config_attrs( "/data/ccc/dd[\@name=\"one\"]" ) },
            "Using static function 'get_config_attrs' as a method is deprecated",
            'using static function as method gives warning' );

is_deeply( $aref, { '+' => "dd", name => "one", value => "1" }, 'attributes values from static function' );
