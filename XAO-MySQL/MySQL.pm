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

use base XAO::Objects->load(objname => 'FS::Glue::Base_MySQL');

use vars qw($VERSION);
$VERSION='1.03';

###############################################################################

sub connector_create ($) {
    return XAO::Objects->new(objname => 'FS::Glue::Connect_MySQL');
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
