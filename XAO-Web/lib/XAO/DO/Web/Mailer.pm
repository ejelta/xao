=head1 NAME

XAO::DO::Web::Mailer - executes given template and send results via e-mail

=head1 SYNOPSIS

 <%Mailer
   to="foo@somehost.com"
   from="bar@otherhost.com"
   subject="Your order '<%ORDER_ID/f%>' has been shipped"
   text.path="/bits/shipped-mail-text"
   html.path="/bits/shipped-mail-html"
   ORDER_ID="<%ORDER_ID/f%>"
 %>

=head1 DESCRIPTION

Displays nothing, just sends message.

Arguments are:

 to          => e-mail address of the recepient; default is taken from
                userdata->email if defined.
 cc          => optional e-mail address of the seconday recepient
 from        => optional 'from' e-mail address, default is taken from
                'default_from_address' site configuration parameter.
 subject     => message subject;
 server      => is not recommended, put server name into site configuration
                'smtp_server' parameter instead. Localhost is default.
 [text.]path => text-only template path (required);
 html.path   => html template path;
 ARG         => VALUE - passed to Page when executing templates;

If 'to', 'from' or 'subject' are not specified then get_to, get_from
or get_subject methods are called first. Derived class may
override them. 'To' may be comma-separated addresses list.

=cut

###############################################################################
package XAO::DO::Web::Mailer;
use strict;
use Mail::Sender 0.7;
use XAO::Utils;
use XAO::Errors qw(XAO::DO::Web::Mailer);
use XAO::Objects;
use base XAO::Objects->load(objname => 'Web::Page');

sub display ($;%) {

    my $self = shift;
    my $args = get_args(\@_);
    my $to   = $args->{to};

    unless ($to) {
        my $ud = $self->{siteconfig}->get('userdata');
        $to    = $ud ? $ud->get('email') : $self->get_to;
    }
    $to || throw XAO::E::DO::Web::Mailer "display - no 'to' given";
    my $from    = $args->{from} || $self->{siteconfig}->get('default_from_address');
    $from || throw XAO::E::DO::Web::Mailer "display - no 'from' given";
    my $subject = $args->{subject} || $self->{siteconfig}->get('sitedesc')    || 'No subject';
    my $server  = $args->{server}  || $self->{siteconfig}->get('smtp_server') || '127.0.0.1';
    
    ##
    # Parsing text template
    #
    my $textpath   = $args->{'text.path'} || $args->{path};
    $textpath || throw XAO::E::DO::Web::Mailer "display - no text path given";
    my $obj        = $self->object;
    my %objargs    = %$args;
    delete $objargs{template};
    $objargs{path} = $textpath;
    my $text       = $obj->expand(\%objargs);
    $text || throw XAO::E::DO::Web::Mailer "display - template $textpath produced no text";
    
    ##
    # Parsing HTML template
    #
    my $html;
    if($args->{'html.path'}) {
        %objargs       = %$args;
        delete $objargs{template};
        $objargs{path} = $args->{'html.path'};
        $html          = $obj->expand(\%objargs);
    }
    
    ##
    # Preparing mailer
    #
    my $mailer = Mail::Sender->new({ smtp => $server });
    if($html) {
        $mailer->OpenMultipart({
            from      => $from,
            to        => $to,
            cc        => $args->{cc},
            subject   => $subject,
            multipart => 'Alternative',
        });
        $mailer->Body;
        $mailer->Send($text);
        $mailer->Part({ ctype => 'text/html'});
        $mailer->Send($html);
        $mailer->Close;
    }
    else {
        $mailer->Open({
            from    => $from,
            to      => $to,
            cc      => $args->{cc},
            subject => $subject,
        });
        $mailer->Send($text);
        $mailer->Close;
     }
}

###############################################################################
1;
__END__

=head1 METHODS

No publicly available methods except overriden display().

=head1 EXPORTS

Nothing.

=head1 AUTHOR

Copyright (c) 2000-2001 XAO, Inc.

=head1 SEE ALSO

Recommended reading:
L<XAO::Web>,
L<XAO::DO::Web::Page>.
