=head1 NAME

XAO::DO::Web::MenuBuilder - building all sorts of menus

=head1 SYNOPSIS

 <%MenuBuilder
   base="/bits/top-menu"
   item.0="statistic"
   item.1="config"
   item.1.grayed
   item.2="password"
   item.2.grayed
   active="statistic"
 %>

 <%MenuBuilder
   base="/bits/top-menu"
   item.0="statistic"
   item.1="config"
   item.2="password"
   grayed="config,password"
   active="statistic"
 %>

=head1 DESCRIPTION

Assumes the following file structure at the `base':

 header           - static menu header (optional)
 footer           - static menu footer (optional)
 separator        - static menu items separator
 item-NAME-normal - normal item text
 item-NAME-grayed - grayed item text
 item-NAME-active - currently opened page

If "grayed" argument is "*" then all menu items are displayed in
"grayed" mode.

=cut

###############################################################################
package XAO::DO::Web::MenuBuilder;
use strict;
use XAO::Utils;
use XAO::Objects;
use XAO::Templates;

use base XAO::Objects->load(objname => 'Web::Page');

sub display ($;%) {
    my $self=shift;
    my $args=get_args(\@_);

    ##
    # Base directory is required!
    #
    my $base=$args->{base} ||
        throw $self "display - no `base' defined";

    ##
    # Building the list of items to show
    #
    my %items;
    foreach my $item (keys %{$args}) {
        next unless $item =~ /^item.(\w+)$/;
        $items{$1}=$args->{$item};
    }

    ##
    # Now buiding the list of grayed out items
    #
    my %grayed;
    if($args->{grayed}) {
        if($args->{grayed} eq '*') {
            %grayed=map { $_ => 1 } values %items;
        }
        else {
            %grayed=map { $_ => 1 } split(/,/,$args->{grayed});
        }
    }
    else {
        foreach my $item (keys %items) {
            $grayed{$items{$item}}=1 if $args->{"item.$item.grayed"};
        }
    }

    ##
    # And finally displaying items.
    #
    my $obj=$self->object;
    $obj->display(path => "$base/header") if XAO::Templates::check(path => "$base/header");
    my $first=1;
    my $sepexists=XAO::Templates::check(path => "$base/separator");
    foreach my $item (sort { ($a =~ /^\d+$/ && $b =~ /^\d+$/)
                                ? $a <=> $b
                                : $a cmp $b } keys %items) {
        my $name=$items{$item};
        $obj->display(path => "$base/separator") if !$first && $sepexists;
        $first=0;
        my $path;
        if($grayed{$name}) {
            $path="grayed";
        }
        elsif(defined($args->{active}) && $name eq $args->{active}) {
            $path="active";
        }
        else {
            $path="normal";
        }
        $path="$base/item-$name-$path";
        $obj->display(path => $path);
    }
    $obj->display(path => "$base/footer") if XAO::Templates::check(path => "$base/footer");
}

###############################################################################
1;
__END__

=head1 EXPORTS

Nothing.

=head1 AUTHOR

Copyright (c) 2000-2002 XAO, Inc.

Andrew Maltsev <am@xao.com>.

=head1 SEE ALSO

Recommended reading:
L<XAO::Web>,
L<XAO::DO::Web::Page>.
