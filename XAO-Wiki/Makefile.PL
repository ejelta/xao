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

XAO::Wiki will need access to a XAO::FS database in order to run tests.
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

use XAO::Base qw($homedir);

WriteMakefile(
    'ABSTRACT'      => 'XAO::Wiki - wiki editing/display support',
    'AUTHOR'        => 'Nick Eremeev, Andrew Maltsev, http://ejelta.com/xao/',
    'NAME'          => 'XAO::Wiki',
    'VERSION_FROM'  => 'Wiki.pm',
    'PREREQ_PM'     => {
        'Test::Unit'        => 0.14,
        'Error'             => 0.15,
        'XAO::Base'         => 1.06,
        'XAO::FS'           => 1.06,
        'XAO::Web'          => 1.07,
    },
);

sub MY::postamble
{ <<EOT;

config::	README

README:	Wiki.pm
	pod2text -w76 Wiki.pm > README

install::
	[ -d $homedir ] || mkdir $homedir && chmod 755 $homedir
	\@\$(PERL) -Mblib \\
	           -MXAO::PluginUtils=install_templates \\
	           -e'install_templates("MANIFEST")'

EOT
}
