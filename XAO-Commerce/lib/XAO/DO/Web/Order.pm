=head1 NAME

XAO::DO::Web::Order - object that holds non-translated
vendor orders

=head1 DESCRIPTION

Web::Order is a child object of Web::FS which handles all aspects
of handling orders on an eCommerce site.  As a part of the XAO::Commerce
release its main function is to implement shopping cart and order
checkout functionality.  In version 1.0, Web::Order does not provide any
meaningful calculation for shipping and tax charges, however the methods
calc_shipping_totals() and calc_tax_totals() are in place providing
sample calculations.  For Web::Order to truely be useful in a production
eCommerce site these methods simply need to be overridden by custom methods 
that reflect the actual algorithm requirements for the site.

=over

=cut

###############################################################################

package XAO::DO::Web::Order;

use strict;

use XAO::Utils;
use XAO::Errors qw(XAO::DO::Web::Order);
use XAO::Objects;
use base XAO::Objects->load(objname => 'Web::FS');

# XXX The following order parameters are hardcoded throughout:
#       * 'Products'
#       * 'quantity'
#       * 'shipmethod'
#       * 'total_items'
#       * 'total_shipping'
#       * 'total_tax'
#       * 'total_grand'

###############################################################################
sub check_mode($;%) {

    #dprint "\n\n***\n***\n"
    #     . "*** XAO::DO::Web::Order::check_mode() START\n"
    #     . "***\n***";

    my $self = shift;
    my $args = get_args(\@_);

    #
    # After this block, we will know we have either a template parameter
    # keyed by "$type.template" or a path parameter keyed by "$type.path"
    # for each template type supported.  This helps avoid using uninitialized
    # variables in the methods.
    #
    foreach my $type (
                '',
                'sorry',
                'item',
                'itemheader',
                'itemfooter',
            ) {

        my $tkey = $type ? $type.'.template' : 'template';
        my $pkey = $type ? $type.'.path'     : 'path';

        if (exists($args->{$tkey})) {
            delete $args->{$pkey} if exists($args->{$pkey});
            #dprint "    %% '$tkey' = $args->{$tkey}";
        }
        else {
            $args->{$pkey} = $args->{$type} if !exists($args->{$pkey})
                                            &&  exists($args->{$type})
                                            &&  exists($args->{$type});
            delete $args->{$tkey} if exists($args->{$tkey});
            #dprint "    %% '$pkey' = $args->{$pkey}" if exists($args->{$pkey});
        }
        delete $args->{$type} if exists($args->{$type});
    }

    my $mode = $args->{mode} || 'show';
    if    ($mode eq 'show' || $mode eq 'view') { $self->show($args); }
    elsif ($mode eq 'save')                    { $self->save($args); }
    elsif ($mode eq 'add' || $mode eq 'clear') { $self->add($args);  }
    elsif ($mode eq 'edit-object')             { $self->edit_object($args); }
    elsif ($mode eq 'delete-object')           { $self->delete_object($args); }
    else                                       { $self->SUPER::check_mode($args); }

    #dprint "***\n***\n"
    #     . "*** XAO::DO::Web::Order::check_mode() STOP\n"
    #     . "***\n***";
}
###############################################################################

=item show ()

Presents the order details.  Takes arguments:

    * 'template' or 'path'
    * 'sorry.template' or 'sorry.path' or sorry'
    * 'item' or 'item.path' or 'item.template'
    * 'itemheader' or 'itemheader.path' or 'itemheader.template' (optional)
    * 'itemfooter' or 'itemfooter.path' or 'itemfooter.template' (optional)

=cut

sub show {
    
    #dprint "***\n"
    #     . "*** XAO::DO::Web::Order::show() START\n"
    #     . "***";

    my $self = shift;
    my $args = get_args(\@_);

    my %pass;
    foreach (keys %$args) { $pass{$_} = $args->{$_} if $args->{$_}; }

    my $order_id = $args->{id} || '';
    my $order    = $self->_get_order($order_id);
    unless ($order && $order->get('Products')->keys) { # XXX hardcoded for now
        #dprint "    %% No Items Found";
        $pass{template} = $args->{'sorry.template'} if exists($args->{'sorry.template'});
        $pass{path}     = $args->{'sorry.path'}     if exists($args->{'sorry.path'});
    }

    throw XAO::E::DO::Web::Order "show - no path or template" unless exists($pass{template})
                                                                  || exists($pass{path});
    foreach (keys %pass) { delete $pass{$_} if /^sorry/; }
    $self->_display(\%pass);
    
    #dprint "***\n"
    #     . "*** XAO::DO::Web::Order::show() STOP\n"
    #     . "***";

    return 1;
}
###############################################################################

=item add ()

This method does the following:

    - checks for order_id cookie; if one exists, retrieves order object,
      otherwise creates a new order object and sets an order_id cookie.
    - adds item(s) to order object if applicable.
    - saves selected shipping address to order object if applicable.
    - saves selected shipping method  to order object if applicable.
    - saves selected payment  method  to order object if applicable.
    - calculates ordered item total                and saves it to order object.
    - calculates ship  total or estimated ship  total and saves it to order object.
    - calculates tax   total or estimated tax   total and saves it to order object.
    - calculates grand total or estimated grand total and saves it to order object.

Takes arguments:

    * 'template' or 'path'
    * 'sorry.template' or 'sorry.path' or sorry'

=cut

sub add () {

    #dprint "***\n"
    #     . "*** XAO::DO::Web::Order::add() START\n"
    #     . "***";

    my $self = shift;
    my $args = get_args(\@_);

    my $rh_cgi;
    my $cgi = $self->siteconfig->cgi;
    foreach ($cgi->param) { $rh_cgi->{$_} = $cgi->param($_); }
    #dprint "    %% CGI PARAMETERS:";
    #foreach (sort keys %$rh_cgi) { dprint "    %% * $_: $rh_cgi->{$_}"; }

    # Create new order if necessary
    my $order_id = $args->{id} || '';
    my $order    = $self->_get_order($order_id) || $self->_create_order;

    my $clear_items = $rh_cgi->{clear} || $args->{mode} eq 'clear' ? 1 : '';

    if ($clear_items) {
        $self->clear_items($rh_cgi);
    }
    else {
        $self->add_items($rh_cgi)      if $rh_cgi->{item1};
        $self->set_shipto($rh_cgi)     if $rh_cgi->{shipto};
        $self->set_shipmethod($rh_cgi) if $rh_cgi->{shipmethod};
        $self->set_paymethod($rh_cgi)  if $rh_cgi->{paymethod};
    }

    if ($clear_items || $rh_cgi->{item1} || $rh_cgi->{shipto}
     || $rh_cgi->{shipmethod} || $rh_cgi->{paymethod}) {
        # 'order_price' is the unit price to be used for a given item
        # It can depend on any aspect of an order and thus should be
        # updated whenever anything about an order changes (Address,
        # PayMethod, quantity, etc.).
        unless ($clear_items) {
            my $oilist = $order->get('Products');
            foreach ($oilist->keys) {
                my $oitem = $oilist->get($_);
                $oitem->put('order_price', $self->order_price($oitem));
            }
        }
        $self->calc_item_totals;
        $self->calc_shipping_totals;
        $self->calc_tax_totals;
        $self->calc_grand_total;
    }

    my %pass;
    unless ($order->get('Products')->keys) { # XXX hardcoded for now
        #dprint "    %% No Items Left";
        $pass{template} = $args->{'sorry.template'} if exists($args->{'sorry.template'});
        $pass{path}     = $args->{'sorry.path'}     if exists($args->{'sorry.path'});
    }
    foreach (keys %$args) {
        $pass{$_} = $args->{$_} unless exists($pass{$_}) || !$args->{$_} || /^sorry/;
    }
    $self->_display(\%pass);

    #dprint "***\n"
    #     . "*** XAO::DO::Web::Order::add() STOP\n"
    #     . "***";

    return 1;
}
###############################################################################

=item save ()

Changes status of order to 'Placed' and adds customer_id to order
of orders.  Takes arguments:

    * 'template' or 'path'
    * 'sorry.template' or 'sorry.path' or sorry'

=cut

sub save {
    
    #dprint "***\n"
    #     . "*** XAO::DO::Web::Order::save() START\n"
    #     . "***";

    my $self = shift;
    my $args = get_args(\@_);

    my %pass;
    foreach (keys %$args) { $pass{$_} = $args->{$_} if $args->{$_}; }

    my $order_id = $args->{id} || '';
    my $order    = $self->_get_order($order_id);
    if ($order && $order->get('Products')->keys) { # XXX hardcoded for now
        #dprint "    %% Found Order With Items";
        # Note: get customer from clipboard - this requires IdentifyUser to have
        # run previously in 'check' mode!
        # XXX 'customer' is hardcoded for now
        my $customer = $self->_get_customer('customer')
                    || throw XAO::E::DO::Web::Order "save - no customer object";
        # XXX 'customer_id', 'status' and 'Placed' are hardcoded for now
        $order->put('customer_id', $customer->get('customer_id'));
        $order->put('status',      'Placed');
        $order->put('place_time',  time());

        # Clear cookie
        my $oconfig = $self->siteconfig->get('order');
        $self->siteconfig->add_cookie(
            -name    => $oconfig->{order_cookie},
            -value   => '',
            -path    => '/',
            -expires => '+0s',
        );
    }
    else {
        #dprint "    %% No Order";
        $pass{template} = $args->{'sorry.template'} if exists($args->{'sorry.template'});
        $pass{path}     = $args->{'sorry.path'}     if exists($args->{'sorry.path'});
    }

    foreach (keys %pass) { delete $pass{$_} if /^sorry/; }
    $self->_display(\%pass);

    #dprint "***\n"
    #     . "*** XAO::DO::Web::Order::save() STOP\n"
    #     . "***";

    return 1;
}
###############################################################################

=item expand_items (%)

This functionality is in its own method to facilitate customizations.
The method displays items.  It is called as follows:

    $self->expand_items($args);

=cut

sub expand_items {

    #dprint "*** XAO::DO::Web::Order::expand_items() START";

    my $self = shift;
    my $args = get_args(\@_);

    my $page     = $self->object;
    my $order_id = $args->{id} || '';
    my $order    = $self->_get_order($order_id) || throw XAO::E::DO::Web::Order "expand_items - no order";
    my $ilist = $order->get('Products');
    my $text  = '';

    my %hpass;
    $hpass{template} = $args->{'itemheader.template'} if exists($args->{'itemheader.template'});
    $hpass{path}     = $args->{'itemheader.path'}     if exists($args->{'itemheader.path'});
    $text .= $page->expand(\%hpass) if exists($hpass{template}) || exists($hpass{path});

    # XXX Later: group and order items in a deliberate way
    throw XAO::E::DO::Web::Order "expand_items - no item path or template"
      unless exists($args->{'item.template'}) || exists($args->{'item.path'});
    my $count = 1;
    foreach ($ilist->keys) {
        my $item   = $ilist->get($_);
        my $oprice = sprintf("%.2f", $item->get('order_price'));
        my %ipass  = (
            COUNT      => $count,
            PRICE      => $oprice,
            TOTAL_ITEM => sprintf("%.2f", $oprice * $item->get('quantity')),
        );
        $ipass{template} = $args->{'item.template'} if exists($args->{'item.template'});
        $ipass{path}     = $args->{'item.path'}     if exists($args->{'item.path'});
        foreach ($item->keys) {
            my $key = uc($_);
            $ipass{$key} = $item->get($_);
            $ipass{$key} = sprintf("%.2f", $ipass{$key}) if /price$/;
        }
        $text .= $page->expand(\%ipass);
        $count++;
    }

    my %fpass;
    $fpass{template} = $args->{'itemfooter.template'} if exists($args->{'itemfooter.template'});
    $fpass{path}     = $args->{'itemfooter.path'}     if exists($args->{'itemfooter.path'});
    $text .= $page->expand(\%fpass) if exists($fpass{template}) || exists($fpass{path});

    #dprint "*** XAO::DO::Web::Order::expand_items() STOP";

    return $text;
}
###############################################################################

=item clear_items (%)


=cut

sub clear_items {
    #dprint "*** XAO::DO::Web::Order::clear_items() START";
    my ($self, $rh_cgi) = @_;
    my $order  = $self->_get_order || throw XAO::E::DO::Web::Order "clear_items - no order";
    my $oilist = $order->get('Products');
    $oilist->destroy;
    #dprint "*** XAO::DO::Web::Order::clear_items() STOP";
    return 1;
}
###############################################################################

=item add_items (%)

This method adds/sets quantities of items to "ordered items" list.  It
takes the following CGI Parameters:

  * items1..N
  * quantity1..N
  * set1..N (optional - 'set' mode; default is 'add' mode)

=cut

sub add_items {

    #dprint "*** XAO::DO::Web::Order::add_items() START";

    my ($self, $rh_cgi) = @_;

    my $order  = $self->_get_order || throw XAO::E::DO::Web::Order "add_items - no order";
    my $oilist = $order->get('Products');
    my $ilist  = $self->odb->fetch('/Products'); # XXX hardcoded for now

    my $count = 1;
    while (my $id = $rh_cgi->{'item'.$count}) { # XXX hardcoded for now

        unless ($ilist->exists($id)) {
            throw XAO::E::DO::Web::Order "add_items - item '$id' does not exist";
            $count++;
            next;
        }
        my $item  = $ilist->get($id);
        my $oitem = $oilist->exists($id) ? $oilist->get($id)
                                         : $self->new_item(
                                               list => $oilist,
                                               item => $item,
                                           );
        my $current  = int($oitem->get('quantity')) || 0;
        my $quantity = int($rh_cgi->{'quantity'.$count});
        $quantity   += $current unless exists($rh_cgi->{'set'.$count}) && $rh_cgi->{'set'.$count};
        $quantity > 0 ? $oitem->put('quantity', $quantity) : $oilist->delete($id);

        # this is redundant, 'cause it happens in add():
        #$oitem->put('order_price', $self->order_price($oitem));

        $count++;
    }

    #dprint "*** XAO::DO::Web::Order::add_items() STOP";

    return --$count || -1; # return num items added _or_ true value
}
###############################################################################

=item new_item (%)

This functionality is in its own method to facilitate customizations.
The method copies a item into the "ordered item" list.  It's called as
follows:

    my $new_ordered_item = $self->new_item(
                               list    => $ordered_item_list,
                               item => $item,
                           );

=cut

sub new_item {

    #dprint "*** XAO::DO::Web::Order::new_item() START";

    my $self   = shift;
    my $args   = get_args(\@_);
    my $oilist = $args->{list} || throw XAO::E::DO::Web::Order "new_item - no list argument";
    my $item   = $args->{item} || throw XAO::E::DO::Web::Order "new_item - no item argument";

    my ($oitem, $id) = ($oilist->get_new, '');
    foreach (sort $oitem->keys) {

        next if $_ eq 'quantity' || $_ eq 'order_price';

        my $rh_descr = $item->describe($_);
        if ($rh_descr->{type} eq 'key') {
            $id = $item->get($_);
            next;
        }

        my $value = $item->get($_) || '';
        # XXX use this once _clone_list() is correctly implemented.
        #$rh_descr->{type} eq 'list' ? $oitem->put($_, $self->_clone_list($value))
        #                            : $oitem->put($_, $value);
        $oitem->put($_, $value) unless $rh_descr->{type} eq 'list';
    }

    # attach ordered item with specified id
    $id ? $oilist->put($id, $oitem) : throw XAO::E::DO::Web::Order "new_item - no item id";

    #dprint "*** XAO::DO::Web::Order::new_item() STOP";

    return $oilist->get($id);
}
###############################################################################

=item set_shipto (%)

This method sets the shipping address information.  It
takes the following CGI Parameters:

  * shipto

=cut

sub set_shipto {

    #dprint "*** XAO::DO::Web::Order::set_shipto() START";

    my ($self, $rh_cgi) = @_;

    my $shipto_id = $rh_cgi->{shipto}
                 || throw XAO::E::DO::Web::Order "set_shipto - no shipto argument";

    # Note: get customer from clipboard - this requires IdentifyUser to have
    # run previously in 'check' mode!
    # XXX 'customer' is hardcoded for now
    my $customer = $self->_get_customer('customer')
                || throw XAO::E::DO::Web::Order "set_shipto - no customer object";
    my $alist    = $customer->get('Addresses'); # XXX hardcoded for now
    my $address  = $alist->get($shipto_id);
    my $order    = $self->_get_order || throw XAO::E::DO::Web::Order "set_shipto - no order";
    foreach ($address->keys) {
        my $rh_descr = $address->describe($_);
        next if $rh_descr->{type} eq 'key';
        $order->put("shipto_$_", $address->get($_));
    }
    #dprint "    %% Shipto Address:";
    #foreach (sort $address->keys) { dprint "    %% * shipto_$_: ".$order->get("shipto_$_"); }

    #dprint "*** XAO::DO::Web::Order::set_shipto() STOP";

    return 1;
}
###############################################################################

=item set_shipmethod (%)

This method sets the shipping method information.  It
takes the following CGI Parameters:

  * shipmethod

=cut

sub set_shipmethod {

    #dprint "*** XAO::DO::Web::Order::set_shipmethod() START";

    my ($self, $rh_cgi) = @_;

    my $shipmethod_id = $rh_cgi->{shipmethod}
                     || throw XAO::E::DO::Web::Order "set_shipmethod - no shipmethod argument";

    my $order = $self->_get_order || throw XAO::E::DO::Web::Order "set_shipmethod - no order";
    $order->put('shipmethod', $shipmethod_id);

    #dprint "*** XAO::DO::Web::Order::set_shipmethod() STOP";

    return 1;
}
###############################################################################

=item set_paymethod (%)

This method sets the payment method information.  It
takes the following CGI Parameters:

  * paymethod

=cut

sub set_paymethod {

    #dprint "*** XAO::DO::Web::Order::set_paymethod() START";

    my ($self, $rh_cgi) = @_;

    my $paymethod_id = $rh_cgi->{paymethod}
                    || throw XAO::E::DO::Web::Order "set_paymethod - no paymethod argument";

    # Note: get customer from clipboard - this requires IdentifyUser to have
    # run previously in 'check' mode!
    # XXX 'customer' is hardcoded for now
    my $customer  = $self->_get_customer('customer')
                 || throw XAO::E::DO::Web::Order "set_paymethod - no customer object";
    my $pmlist    = $customer->get('PayMethods'); # XXX hardcoded for now
    my $paymethod = $pmlist->get($paymethod_id);
    my $order     = $self->_get_order || throw XAO::E::DO::Web::Order "set_paymethod - no order";
    foreach ($paymethod->keys) {
        my $rh_descr = $paymethod->describe($_);
        next if $rh_descr->{type} eq 'key';
        $order->put("pay_$_", $paymethod->get($_));
    }
    #dprint "    %% Payment Method:";
    #foreach (sort $paymethod->keys) { dprint "    %% * paymethod_$_: ".$order->get("paymethod_$_"); }

    #dprint "*** XAO::DO::Web::Order::set_paymethod() STOP";

    return 1;
}
###############################################################################

=item calc_item_totals ($)

This method calculates and saves the item total.

=cut

sub calc_item_totals($) {
    #dprint "*** XAO::DO::Web::Order::calc_item_totals() START";
    my $self   = shift;
    my $order  = $self->_get_order || throw XAO::E::DO::Web::Order "calc_item_totals - no order";
    my $ilist  = $order->get('Products');
    my $ptotal = 0;
    foreach ($ilist->keys) {
        my $item = $ilist->get($_);
        $ptotal += $item->get('order_price') * $item->get('quantity');
    }
    $ptotal = sprintf("%.2f", $ptotal);
    #dprint "*** XAO::DO::Web::Order::calc_item_totals() STOP";
    return $order->put('total_items', $ptotal);
}
###############################################################################
# XXX This is the simplest possible case of this method. The 'price' property
# is hardcoded and a possible sale price is not taken into consideration.
sub order_price {
    my ($self, $item) = @_;
    return sprintf("%.2f", $item->get('price'));
}
###############################################################################

=item calc_shipping_totals ($)

This method calculates and saves the shipping total.  Currently the calculation
present is for sample purposes only (5% of items total).  Override this method
with your custom shipping calculation.  Make sure that, in your custom version,
you put the shipping total in the order's 'total_shipping' property and return
the shipping total.

=cut

# XXX This is currently a very fake shipping total.
sub calc_shipping_totals($) {
    #dprint "*** XAO::DO::Web::Order::calc_shipping_totals() START";
    my $self   = shift;
    my $order  = $self->_get_order || throw XAO::E::DO::Web::Order "calc_shipping_totals - no order";
    my $total_shipping = $order->get('shipto_state')
                       ? sprintf("%.2f", $order->get('total_items') * 0.05)
                       : '';
    #dprint "*** XAO::DO::Web::Order::calc_shipping_totals() STOP";
    return $order->put('total_shipping', $total_shipping);
}
###############################################################################

=item calc_tax_totals ($)

This method calculates and saves the tax total. Currently the calculation
present is for sample purposes only (8.25% of items total if shipping to
California, USA).  Override this method with your custom tax calculation.
Make sure that, in your custom version, you put the tax total in the order's
'total_tax' property and return the tax total.

=cut

sub calc_tax_totals($) {
    #dprint "*** XAO::DO::Web::Order::calc_tax_totals() START";
    my $self   = shift;
    my $order  = $self->_get_order || throw XAO::E::DO::Web::Order "calc_tax_totals - no order";
    my $merchant_state = 'CA'; # XXX hardcoded for now
    return '0.00' unless $merchant_state eq $order->get('shipto_state'); # XXX hardcoded for now
    my $taxable_total  = $order->get('total_items') + $order->get('total_shipping');
    my $total_tax      = sprintf("%.2f", $taxable_total * 0.0825);
    return $order->put('total_tax', $total_tax);
    #dprint "*** XAO::DO::Web::Order::calc_tax_totals() STOP";
}
###############################################################################

=item calc_grand_total ($)

This method calculates and saves the grand total.

=cut

sub calc_grand_total($) {
    #dprint "*** XAO::DO::Web::Order::calc_grand_total() START";
    my $self   = shift;
    my $order  = $self->_get_order || throw XAO::E::DO::Web::Order "calc_grand_total - no order";
    my $grand_total = sprintf(
                          "%.2f",
                          $order->get('total_items')
                        + $order->get('total_shipping')
                        + $order->get('total_tax')
                      );
    return $order->put('total_grand', $grand_total);
    #dprint "*** XAO::DO::Web::Order::calc_grand_total() STOP";
}
###############################################################################
#
# Display page using all order properties (use all uppercase keys)
#
sub _display {
    #dprint "*** XAO::DO::Web::Order::_display() START";
    my $self = shift;
    my $args = get_args(\@_);
    my %pass;
    foreach (keys %$args) { $pass{$_} = $args->{$_} || undef; }
    if (my $order = $self->_get_order) {
        foreach ($order->keys) {
            my $rh_descr = $order->describe($_);
            next if $rh_descr->{type} eq 'list';
            my $key      = uc($_);
            my $value    = $order->get($_) || '';
            $pass{$key}  = $value;
        }
        if ($order->get('Products')->keys) { # XXX hardcoded for now
            $pass{ITEMS} = exists($pass{'item.template'}) || exists($pass{'item.path'})
                         ? $self->expand_items(\%pass) : '';
        }
        else {
            $pass{ITEMS} = 'No items in order'; # This shouldn't ever really be shown
        }
    }
    my $page = $self->object;
    $page->display(\%pass);
    #dprint "*** XAO::DO::Web::Order::_display() STOP";
    return 1;
}
###############################################################################
#
# Gets order from clipboard or database. Returns order object or empty string.
# Puts order in clipboard if it gets order from database. Called as follows:
# 
#   my $order = $self->_get_order;
#
sub _get_order($;$) {

    #dprint "*** XAO::DO::Web::Order::_get_order() START";

    my $self     = shift;
    my $sconfig  = $self->siteconfig;
    my $oconfig  = $sconfig->get('order');
    my $cb_uri   = $oconfig->{cb_uri} || '/Orders';
    my $clipbd   = $self->clipboard;
    my $cgi      = $sconfig->cgi;

    #
    # This is included for supporting admin viewing of orders. There
    # is currently no support for admin editing of order details,
    # but this can easily be added in similar fashion to admin
    # viewing support.
    #
    my $order_id = $_[0] ? shift : '';

    my $order;
    if ($order_id) {
        my $olist = $self->odb->fetch($oconfig->{list_uri});
        $order    = $olist->get($order_id) if $olist->exists($order_id);
        return '' unless $order;
        #dprint "    %% Retrieved Order $order_id: $order";
    }
    else {

        #
        # Try to get order from clipboard
        #
        $order = $clipbd->get("$cb_uri/order_object");
        #dprint "    %% Order In Clipboard (early return)" if $order;
        return $order if $order;
        #dprint "    %% No Order In Clipboard";

        #
        # Try to get order id from cookie and then try to get order
        #
        my $cookie_name = $oconfig->{order_cookie}
                       || throw XAO::E::DO::Web::Order "_get_order - no order cookie name in config";
        $order_id = $sconfig->cgi->cookie(-name => $cookie_name);
        #dprint "    %% No Order ID (early return)" unless $order_id;
        return '' unless $order_id;
        #dprint "    %% GOT COOKIE: $cookie_name=$order_id";

        my $olist = $self->odb->fetch($oconfig->{list_uri});
        $order    = $olist->get($order_id) if $olist->exists($order_id);
        return '' unless $order;
        #dprint "    %% Retrieved Order $order_id: $order";
    }

    $clipbd->put("$cb_uri/order_object" => $order);

    #dprint "*** XAO::DO::Web::Order::_get_order() STOP";

    return $order;
}
###############################################################################
#
# Creates a new order, adds it to the order list and finally sets an order
# cookie. Returns order object. Called as follows:
#
#   my $order = $self->_create_order;
#
sub _create_order($;$) {

    #dprint "*** XAO::DO::Web::Order::_create_order() START";

    my $self = shift;
    
    my $oconfig  = $self->siteconfig->get('order');
    my $olist    = $self->odb->fetch($oconfig->{list_uri});
    my $order_id = $olist->put($olist->get_new); # attach this order
    my $order    = $olist->get($order_id);
    $order->put('create_time', time());
    #dprint "    %% CREATED ORDER:      $order_id at (".$order->get('create_time').")";

    my $cb_uri  = $oconfig->{cb_uri} || '/Orders';
    $self->clipboard->put("$cb_uri/order_object" => $order);
    #dprint "    %% ADDED TO CLIPBOARD: $order_id (".$order.")";

    my $expire = $oconfig->{order_cookie_expire} ? "+$oconfig->{order_cookie_expire}s" : '+4y';
    $self->siteconfig->add_cookie(
        -name    => $oconfig->{order_cookie},
        -value   => $order_id,
        -path    => '/',
        -expires => $expire,
    );
    #dprint "    %% ADDED COOKIE:       $oconfig->{order_cookie}=$order_id (expire=$expire)";

    #dprint "*** XAO::DO::Web::Order::_create_order() STOP";

    return $order;
}
###############################################################################
#
# Return customer as retrieved from clipboard - this requires IdentifyUser
# to have run previously in 'check' mode!  Called as follows:
#
#   my $customer = $self->_get_customer('customer');
#
# XXX this should be available from IdentifyUser.pm
#
sub _get_customer {

    my $self = shift;
    my $type = shift;

    # Get clipboard uri for requested type of user
    # XXX shouldn't IdentifyUser.pm provide a method for this?
    my $idconfig = $self->siteconfig->get('identify_user')
                || throw XAO::E::DO::Web::Order "_get_customer - no 'identify_user' config";
    $idconfig    = $idconfig->{$type}
                || throw XAO::E::DO::Web::Order "_get_customer - no 'identify_user' config for '$type'";
    my $cb_uri = $idconfig->{cb_uri} || "/IdentifyUser/$type";

    return $self->clipboard->get("$cb_uri/object");
}
###############################################################################
sub form_fields {
    my $self=shift;
    return [
        {
            name      => 'customer_id',
            style     => 'text',
            maxlength => 100,
        },
       ## Merchant Info
       #{
       #    name     => 'create_time',
       #    style    => 'integer',
       #    minvalue => 0,
       #},
       #{
       #    name     => 'place_time',
       #    style    => 'integer',
       #    minvalue => 0,
       #},
        {
            name     => 'status',
            required => 1,
            style    => 'selection',
            options  => {
                'Processing'            => 'Processing',
                'Shipped'               => 'Shipped',
                'Product Pending'       => 'Product Pending',
                'Authorization Pending' => 'Authorization Pending',
                'Cancelled'             => 'Cancelled',
                'Placed'                => 'Placed',
            },
            param    => 'STATUS',
            text     => 'Status',
        },
        {
            name     => 'merchant_comment',
            style    => 'text',
            param    => 'MERCHANT_COMMENT',
            text     => 'Merchant Comment',
        },
       ## General info:
       #{
       #    name      => 'shipmethod',
       #    style     => 'text',
       #    maxlength => 100,
       #},
       #{
       #    name      => 'total_items',
       #    style     => 'text',
       #    maxlength => 100,
       #},
       #{
       #    name      => 'total_shipping',
       #    style     => 'text',
       #    maxlength => 100,
       #},
       #{
       #    name      => 'total_tax',
       #    style     => 'text',
       #    maxlength => 100,
       #},
       #{
       #    name      => 'total_grand',
       #    style     => 'text',
       #    maxlength => 100,
       #},
       ## Shipping info:
       #{
       #    name      => 'shipto_ref_name',
       #    style     => 'text',
       #    maxlength => 100,
       #},
       #{
       #    name      => 'shipto_name_line1',
       #    style     => 'text',
       #    maxlength => 100,
       #},
       #{
       #    name      => 'shipto_name_line2',
       #    style     => 'text',
       #    maxlength => 100,
       #},
       #{
       #    name      => 'shipto_line_1',
       #    style     => 'text',
       #    maxlength => 100,
       #},
       #{
       #    name      => 'shipto_line_2',
       #    style     => 'text',
       #    maxlength => 100,
       #},
       #{
       #    name      => 'shipto_city',
       #    style     => 'text',
       #    maxlength => 30,
       #},
       #{
       #    name      => 'shipto_state',
       #    style     => 'text',
       #    maxlength => 30,
       #},
       #{
       #    name      => 'shipto_zipcode',
       #    style     => 'text',
       #    maxlength => 10,
       #},
       #{
       #    name      => 'shipto_phone',
       #    style     => 'text',
       #    maxlength => 100,
       #},
       ## PayMethod info:
       #{
       #    name      => 'pay_ref_name',
       #    style     => 'text',
       #    maxlength => 100,
       #},
       #{
       #    name      => 'pay_method',
       #    style     => 'text',
       #    maxlength => 100,
       #},
       #{
       #    name      => 'pay_number',
       #    style     => 'text',
       #    maxlength => 100,
       #},
       #{
       #    name      => 'pay_expire_month',
       #    style     => 'integer',
       #    minvalue  => 0,
       #},
       #{
       #    name      => 'pay_expire_year',
       #    style     => 'integer',
       #    minvalue  => 0,
       #},
       #{
       #    name      => 'pay_name',
       #    style     => 'text',
       #    maxlength => 100,
       #},
       #{
       #    name      => 'pay_line_1',
       #    style     => 'text',
       #    maxlength => 100,
       #},
       #{
       #    name      => 'pay_line_2',
       #    style     => 'text',
       #    maxlength => 100,
       #},
       #{
       #    name      => 'pay_city',
       #    style     => 'text',
       #    maxlength => 30,
       #},
       #{
       #    name      => 'pay_state',
       #    style     => 'text',
       #    maxlength => 30,
       #},
       #{
       #    name      => 'pay_zipcode',
       #    style     => 'text',
       #    maxlength => 10,
       #},
       #{
       #    name      => 'pay_phone',
       #    style     => 'text',
       #    maxlength => 100,
       #},
    ];
}
###############################################################################
1;
__END__

=back

=head1 AUTHORS

Copyright (c) 2002 XAO Inc.

Marcos Alves <alves@xao.com>
