use ExtUtils::MakeMaker;

WriteMakefile(
    'AUTHOR'         => 'XAO Inc. <alves@xao.com>',
    'ABSTRACT'       => 'Set of templates for creating eCommerce site using XAO::Web',
    'NAME'           => 'XAO::Commerce',
    'VERSION_FROM'   => 'Commerce.pm',
    'PREREQ_PM'      => {
        'XAO::Base'         => '1.03',
        'XAO::FS'           => '1.03',
        'XAO::DO::Catalogs' => '1.0',
        'XAO::Web'          => '1.03',
        'Test::Unit'        => '0.14',
    }
);

sub MY::postamble {

    <<EOT;
config::	README

README:	Commerce.pm
	pod2text Commerce.pm > README

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
