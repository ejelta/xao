=head1 NAME

XAO::DO::FS::Glue::Connect_MySQL - direct connection to MySQL DB

=head1 SYNOPSIS

Not directly used.

=head1 DESCRIPTION

=cut

###############################################################################
package XAO::DO::FS::Glue::Connect_MySQL;
use strict;
use XAO::Utils;
use XAO::Objects;

use base (
    XAO::Objects->load(objname => 'FS::Glue::Connect_SQL'),
    'DynaLoader',
);

use vars qw($VERSION);
$VERSION=(0+sprintf('%u.%03u',(q$Id: Connect_MySQL.pm,v 1.2 2008/02/21 21:42:34 am Exp $ =~ /\s(\d+)\.(\d+)\s/))) || die "Bad VERSION";

bootstrap XAO::DO::FS::Glue::Connect_MySQL $VERSION;

###############################################################################

sub sql_connect ($%) {
    my $self=shift;
    my $args=get_args(\@_);

    if(%$args) {
        $self->{'dsn'}=$args->{'dsn'} || throw $self "sql_connect - no 'dsn' given";
        $self->{'user'}=$args->{'user'};
        $self->{'password'}=$args->{'password'};
    }

    my $dsn=$self->{'dsn'} ||
        throw $self "sql_connect - no 'dsn' given";

    $dsn=~m/^dbi:mysql:(database=)?(\w+)(;hostname=(.*?)(;|$))?/i ||
        throw $self "sql_connect - wrong DSN format ($dsn)";

    my $dbname=$2;
    my $hostname=$3 ? $4 : '';
    my $user=defined($self->{'user'}) ? $self->{'user'} : '';
    my $password=defined($self->{'password'}) ? $self->{'password'} : '';

    ### dprint "CONNECT: dbname='$dbname', hostname='$hostname', user='$user', password='$password'";

    my $db=sql_real_connect(
        $hostname."\0",
        $user."\0",
        $password."\0",
        $dbname."\0",
    ) || throw $self "sql_connect - can't connect to the database ($dsn)";

    ### dprint "CONNECT: db=$db";
    $self->{'sql'}=$db;
}

###############################################################################

=item sql_connected ()

Checks and returns true if the database connection is currently
established.

=cut

sub sql_connected ($) {
    my $self=shift;
    ### dprint "Sql_connected: ".join('|',caller(1));

    return undef unless $self->{'sql'};

    return sql_real_do($self,'select 1',[ ]) ? 0 : 1;
}

###############################################################################

=item sql_disconnect ()

Closes connection to the database.

=cut

# Implemented in .xs

###############################################################################

sub sql_do ($$;@) {
    my $rc;

    ### dprint "SQL_DO: $_[1] ||| ".join(' ',map { my @a=caller($_); $a[0] ? ("$a[0]:$a[2]") : (); } (0,1,2,3));

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

    ### dprint "SQL_EX: $_[1] ||| ".join(' ',map { my @a=caller($_); $a[0] ? ("$a[0]:$a[2]") : (); } (0,1,2,3));

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

sub need_unlock_on_error ($) {
    return 0;
}

###############################################################################
1;
__END__

=head1 AUTHORS

Copyright (c) 2005,2007 Andrew Maltsev

Copyright (c) 2001-2004 Andrew Maltsev, XAO Inc.

<am@ejelta.com> -- http://ejelta.com/xao/

=head1 SEE ALSO

L<XAO::FS>, L<XAO::DO::FS::Glue::MySQL_DBI>.

=cut
