#!/usr/bin/perl -w

use strict;

use Test::More tests => 25;
use Test::Exception;

use Config::XPath;

throws_ok( sub { get_config_string( "/data/aaa/bbb" ) },
           'Config::XPath::NoDefaultConfigException',
           'no default config throws exception' );

read_default_config( "t/data.xml" );

my $s;

$s = get_config_string( "/data/aaa/bbb" );
is( $s, "Content", 'content' );

throws_ok( sub { $s = get_config_string( "/data/nonexistent" ) },
           'Config::XPath::ConfigNotFoundException',
           'nonexistent throws exception' );

throws_ok( sub { $s = get_config_string( "/data/eee/ff" ) },
           'Config::XPath::BadConfigException',
           'multiple nodes throws exception' );

throws_ok( sub { $s = get_config_string( "/data/eee" ) },
           'Config::XPath::BadConfigException',
           'multiple children throws exception' );

throws_ok( sub { $s = get_config_string( "/data/ggg" ) },
           'Config::XPath::BadConfigException',
           'non-text throws exception' );

throws_ok( sub { $s = get_config_string( "/data/comment()" ) },
           'Config::XPath::BadConfigException',
           'unrepresentable throws exception' );

$s = get_config_string( "/data/empty" );
is( $s, "", 'empty' );

my $aref;

$aref = get_config_attrs( "/data/ccc/dd[\@name=\"one\"]" );
ok( defined $aref, 'attributes hash defined'  );
is_deeply( $aref, { '+' => "dd", name => "one", value => "1" }, 'attribute values' );

throws_ok( sub { $aref = get_config_attrs( "/data/nonexistent" ) },
           'Config::XPath::ConfigNotFoundException',
           'missing attrs throws exception' );

throws_ok( sub { $aref = get_config_attrs( "/data/ccc/dd" ) },
           'Config::XPath::BadConfigException',
           'multiple attrs throws exception' );

throws_ok( sub { $aref = get_config_attrs( "/data/aaa/\@str" ) },
           'Config::XPath::BadConfigException',
           'attrs of attrs throws exception' );

my @l;

@l = get_config_list( "/data/ccc/dd/\@name" );
is_deeply( \@l, [ qw( one two ) ], 'list of attrs values' );

@l = get_config_list( "/data/nonexistent" );
is_deeply( \@l, [], 'list of missing values' );

throws_ok( sub { @l = get_config_list( "/data/comment()" ) },
           'Config::XPath::BadConfigException',
           'list of comment throws exception' );

my $sub = get_sub_config( "/data/ccc" );
ok( defined $sub, 'subconfig defined' );

$s = $sub->get_config_string( "dd[\@name=\"one\"]/\@value" );
is( $s, "1", 'subconfig string' );

$aref = $sub->get_config_attrs( "dd[\@name=\"one\"]" );
is_deeply( $aref, { '+' => "dd", name => "one", value => "1" }, 'subconfig attrs' );

@l = $sub->get_config_list( "dd/\@name" );
is_deeply( \@l, [ qw( one two ) ], 'subconfig list' );

my @subs = get_sub_config_list( "/data/ccc/dd" );
is( scalar @subs, 2, 'number of subconfig list' );
ok( defined $subs[0], 'defined subconfig[0]' );
is( ref $subs[0], 'Config::XPath', 'type of subconfig[0]' );
ok( defined $subs[1], 'defined subconfig[1]' );
is( ref $subs[1], 'Config::XPath', 'type of subconfig[1]' );
