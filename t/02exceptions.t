#!/usr/bin/perl -w

use strict;

use Test::More tests => 24;

use Config::XPath;

my $e;

$e = Config::XPath::Exception->new( "Testing" );
ok( defined $e, 'defined $e Config::XPath::Exception' );
is( ref $e, "Config::XPath::Exception", 'ref $e Config::XPath::Exception' );
isa_ok( $e, "Error", '$e->isa' );
is( "$e", "Testing", '"$e"' );

$e = Config::XPath::Exception->new( "Testing", "/some/path" );
ok( defined $e, 'defined $e Config::XPath::Exception' );
is( ref $e, "Config::XPath::Exception", 'ref $e Config::XPath::Exception' );
isa_ok( $e, "Error", '$e->isa' );
is( "$e", "Testing at path /some/path", '"$e"' );

$e = Config::XPath::ConfigNotFoundException->new( "Testing" );
ok( defined $e, 'defined $e Config::XPath::ConfigNotFoundException' );
is( ref $e, "Config::XPath::ConfigNotFoundException", 'ref $e Config::XPath::ConfigNotFoundException' );
isa_ok( $e, "Config::XPath::Exception", '$e->isa' );
is( "$e", "Testing", '"$e"' );

$e = Config::XPath::BadConfigException->new( "Testing" );
ok( defined $e, 'defined $e Config::XPath::BadConfigException' );
is( ref $e, "Config::XPath::BadConfigException", 'ref $e Config::XPath::BadConfigException' );
isa_ok( $e, "Config::XPath::Exception", '$e->isa' );
is( "$e", "Testing", '"$e"' );

$e = Config::XPath::NoDefaultConfigException->new();
ok( defined $e, 'defined $e Config::XPath::NoDefaultConfigException' );
is( ref $e, "Config::XPath::NoDefaultConfigException", 'ref $e Config::XPath::NoDefaultConfigException' );
isa_ok( $e, "Config::XPath::Exception", '$e->isa' );
is( "$e", "No default configuration loaded", '"$e"' );

$e = Config::XPath::NoDefaultConfigException->new( "/some/path" );
ok( defined $e, 'defined $e Config::XPath::NoDefaultConfigException' );
is( ref $e, "Config::XPath::NoDefaultConfigException", 'ref $e Config::XPath::NoDefaultConfigException' );
isa_ok( $e, "Config::XPath::Exception", '$e->isa' );
is( "$e", "No default configuration loaded at path /some/path", '"$e"' );
