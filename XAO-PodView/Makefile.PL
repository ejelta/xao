use ExtUtils::MakeMaker;

WriteMakefile(
    'AUTHOR'         => 'Andrew Maltsev, XAO Inc. <am@xao.com>',
    'ABSTRACT'       => 'XAO::Web plugin for viewing .pod files',
    'NAME'           => 'XAO::DO::Web::PodView',
    'DISTNAME'       => 'XAO-PodView',
    'VERSION_FROM'   => 'PodView.pm',
    'PREREQ_PM'      => {
        'IO::String'    => '1.01',
        'Pod::Parser'   => '1.12',
        'XAO::Web'      => '1.02',
    }
);

sub MY::postamble
{ <<EOT;
config::	README

README:	PodView.pm
	pod2text PodView.pm > README

install::
	\$(PERL) -MXAO::PluginUtils=install_templates \\
		 -e'install_templates("MANIFEST",1)'
	\@echo
	\@echo "Please read the XAO::DO::Web::PodView manpage"
	\@echo "for usage instructions."
	\@echo
	\@echo "Good luck!"
	\@echo
EOT
}
