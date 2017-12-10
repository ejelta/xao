#!/usr/bin/env perl
use warnings;
use strict;
use ExtUtils::MakeMaker;

WriteMakefile(
    'AUTHOR'         => 'Marcos Alves',
    'ABSTRACT'       => 'Set of templates for creating eCommerce site using XAO::Web',
    'NAME'           => 'XAO::Commerce',
    'VERSION_FROM'   => 'Commerce.pm',
    'PREREQ_PM'      => {
        'XAO::Base'         => '1.04',
        'XAO::FS'           => '1.04',
        'XAO::DO::Catalogs' => '1.01',
        'XAO::Web'          => '1.04',
        'Test::Unit'        => '0.14',
    }
);

sub MY::postamble {

    <<EOT;
config::	README

README:	Commerce.pm
	\@COLUMNS=80 pod2text Commerce.pm > README

install::
	\$(PERL) -MXAO::PluginUtils=install_templates \\
		 -e'install_templates("MANIFEST",1)'
	\@echo
	\@echo "Please read the XAO::Commerce manpage"
	\@echo "for usage instructions."
	\@echo
	\@echo "Good luck!"
	\@echo
EOT
}
