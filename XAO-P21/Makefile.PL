use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'XAO::P21',
    'VERSION_FROM' => 'P21.pm', # finds $VERSION
    PREREQ_PM => {
        'XAO::Base' => 1.0,
        'IO' => 1.20,
        },
);
