=head1 NAME

XAO::Commerce - eCommerce Suite

=head1 SYNOPSIS

See sample site templates, images and usage examples.

=head1 DESCRIPTION

XAO::Commerce is a part of XAO open source web services suite. It allows to
build eCommerce sites using XAO::Web (see XAO::Web for details).

XAO::Commerce consists of a number of templates and the following objects:

=over

=item *

XAO::DO::Web::Order: a child of Web::FS, keeps customer order
information and implements shopping cart functionality.

=item *

XAO::DO::Web::Account: a child of Web::FS, keeps general customer
account information.

=item *

XAO::DO::Web::Address: a child of Web::FS, keeps customer shipping
address information.

=item *

XAO::DO::Web::PayMethod: a child of Web::FS, keeps customer payment
method information.

=item *

XAO::DO::Web::Product: a child of Web::FS, keeps product information.

=item *

XAO::DO::Web::Order: a child of Web::FS, keeps customer order
information and implements shopping cart functionality.  Note that
to make any real shipping and tax calculations you will need to
override methods in this object that make these calculations.

=back

=head1 INSTALLATION NOTES

The easiest way to install XAO Commerce is to use CPAN. Usually you would
need to something like this:

 sudo perl -MCPAN -e'install XAO::DO::Commerce'

If you downloaded archive and want to install it manually then usual
four commands will do:

 perl Makefile.PL
 make
 make test
 sudo make install

Once installed the XAO Commerce is ready to be used and its templates are
located in the XAO installation path (usually /usr/local/xao/projects) under
templates/.

=head2 SAMPLE SITE TO SEE XAO COMMERCE IN ACTION

Here are the steps you need to follow to get a simple working sample
eCommerce site that uses XAO Commerce:

The distribution comes with a sample site in the directory sample/.
This directory contains a set of templates, configurations, objects and
tools for putting together a functioning sample eCommerce website.  To
set up this sample website:

=over

=item 1

Sym-link or recursively copy the 'sample' directory from the XAO
Commerce distribution to your 'projects' directory in XAO
installation path (usually /usr/local/xao/projects). The name you
use for sym-linking is the name of your site --
/usr/local/xao/projects/commerce would mean 'commerce' is the site name.

Install the required packages, XAO::FS, XAO::Web and XAO::Catalog,
along with their requirements.

=item 2

Create an empty MySQL database for your site (providing MySQL
username/password if required). In our example we use 'commerce' as
the database name.

 % mysqladmin create commerce

=item 3

Create empty XAO::FS database on top of MySQL database:

 % xao-fs --dsn=OS:MySQL_DBI:commerce init

=item 4

Go to /usr/local/xao/projects/commerce and run configure script:

 cd /usr/local/xao/projects/commerce
 perl ./configure.pl

Enter OS:MySQL_DBI:commerce as the database DSN and username/password
of a user that has full access to that database.

=item 5

Create database layout required by XAO Commerce:

 ./bin/build-structure

=item 6

Create an administration user for access the sample site's admin
area located at http://SITEDOMAIN/admin/:

 ./bin/add-admin LOGNAME PASSWORD EMAIL REAL_NAME

=item 7

To load sample data set from the provided sample flatfile `cd' to the
sample site directory and follow these steps:

 % bin/scan-flatfile sample_products.txt > sample_products.xml
 % bin/ifilter-flatfile sample_products.xml
 % bin/import-map FlatFile
 % bin/mark-empty-categories yes

NOTE: see README in `sample' for details.

=item 8

Configure a virtual server in your Apache config:

 <VirtualHost SOME_HOST_NAME>
   ServerName SOME_HOST_NAME

   CustomLog /usr/local/xao/projects/SITENAME/logs/access_log combined
   ErrorLog /usr/local/xao/projects/SITENAME/logs/error_log
   
   DocumentRoot /usr/local/xao/projects/SITENAME/images
   
   <Directory /usr/local/xao/handlers>
     Options ExecCGI
   
     # to use cgi's
     SetHandler cgi-script
   
     # to use mod_perl:
     #SetHandler perl-script
     #PerlHandler Apache::Registry
   </Directory>
   
   RewriteEngine on
   RewriteRule   ^/images/(.*)$ \
                 /usr/local/xao/projects/SITENAME/images/$1 \
                 [L]
   RewriteRule   ^/(.*)$ \
                 /usr/local/xao/handlers/xao-apache.pl/SITENAME/$1 \
                 [L]
 </VirtualHost>

Here you replace SOME_HOST_NAME with a something that you have in
your DNS or at least in /etc/hosts file and SITENAME with the name you
give your site. It is assumed in this example that the xao installation
path used is /usr/local/xao/ -- you need to change it if you used
a different path.

=back

=head1 METHODS

No publicly available methods.

=head1 EXPORTS

Nothing.

=head1 AUTHOR

Copyright (c) 2002 XAO Inc.

Marcos Alves <alves@xao.com>.

=head1 SEE ALSO

Recommended reading:
L<XAO::Web>,
L<XAO::DO::Web::Page>.

=cut

###############################################################################
package XAO::Commerce;
use strict;

use vars qw($VERSION);
$VERSION='1.02';

###############################################################################
1;
