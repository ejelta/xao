=head1 NAME

XAO::DO::Web::Mailer - executes given template and sends results via e-mail

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
 cc          => optional e-mail addresses of secondary recepients
 from        => optional 'from' e-mail address, default is taken from
                'from' site configuration parameter.
 subject     => message subject;
 [text.]path => text-only template path (required);
 html.path   => html template path;
 ARG         => VALUE - passed to Page when executing templates;

If 'to', 'from' or 'subject' are not specified then get_to(), get_from()
or get_subject() methods are called first. Derived class may override
them. 'To' and 'cc' may be comma-separated addresses lists.

THe configuration for Web::Mailer is kept in a hash stored in the site
configuration under 'mailer' name. Normally it is not required, the
default is to use sendmail for delivery. The parameters are:

 method     => either 'local' or 'smtp'
 agent      => server name for `smtp' or binary path for `local'
 from       => either a hash reference or a scalar with the default
               `from' address.

If `from' is a hash reference then the content of `from' argument to the
object is looked in keys and the value is used as actual `from'
address. This can be used to set up rudimentary aliases:

 <%Mailer
   ...
   from="customer_support"
   ...
 %>

 mailer => {
    from => {
        customer_support => 'support@foo.com',
        technical_support => 'tech@foo.com',
    },
    ...
 }

In that case actual from address will be `support@foo.com'. By default
if `from' in the configuration is a hash and there is no `from'
parameter for the object, `default' is used as the key.

=cut

###############################################################################
package XAO::DO::Web::Mailer;
use strict;
use MIME::Lite 2.117;
use XAO::Utils;
use XAO::Errors qw(XAO::DO::Web::Mailer);
use base XAO::Objects->load(objname => 'Web::Page');

sub display ($;%) {
    my $self=shift;
    my $args=get_args(\@_);

    my $config=$self->siteconfig->get('/mailer') || {};

    my $to=$args->{to} ||
           $self->get_to ||
           throw $self "display - no 'to' given";

    my $from=$args->{from};
    if(!$from) {
        $from=$config->{from};
        $from=$from->{default} if ref($from);
    }
    else {
        $from=$config->{from}->{$from} if ref($config->{from}) &&
                                          $config->{from}->{$from};
    }
    $from || throw $self "display - no 'from' given";

    my $subject=$args->{subject} || $self->get_subject() || 'No subject';

    ##
    # Parsing text template
    #
    my $page=$self->object;
    my $text;
    if($args->{'text.path'} || $args->{path}) {
        my $textpath=$args->{'text.path'} ||
                     $args->{path};
        my $objargs=merge_refs($args, { path => $textpath });
        delete $objargs->{template};
        $text=$page->expand($objargs);
    }
    
    ##
    # Parsing HTML template
    #
    my $html;
    if($args->{'html.path'}) {
        my $objargs=merge_refs($args,{ path => $args->{'html.path'} });
        delete $objargs->{template};
        $html=$page->expand($objargs);
    }

    ##
    # Preparing mailer and storing content in
    #
    my $mailer;
    if($html && !$text) {
        $mailer=MIME::Lite->new(
            From        => $from,
            To          => $to,
            Subject     => $subject,
            Data        => $html,
            Type        => 'text/html',
        );
    }
    elsif($text && !$html) {
        $mailer=MIME::Lite->new(
            From        => $from,
            To          => $to,
            Subject     => $subject,
            Data        => $text,
        );
    }
    elsif($text && $html) {
        $mailer=MIME::Lite->new(
            From        => $from,
            To          => $to,
            Subject     => $subject,
            Type        => 'multipart/alternative',
        );
        $mailer->attach(
            Type        => 'text/html',
            Data        => $html,
        );
        $mailer->attach(
            Type        => 'text/plain',
            Data        => $text,
        );
    }
    else {
        throw $self "display - no text for either html or text part";
    }
    $mailer->add(Cc => $args->{cc}) if $args->{cc};

    ##
    # Sending
    #
    ### dprint $mailer->as_string;
    my $method=$config->{method} || 'local';
    my $agent=$config->{agent};
    if(lc($method) eq 'local') {
        if($agent) {
            $mailer->send('sendmail',$agent);
        }
        else {
            $mailer->send('sendmail');
        }
    }
    else {
        $mailer->send('smtp',$agent || 'localhost');
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
