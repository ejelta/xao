use ExtUtils::MakeMaker;

WriteMakefile( 'AUTHOR'         => 'Andrew Maltsev <am@xao.com>'
             , 'ABSTRACT'       => 'Symphero::Web plugin for viewing .pod files'
             , 'NAME'           => 'Symphero::Objects::PodView'
             , 'DISTNAME'       => 'Symphero-PodView'
             , 'VERSION_FROM'   => 'PodView.pm'
             , 'PREREQ_PM'      => { 'Symphero::Web' => '0.7',
                                     'Pod::Parser' => '1.12',
                                     'IO::String' => '1.01'
                                   }
             );

sub MY::postamble
{ <<EOT;
config::	README

README:	PodView.pm
	pod2text PodView.pm > README

install::
	\$(PERL) -MSymphero::PluginUtils=install_templates \\
		 -e'install_templates("MANIFEST",1)'
	\@echo
	\@echo "Please read the Symphero::Objects::PodView manpage"
	\@echo "for usage instructions."
	\@echo
	\@echo "Good luck!"
	\@echo
EOT
}
