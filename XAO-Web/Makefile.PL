use ExtUtils::MakeMaker;

##
# This is the version for XAO::Web, should be updated manually.
#
my $version='0.9';

WriteMakefile(
    'NAME'          => 'XAO::Web',
    'VERSION'       => $version,
    'PREREQ_PM'     => {
        'Error' => '0.13',
        'XAO::Base' => '0.1',
    },
);

#sub MY::postamble
#{ <<EOT;
#
#install::
#	[ -d $homedir ] || mkdir $homedir && chmod 755 $homedir
#
#EOT
#}
