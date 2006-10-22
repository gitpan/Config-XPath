#!/usr/bin/perl -w

use strict;

use Test::More tests => 35;

use Config::XPath;

eval { get_config_string( "/data/aaa/bbb" ) };
ok( defined $@, 'no default config throws exception' );
is( ref $@, 'Config::XPath::NoDefaultConfigException', 'exception type' );

read_default_config( "t/data.xml" );

my $s;

$s = get_config_string( "/data/aaa/bbb" );
is( $s, "Content", 'content' );

eval { $s = get_config_string( "/data/nonexistent" ) };
ok( defined $@, 'nonexistent throws exception' );
is( ref $@, 'Config::XPath::ConfigNotFoundException', 'exception type' );

eval { $s = get_config_string( "/data/eee/ff" ) };
ok( defined $@, 'multiple nodes throws exception' );
is( ref $@, 'Config::XPath::BadConfigException', 'exception type' );

eval { $s = get_config_string( "/data/eee" ) };
ok( defined $@, 'multiple children throws exception' );
is( ref $@, 'Config::XPath::BadConfigException', 'exception type' );

eval { $s = get_config_string( "/data/ggg" ) };
ok( defined $@, 'non-text throws exception' );
is( ref $@, 'Config::XPath::BadConfigException', 'exception type' );

eval { $s = get_config_string( "/data/comment()" ) };
ok( defined $@, 'unrepresentable throws exception' );
is( ref $@, 'Config::XPath::BadConfigException', 'exception type' );

$s = get_config_string( "/data/empty" );
is( $s, "", 'empty' );

my $aref;

$aref = get_config_attrs( "/data/ccc/dd[\@name=\"one\"]" );
ok( defined $aref, 'attributes hash defined'  );
is_deeply( $aref, { '+' => "dd", name => "one", value => "1" }, 'attribute values' );

eval { $aref = get_config_attrs( "/data/nonexistent" ) };
ok( defined $@, 'missing attrs throws exception' );
is( ref $@, 'Config::XPath::ConfigNotFoundException', 'exception type' );

eval { $aref = get_config_attrs( "/data/ccc/dd" ) };
ok( defined $@, 'multiple attrs throws exception' );
is( ref $@, 'Config::XPath::BadConfigException', 'exception type' );

eval { $aref = get_config_attrs( "/data/aaa/\@str" ) };
ok( defined $@, 'attrs of attrs throws exception' );
is( ref $@, 'Config::XPath::BadConfigException', 'exception type' );

my @l;

@l = get_config_list( "/data/ccc/dd/\@name" );
is_deeply( \@l, [ qw( one two ) ], 'list of attrs values' );

@l = get_config_list( "/data/nonexistent" );
is_deeply( \@l, [], 'list of missing values' );

eval { @l = get_config_list( "/data/comment()" ) };
ok( defined $@, 'list of comment throws exception' );
is( ref $@, 'Config::XPath::BadConfigException', 'exception type' );

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
