#!/usr/bin/perl -w

use strict;

use Test::More tests => 17;

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

eval { $s = $c->get_config_string( "/data/nonexistent" ) };
ok( defined $@, 'nonexistent throws exception' );
is( ref $@, 'Config::XPath::ConfigNotFoundException', 'exception type' );

eval { $s = $c->get_config_string( "/data/eee/ff" ) };
ok( defined $@, 'multiple nodes throws exception' );
is( ref $@, 'Config::XPath::BadConfigException', 'exception type' );

eval { $s = $c->get_config_string( "/data/eee" ) };
ok( defined $@, 'multiple children throws exception' );
is( ref $@, 'Config::XPath::BadConfigException', 'exception type' );

eval { $s = $c->get_config_string( "/data/ggg" ) };
ok( defined $@, 'unrepresentable throws exception' );
is( ref $@, 'Config::XPath::BadConfigException', 'exception type' );

eval { $s = $c->get_config_string( "/data/comment()" ) };
ok( defined $@, 'comment throws exception' );
is( ref $@, 'Config::XPath::BadConfigException', 'exception type' );

$s = $c->get_config_string( "/data/empty" );
is( $s, "", 'empty' );
