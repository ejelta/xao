=head1 NAME

XAO::DO::FS::Glue::MySQL - Fast MySQL driver for XAO::FS

=head1 SYNOPSIS

 my $odb=XAO::Objects->new(objname => 'FS::Glue',
                           dsn     => 'OS:MySQL:testdatabase');

=head1 DESCRIPTION

This is a faster MySQL driver for XAO::FS that does not use DBI/DBD and
connects to the database directly. It is otherwise compatible with
MySQL_DBI driver and can be used everywhere MySQL_DBI is used by
simply substituting 'OS:MySQL_DBI:dbname' string with 'OS:MySQL:dbname' in
connection to the database.

See L<XAO::DO::FS::Glue::MySQL_DBI> for the description of methods.

=cut

###############################################################################
package XAO::DO::FS::Glue::MySQL;
use strict;
use XAO::Utils;
use XAO::Objects;

use base XAO::Objects->load(objname => 'FS::Glue::MySQL_DBI'),
         'DynaLoader';

use vars qw($VERSION);
$VERSION='1.02';

bootstrap XAO::DO::FS::Glue::MySQL $VERSION;

###############################################################################

sub sql_connect ($%) {
    my $self=shift;
    my $args=get_args(\@_);

    my $dsn=$args->{dsn} ||
        throw $self "sql_connect - no 'dsn' given";
    $dsn=~m/^dbi:mysql:(database=)?(\w+)(;hostname=(.*?)(;|$))?/i ||
        throw $self "sql_connect - wrong DSN format ($dsn)";
    my $dbname=$2 . "\0";
    my $hostname=$3 ? $4 : '';
    $hostname.="\0";
    my $user=defined($args->{user}) ? $args->{user} : '';
    $user.="\0";
    my $password=defined($args->{password}) ? $args->{password} : '';
    $password.="\0";

    ##
    # Perl complains about passing undefs into the sub which is ok and
    # expected in this case.
    #
    my $db=sql_real_connect($hostname,$user,$password,$dbname) ||
        throw $self "sql_connect - can't connect to the database ($dsn)";

    $self->{sql}=$db;
}

###############################################################################

sub sql_do ($$;@) {
    my $rc;

    if(@_>2 && ref($_[2])) {
        $rc=sql_real_do(@_);
    }
    else {
        $rc=sql_real_do($_[0],$_[1],[ @_[2..$#_] ]);
    }

    $rc && $_[0]->throw("sql_do - SQL error '" . sql_error_text($_[0]) . "' for '$_[1]'");
}

sub sql_do_no_error ($$) {
    sql_real_do($_[0],$_[1],[ ]);
}

###############################################################################

sub sql_execute ($$;@) {
    my $r;

    if(scalar(@_)==2) {
        $r=sql_real_execute(@_,[]);
    }
    elsif(ref $_[2]) {
        $r=sql_real_execute(@_);
    }
    else {
        $r=sql_real_execute($_[0],$_[1],[ @_[2..$#_] ]);
    }

    defined($r) ||
        $_[0]->throw("sql_execute - SQL error: " . sql_error_text($_[0]));

    return $r;
}

###############################################################################
1;
__END__

=head1 AUTHORS

Copyright (c) 2005 Andrew Maltsev

Copyright (c) 2001-2004 Andrew Maltsev, XAO Inc.

<am@ejelta.com> -- http://ejelta.com/xao/

=head1 SEE ALSO

L<XAO::FS>, L<XAO::DO::FS::Glue::MySQL_DBI>.

=cut
