use ExtUtils::MakeMaker;

WriteMakefile(
   NAME => 'Config::XPath',
   VERSION_FROM => 'lib/Config/XPath.pm',
   PREREQ_PM => {
      'XML::XPath' => 0,
      'Error'      => '0.15',
   },
);
