use ExtUtils::MakeMaker;

##
# This is the version for XAO::Base, should be updated manually.
#
my $version='1.0';

##
# Trying to find out current configuration. If it is saved in file -
# retrieving and asking otherwise.
#
my ($homedir,$config_version);
my $ask=0;
if(open(F,".config")) {
    while(<F>) {
        next unless /^(\w+)\s+(.*?)[\s\r\n]+$/s;
        my ($cmd,$value)=($1,$2);
        if($cmd eq 'homedir') {
            $homedir=$value;
        }
        elsif($cmd eq 'version') {
            $config_version=$value;
        }
    }
    close(F);
}
$ask=1 unless $homedir;
while($ask) {
    my $notes;
    if(!$homedir) {
        eval { require XAO::Base };
        if(!$@) {
            $homedir=$XAO::Base::homedir;
            my $version=$XAO::Base::VERSION;
            $notes=<<EOT;

The default choice is where the earlier version ($version) of XAO was installed.
It is recommended to use the same directory for all installations on the
same computer - otherwise you will need to move your projects to the new
directory.
EOT
        }
    }
    $homedir='/usr/local/xao' unless $homedir;
    print <<EOT;
XAO::Base needs a directory for project specific configuration values,
objects, templates etc.$notes

EOT
    print "Directory name ? [$homedir] ";
    (my $hd=<STDIN>) =~ s/[\s\n\r]//sg;
    $hd=~s/^\s*(.*?)\s*$/$1/;
    $hd=~s/^~\//$ENV{HOME}\//;
    if($hd && substr($hd,0,1) ne '/') {
        print "\nBad path ($hd)!\n\n";
        next;
    }
    $homedir=$hd if $hd;

    print <<EOT;

The following directory structure will be used:
$homedir/cgi-bin   - web server handlers
$homedir/projects  - projects root directory
$homedir/templates - default templates

EOT
    print "Is that OK? [Y/n] ";
    (my $answer=<STDIN>) =~ s/[\s\r\n]//sg;
    last unless lc(substr($answer,0,1)) eq 'n';
}

if(!$config_version || $config_version ne $version) {
    open(F,"> .config") || die "Cannot write .config: $!\n";
    print F "homedir $homedir\n";
    print F "version $version\n";
    close(F);
    print "\nConfiguration saved into .config\n\n";
}

WriteMakefile(
    'NAME'          => 'XAO::Base',
    'VERSION'       => $version,
    'PREREQ_PM' => {
        'Error' => '0.13',
    },
    'PL_FILES'      => {
        'Base.PL' => '$(INST_LIB)/XAO/Base.pm',
    }
);

sub MY::postamble
{ <<EOT;

install::
	[ -d $homedir ] || mkdir $homedir && chmod 755 $homedir

EOT
}
