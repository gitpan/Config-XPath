use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new
  (
   module_name => 'Config::XPath',
   dist_version_from => 'lib/Config/XPath.pm',
   requires => {
                 'Error' => '0.15',
                 'XML::XPath' => 0
               },
   build_requires => {
                 'Test::More' => 0,
                 'Test::Exception' => 0,
                 'Test::Warn' => 0,
               },
   license => 'perl',
   create_makefile_pl => 'traditional',
  );
  
$build->create_build_script;
