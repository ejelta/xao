=head1 NAME

XAO::DO::Web::Config - XAO::Web site configuration object

=head1 SYNOPSIS

 sub init {
     my $self=shift;

     my $webconfig=XAO::Objects->new(objname => 'Web::Config');

     $self->embed(web => $webconfig);
 }

=head1 DESCRIPTION

This object provides methods specifically for XAO::Web objects. It is
supposed to be embedded into XAO::DO::Config object by a web server
handler when site is initialized.

=cut

###############################################################################
package XAO::DO::Web::Config;
use XAO::Utils;
use XAO::Cache;
use XAO::Errors qw(XAO::DO::Web::Config);

##
# Prototypes
#
sub add_cookie ($@);
sub cgi ($$);
sub cleanup ($);
sub clipboard ($);
sub cookies ($);
sub disable_special_access ($);
sub embeddable_methods ($);
sub enable_special_access ($);
sub header ($@);
sub header_args ($@);
sub new ($@);

##
# Package version for checks and reference
#
use vars qw($VERSION);
($VERSION)=(q$Id: Config.pm,v 1.10 2003/10/21 22:16:52 am Exp $ =~ /(\d+\.\d+)/);

###############################################################################

=head1 METHODS

=over

=cut

###############################################################################

=item add_cookie (@)

Adds an HTTP cookie into the internal list. If there is only one
parameter we assume it is already encoded cookie, otherwise we assume it
is a hash of parameters for CGI->cookie method (see L<CGI>).

If a cookie with that name is already in the list from a previous call
to add_cookie() then it gets replaced. This check is only performed if
you pass a hash of arguments, not already prepared cookie.

Think of it as if you are adding cookies to you final HTTP response as
XAO::Web handler will get all the cookies collected during template
processing and send them out for you.

Examples:

 $config->add_cookie($cookie);

 $config->add_cookie(-name => 'sessionID',
                     -value => 'xyzzy',
                     -expires=>'+1h');

=cut

sub add_cookie ($@) {
    my $self=shift;
    my $cookie=(@_==1 ? $_[0] : get_args(\@_));
  
    ##
    # If new cookie has the same name, domain and path
    # as previously set one - we replace it. Works only for
    # cookies stored as parameters, unprepared.
    #
    if($self->{cookies} && ref($cookie) && ref($cookie) eq 'HASH') {
        for(my $i=0; $i!=@{$self->{cookies}}; $i++) {
            my $c=$self->{cookies}->[$i];

            next unless ref($c) && ref($c) eq 'HASH';

            next unless $c->{-name} eq $cookie->{-name} &&
                        $c->{-path} eq $cookie->{-path} &&
                        ((!defined($c->{-domain}) && !defined($cookie->{-domain})) ||
                         $c->{-domain} eq $cookie->{-domain});

            $self->{cookies}->[$i]=$cookie;

            return $cookie;
        }
    }

    push @{$self->{cookies}},$cookie;
}

###############################################################################

=item cgi (;$)

Returns or sets standard CGI object (see L<CGI>). In future versions this
would probably be converted to CGI::Lite or something similar, so do not
rely to much on the functionality of CGI.

Obviously you should not call this method to set CGI object unless you
are 100% sure you know what you're doing. And even in that case you have
to call enable_special_access() in advance.

Example:

 my $cgi=$self->cgi;
 my $name=$cgi->param('name');

Or just:

 my $name=$self->cgi->param('name');

=cut

sub cgi ($$) {
    my ($self,$newcgi)=@_;
    return $self->{cgi} unless $newcgi;
    if($self->{special_access}) {
        $self->{cgi}=$newcgi;
        return $newcgi;
    }
    throw XAO::E::DO::Web::Config
          "cgi - storing new CGI requires enable_special_access()";
}

###############################################################################

=item cleanup ()

Removes CGI object, cleans up clipboard. No need to call manually,
usually is called as part of XAO::DO::Config cleanup().

=cut

sub cleanup ($) {
    my $self=shift;
    delete $self->{cgi};
    delete $self->{clipboard};
    delete $self->{cookies};
    delete $self->{header_args};
    delete $self->{header_printed};
    delete $self->{special_access};
}

###############################################################################

=item clipboard ()

Returns clipboard XAO::SimpleHash object. Useful to keep temporary data
between different XAO::Web objects. Cleaned up for every session.

=cut

sub clipboard ($) {
   my $self=shift;
   $self->{clipboard}=XAO::SimpleHash->new() unless $self->{clipboard};
   $self->{clipboard};
}

###############################################################################

=item cookies ()

Returns reference to an array of prepared cookies.

=cut

sub cookies ($) {
    my $self=shift;

    my @baked;
    foreach my $c (@{$self->{cookies}}) {
        if(ref($c) && ref($c) eq 'HASH') {
            push @baked,$self->cgi->cookie(%{$c});
        }
        else {
            push @baked,$c;
        }
    }

    \@baked;
}

###############################################################################

=item disable_special_access ()

Disables use of cgi() method to set a new value.

=cut

sub disable_special_access ($) {
    my $self=shift;
    delete $self->{special_access};
}

###############################################################################

=item embeddable_methods ()

Used internally by global Config object, returns an array with all
embeddable method names -- add_cookie(), cgi(), clipboard(), cookies(),
header(), header_args().

=cut

sub embeddable_methods ($) {
    qw(add_cookie cgi clipboard cookies header header_args);
}

###############################################################################

=item enable_special_access ()

Enables use of cgi() method to set a new value. Normally you do
not need this method.

Example:

 $config->enable_special_access();
 $config->cgi(CGI->new());
 $config->disable_special_access();

=cut

sub enable_special_access ($) {
    my $self=shift;
    $self->{special_access}=1;
}

###############################################################################

=item header (@)

Returns HTTP header. The same as $cgi->header and accepts the same
parameters. Cookies added before by add_cookie() method are also
included in the header.

Returns header only once, on subsequent calls returns undef.

B<NOTE:> In mod_perl environment CGI will send the header itself and
return empty string. Be carefull to check the result for
C<if(defined($header))> instead of just C<if($header)>!

As with the most of Web::Config methods you do not need this method
normally. It is called automatically by web server handler at the end of
a session before sending out session results.

=cut

sub header ($@) {
    my $self=shift;
    return undef if $self->{header_printed};
    $self->header_args(@_) if @_;
    $self->{header_printed}=1;
    $self->cgi->header(%{merge_refs( { -cookie => $self->cookies },
                                     $self->{header_args})
                        });
}

###############################################################################

=item header_args (%)

Sets some parameters for header generation. You can use it to change
page status for example:

 $config->header_args(-Status => '404 File not found');

Accepts the same arguments CGI->header() accepts.

=cut

sub header_args ($@) {
    my $self=shift;
    my $args=get_args(\@_);
    @{$self->{header_args}}{keys %{$args}}=values %{$args};
    return $self->{header_args};
}

###############################################################################

=item new ($$)

Creates a new empty configuration object.

=cut

sub new ($@) {
    my $proto=shift;
    bless {},ref($proto) || $proto;
}

###############################################################################
1;
__END__

=back

=head1 AUTHOR

Copyright (c) 1999-2001 XAO Inc.

Author is Andrew Maltsev <am@xao.com>.

=head1 SEE ALSO

Recommended reading:
L<XAO::Web>,
L<XAO::DO::Config>.
