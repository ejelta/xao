# Copyright (c) 1997-2001 XAO Inc.
###############################################################################
use ExtUtils::MakeMaker;

use XAO::Base qw($homedir);

WriteMakefile(
    'ABSTRACT'      => 'XAO Catalogs',
    'AUTHOR'        => 'XAO Inc. http://xao.com/',
    'NAME'          => 'XAO::Catalogs',
    'VERSION_FROM'  => 'Catalogs.pm',
    'PREREQ_PM'     => {
        'XAO::Base'     => '1.01',
        'XAO::FS'       => '1.01',
    },
    'INSTALLBIN'	=> $homedir . '/bin',
    'INSTALLSCRIPT'	=> $homedir . '/handlers',
);
