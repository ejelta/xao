# Copyright (c) 1997-2001 XAO Inc.
###############################################################################
use ExtUtils::MakeMaker;
use ExtUtils::Manifest;

##
# Reading configuration
#
my %d;
if(open(F,'.config')) {
    local($/);
    my $t=<F>;
    close(F);
    eval $t;
}
while(!$d{test_dsn}) {
    print <<EOT;

XAO::Web will need access to a XAO::FS database in order to run tests.
That database will be COMPLETELY DESTROYED AND OVERRIDEN every time you
run 'make test'.

The database have to be created, but it does not matter what it contains.

Please enter access information (brackets contain default values):

EOT
    my $dsn='OS:MySQL_DBI:test_fs';
    print "DSN: [$dsn] ";
    chomp(my $str=<STDIN>);
    if($str) {
        if($str =~ /^\s*(OS:(\w+):(\w+)(;.*?)?)\s*$/) {
            $dsn=$1;
        }
        else {
            die "Incorrect DSN entered!\n";
        }
    }
    chomp(my $user=`whoami`);
    print "User name: [$user] ";
    chomp($str=<STDIN>);
    if($str && $str=~/^\s*(.*?)\s*$/) {
        $user=$1;
    }
    my $pass='';
    print "Password: [$pass] ";
    chomp($str=<STDIN>);
    if($str && $str=~/^\s*(.*?)\s*$/) {
        $pass=$1;
    }

    print <<EOT;

Here is what will be used to connect to the test database
(and DESTROY it):
   DSN:      $dsn
   User:     $user
   Password: $password

EOT
    $|=1;
    print "Does it make sense ? [Y/n] y\b";
    chomp($str=<STDIN>);
    if(!$str || lc($str)=~/y/) {
        open(F,">.config") || die "Can't open .config: $!\n";
        print F <<EOT;
## Feel free to remove or edit that file. It will be re-created on `perl
## Makefile.PL' if removed.
\$d{test_dsn}='$dsn';
\$d{test_user}='$user';
\$d{test_password}='$pass';
EOT
        last;
    }
}

##
# This rather stupid workaround is here because for some reason
# MakeMaker excludes /Config/ files from MAN3PODS
#
my %man3pods;
foreach my $n (keys %{ExtUtils::Manifest::maniread()}) {
    next unless $n =~ '^(Web).pm$' ||
                $n =~ '^lib/XAO/(.*)\.(pm|pod)$';
    my $man=$1;
    $man=~s/\/+/::/g;
    $man='XAO::' . $man;

    open(F,$n) || die "Can't read $n: $!";
    my $pod=0;
    while(<F>) {
        if(/^=(\w+)/) {
            $pod=1;
            last;
        }
    }
    $pod || die "$n ($man) does not have documentation";

    $man3pods{$n}='$(INST_MAN3DIR)/' . $man . '.3';
}


use XAO::Base qw($homedir);

WriteMakefile(
    'ABSTRACT'      => 'XAO Web Developer',
    'AUTHOR'        => 'XAO Inc. http://xao.com/',
    'NAME'          => 'XAO::Web',
    'VERSION_FROM'  => 'Web.pm',
    'PREREQ_PM'     => {
        'Digest::MD5'       => 2.13,
        'MIME::Lite'        => 2.117,
        'Error'             => 0.13,
        'XAO::Base'         => 1.04,
        'XAO::FS'           => 1.04,
        'Text::FormatTable' => 0.01,
    },
    'INSTALLBIN'	=> $homedir . '/bin',
    'INSTALLSCRIPT'	=> $homedir . '/handlers',
    'EXE_FILES'     => [ 'handlers/xao-apache.pl' ],
    'MAN3PODS'      => \%man3pods,
);

sub MY::postamble
{ <<EOT;

config::	README

README:	lib/XAO/Web/Intro.pod
	pod2text lib/XAO/Web/Intro.pod > README

install::
	[ -d $homedir ] || mkdir $homedir && chmod 755 $homedir
	\@\$(PERL) -Mblib \\
	           -MXAO::PluginUtils=install_templates \\
	           -e'install_templates("MANIFEST")'

EOT
}
