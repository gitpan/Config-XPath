#!/usr/bin/perl -w

use strict;

use Test::More tests => 6;
use Test::Exception;

use Config::XPath;

my $c;

$c = Config::XPath->new( "t/data.xml" );
ok( defined $c, 'defined $c' );
is( ref $c, "Config::XPath", 'ref $c' );

my @l;

@l = $c->get_config_list( "/data/ccc/dd/\@name" );
is_deeply( \@l, [ qw( one two ) ], 'list values' );

@l = $c->get_config_list( "/data/eee/ff" );
is_deeply( \@l, [ { name => 'one', '+' => 'ff' }, { name => 'two', '+' => 'ff' } ], 'list node attribute values' );

@l = $c->get_config_list( "/data/nonexistent" );
is_deeply( \@l, [], 'list missing' );

throws_ok( sub { @l = $c->get_config_list( "/data/comment()" ) },
           'Config::XPath::BadConfigException',
           'get_config_list unrepresentable throws exception' );
