#!/usr/bin/perl -w

use strict;

use Test::More tests => 10;

use Config::XPath;

my $c;

$c = Config::XPath->new( "t/data.xml" );
ok( defined $c, 'defined $c' );
is( ref $c, "Config::XPath", 'ref $c' );

my $aref;

$aref = $c->get_config_attrs( "/data/ccc/dd[\@name=\"one\"]" );
ok( defined $aref, 'attributes defined $aref' );
is_deeply( $aref, { '+' => "dd", name => "one", value => "1" }, 'attributes values' );

eval { $aref = $c->get_config_attrs( "/data/nonexistent" ) };
ok( defined $@, 'get_config_attrs nonexistent throws exception' );
is( ref $@, 'Config::XPath::ConfigNotFoundException', 'exception type' );

eval { $aref = $c->get_config_attrs( "/data/ccc/dd" ) };
ok( defined $@, 'get_config_attrs multiple nodes throws exception' );
is( ref $@, 'Config::XPath::BadConfigException', 'exception type' );

eval { $aref = $c->get_config_attrs( "/data/aaa/\@str" ) };
ok( defined $@, 'get_config_attrs attribute throws exception' );
is( ref $@, 'Config::XPath::BadConfigException', 'exception type' );
