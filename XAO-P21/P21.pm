package XAO::P21;

use strict;
use vars qw($VERSION @EXPORT_OK @ISA);

use IO::Socket::INET;
use XAO::Errors qw/XAO::P21/;
use XAO::Utils;

require Exporter;

@ISA = qw(Exporter);
@EXPORT_OK = qw(
                items
                avail
                catalog
                custinfo
                order
                price
);
$VERSION = '0.10';


=head1 NAME

XAO::P21 - Perl extension for network interaction with prophet21.

=head1 SYNOPSIS

  use XAO::P21;

=head1 DESCRIPTION

This module is intended for remote interaction with prophet21 system; it is mainly client-side stub for web server.

=cut

=head1 new

The constructor. Usage:

    my $client = XAO::P21->new( PeerPort => 9009 );

The server assumed at localhost; if real server is located at some remote site,
then secure tunnel should help.    

=cut

sub new {
    my ($proto, %param) = @_;
    my $self = { Proto => 'tcp', PeerAddr => '127.0.0.1', PeerPort => 9009 };
    foreach (keys %param) {
        $self->{$_} = $param{$_};
    }
    bless $self, $proto;
}

sub connect {
    my $self = shift;
    $self->{Socket} = IO::Socket::INET->new(%$self);
    throw XAO::E::P21 "connect - $!" unless $self->{Socket};
}

sub call {
    my ($self, $constr, $callback, @args) = @_ ;
    my $list;
    unless($callback) {
        $list=[];
        $callback = sub { push @$list, $_[0]; $list };
    }
    $self->connect unless $self->{Socket};
    my $socket=$self->{Socket};
    my $flag=0;
    local $SIG{PIPE} = sub { $flag = 1 };
    print $socket join("\t", @args), "\n";
    unless ($flag) {
        my $result;
        while(<$socket>) {
            chomp;
            return $result if /^\.$/;
            $result = $callback->($constr->($_));
        }
        delete $self->{Socket};
        throw XAO::E::P21 "call - unexpected eof reading from socket";
    }
    delete $self->{Socket};
    throw XAO::E::P21 "call - SIGPIPE writing to socket";
};

=head1 items

Returns full items list from "item" table; each line contains: item code,
package size, sales unit, sku, list price, alternate unit name or "?",
alternate unit size or "?", description string 1, description string 2, upc.
All the fields in line delimited with "\t".

One optional parameter is a reference to callback procedure, which accepts one
parameter - reference to item object. If it is missing, then the method returns
reference to list of item object references.

=cut  

sub items {
    my ($self, $callback, $table) = @_;
    $self->call( sub {
        my ($item_code, $prod_group, $pkg_size, $sales_unit,
            $sku, $list_price, $alt_ut_name, $alt_ut_size,
            $desc1, $desc2, $upc, $page) = split /\t/, $_[0];
        {
            item_code   => $item_code,
            prod_group  => $prod_group,
            pkg_size    => $pkg_size,
            sales_unit  => $sales_unit,
            sku         => $sku,
            list_price  => $list_price,
            alt_ut_name => $alt_ut_name,
            alt_ut_size => $alt_ut_size,
            desc1       => $desc1,
            desc2       => $desc2,
            upc         => $upc,
            page        => $page,
        }
    }, $callback, $table || 'items');
}

=head1 avail

Returns availability info for each of given item code. The info contains
lines with non-zero quantities only.

Synopsis:

XAO::P21->new->avail( customer => 'CUST_CODE',
                      callback => sub { print $_[0], "\n" },
                      item => '021200-82221' );

or

XAO::P21->new->avail( item => [ '021200-82221', '021200-082222' ] );

=cut  

sub avail {
    my ($self, %param) = @_;
    my $item=$param{item};
    $self->call( sub {
        my ($code, $location, $stlev, $junk1, $unit,
            $description, $junk2, $locn) = split /\t/, $_[0];
        {
            code        => $code,
            location    => $location,
            stock_level => $stlev,
            unit        => $unit,
            description => $description,
            descript2   => $junk2,
            location_code => $locn,
        }
        }, $param{callback}, 'avail', $param{customer} || '?',
        ref($item) eq 'ARRAY' ? @$item : $item);
}
        
=head1 catalog

Returns full catalog items list. See "items" for data layout and attributes order.

=cut  

sub catalog {
    my ($self, $callback) = @_;
    $self->items($callback, 'catalog');
}

=head1 custinfo

Returns list with info about customers. Each line contains attributes,
delimited with "\t":

bill_to_name, cust_code, bill_to_addr1, bill_to_addr2, bill_to_addr3,
bill_to_city, bill_to_state, bill_to_zip, telephone, aux_fax, email_address,
slm_number (territory/salesman number), first_sale (date of first sale).

Synopsis:

my $rlist=$client->custinfo;

$client->custinfo( \&some_callback );

$client->custinfo( callback=>\&some_callback, code=>['21CASH, 'PI10MP'] );

my $rlist = $client->custinfo( code => '21CASH' );

=cut  

sub custinfo {
    my $self=shift;
    my $callback;
    my $custinfo;
    if( @_ == 1 && ref($_[0]) ne 'HASH' ) {
        $callback = $_[0];
        $custinfo = [];
    } else {
        my $args = get_args(\@_);
        $callback = $args->{callback};
        $custinfo = $args->{info};
        $custinfo = [ $custinfo ] if(ref($custinfo) ne 'ARRAY'); 
    }
    $self->call( sub {
                 my (
                     $bill_to_name,
                     $cust_code,
                     $bill_to_addr1,
                     $bill_to_addr2,
                     $bill_to_addr3,
                     $bill_to_city,
                     $bill_to_state,
                     $bill_to_zip,
                     $telephone,
                     $aux_fax,
                     $email_address,
                     $slm_number,
                     $first_sale
                    ) = split '\t', $_[0];
                 {
                     bill_to_name       => $bill_to_name,
                     cust_code  => $cust_code,
                     bill_to_addr1      => $bill_to_addr1,
                     bill_to_addr2      => $bill_to_addr2,
                     bill_to_addr3      => $bill_to_addr3,
                     bill_to_city       => $bill_to_city,
                     bill_to_state      => $bill_to_state,
                     bill_to_zip        => $bill_to_zip,
                     telephone  => $telephone,
                     aux_fax    => $aux_fax,
                     email_address      => $email_address,
                     slm_number => $slm_number,
                     first_sale => $first_sale,
                 }
                 }, $callback, 'custinfo', @$custinfo);
}

=head1 modcust

Modifies customer data, according to custinfo.

=cut

sub modcust {
    my $self=shift;
    my $args=get_args(\@_);
    print STDERR join(' ',(
                     $args->{cust_code},
                     $args->{bill_to_name},
                     $args->{bill_to_addr1},
                     $args->{bill_to_addr2},
                     $args->{bill_to_addr3},
                     $args->{bill_to_city},
                     $args->{bill_to_state},
                     $args->{bill_to_zip},
                     $args->{telephone},
                     $args->{aux_fax},
                     $args->{email_address},
                     $args->{slm_number},
                     $args->{first_sale},
                          ), "\n");
    $self->call(sub { $_[0] }, undef, 'mod_custinfo',
                     $args->{cust_code},
                     $args->{bill_to_name},
                     $args->{bill_to_addr1},
                     $args->{bill_to_addr2},
                     $args->{bill_to_addr3},
                     $args->{bill_to_city},
                     $args->{bill_to_state},
                     $args->{bill_to_zip},
                     $args->{telephone},
                     $args->{aux_fax},
                     $args->{email_address},
                     $args->{slm_number},
                     $args->{first_sale});
}
    
=head1 order

Places order into spool. The only argument is ref to list of ref to hashes.
The hash contains following attributes:

=over

=item reference_number - a unique string which is used to name the temporary order file in the P21 ecommerce spool folder.

=item customer - the Prophet 21 unique customer code.

=item date - formatted Year Month Day without any delimiters, e.g. 020206

=item po - the customer's purchase order number

=item credit_card - the customer's credit card number if applicable

=item card_exp_month - customer's cc expiry month

=item card_exp_year - customer's cc expiry year

=item name - the customer's dba name

=item address1 - the first ship-to address line

=item address2 - the second ship-to address line

=item city - the customer's ship-to city

=item state - the customer's ship-to state

=item zip - the customer's ship-to zip

=item inst1 - a short instruction field of 30 characters

=item inst2 - the second short instruction field of 30 chars

=item line_number - the row number for this entry, first row being 1 (one)

=item qty - quantity ordered for this item

=item itemcode - a valid P21 itemcode (not a customer itemcode!)

=item price - the unit price, not the total price

=item email - email address for further notification
     
=back 

Returns a hash reference with 'result' and 'info' members. Where
result is zero for success and info contains internally used
order ID which is the same as provided currenly.

=cut  

sub order {
    my $self=shift;
    my $order_list=shift;

    my $constr=sub {
        my ($result, $info) = split /\t/, $_[0];
        return { result => $result, info => $info };
    };

    my $callback=sub {
        $_[0];
    };

    my @order_array=map {
        $_->{reference_number},
        $_->{customer},
        $_->{date},
        $_->{po},
        $_->{credit_card},
        $_->{card_exp_month},
        $_->{card_exp_year},
        $_->{name},
        $_->{address1},
        $_->{address2},
        $_->{city},
        $_->{state},
        $_->{zip},
        $_->{inst1},
        $_->{inst2},
        $_->{line_number},
        $_->{itemcode},
        $_->{qty},
        $_->{price},
        $_->{email},
    } @$order_list;

    $self->call($constr,$callback, 'order_entry', @order_array);
}

=head1 price

Asks for price. Input data is: customer code ("?" is allowed), item_code,
quantity.
Returns reference to hash:

{ price=>price_per_unit, mult=>multiplier, total=>price * mult * quantity }

(Net price) = (price per unit) * multiplier.

=cut  

sub price {
    my $self=shift;
    my $args=get_args(\@_);

    my $quantity = $args->{quantity} || 1;
    my $customer = $args->{customer};
    my $itemcode = $args->{itemcode} || $args->{item};

    $self->call(sub {
                    my ($price, $mult) = split /\t/, $_[0];
                    return {
                        price   => $price,
                        mult    => $mult,
                        total   => $price * $mult * $quantity,
                    };
                },
                sub {
                    return $_[0];
                },
                'price',
                $customer,
                $itemcode,
                $quantity);
}

=head1 list_all_open_orders

The server returns list of all open orders for given customer.
Each line contains order number and shipment number.

=cut

sub list_all_open_orders {
    my ($self, %param) = @_ ;
    $self->call( sub {
                     my (
                         $cust_po,
                         $ord_number,
                         $ord_date,
                         $req_date,
                         $total,
                         $open
                        ) = split /\t/, $_[0];
                     {
                         cust_po        => $cust_po,
                         ord_number     => $ord_number,
                         ord_date       => $ord_date,
                         req_date       => $req_date,
                         totalqty       => $total,
                         openqty        => $open,
                     }
                     }, $param{callback},
                     'list_all_open_orders',
                     $param{customer} || '?' ); # XXX
}

=head1 view_open_order_details

Returns info about given order of given customer. Example:

    my $res=$cl->view_open_order_details(customer=>"21CASH", order=>1234567);

Returns array of hash references with order line infos.

Another example:

    my $res=$cl->view_open_order_details(customer=>"21CASH",
                                         order=>1234567,
                                         callback=>\&print_each_line);

=cut

sub view_open_order_details {
    my ($self, %param) = @_ ;
    $self->call( sub {
                     my (
                         $item,
                         $desc,
                         $ord_qty,
                         $unit,
                         $net_price,
                         $open_qty,
                         $open_value,
                         $exp_date,
                         $last_shipment,
                         $disposition,
                         $disposition_desc,
                        ) = split /\t/, $_[0];
                     {
                         item   => $item,
                         desc   => $desc,
                         ord_qty        => $ord_qty,
                         unit   => $unit,
                         net_price      => $net_price,
                         open_qty       => $open_qty,
                         open_value     => $open_value,
                         exp_date       => $exp_date,
                         last_shipment  => $last_shipment,
                         disposition => $disposition,
                         disposition_desc => $disposition_desc,
                     }
                     }, $param{callback}, 'view_open_order_details',
                    $param{customer} || '?', # XXX
                    $param{order} );
}

=head1 list_all_invoices

Lists all invoices for given customer.

=cut

sub list_all_invoices {
    my ($self, %param) = @_ ;
    $self->call( sub {
                     my ( $order, $shipment ) = split /\t/, $_[0];
                     { order => $order, shipment => $shipment }
                     }, $param{callback}, 
                     'list_all_invoices', $param{customer} || '?' );
}

=head1 invoice_recall

Returns preformatted invoice text for given pair order-shipment. If callback is
provided, then it is called for each chomped line, otherwise the method returns
reference to list of all lines without trailing "\n".

=cut

sub invoice_recall {
    my ($self, %param) = @_;
    $self->call( sub { chomp $_[0]; $_[0] },
                 $param{callback}, 'invoice_recall',
                 $param{customer} || '?',
                 $param{order}, $param{shipment} );
}

=head1 list_open_ar

list_open_ar (Open Accounts Receivable).
Required input: customer_code
Output: Invoice/Order Number, Invoice Date, Customer PO, Amount,
Open Amount, part of invoice number before "-',
part of invoice number after "-', Discount Date, Due Date.

=cut

sub list_open_ar {
    my ($self, %param) = @_ ;
    $self->call( sub {
                     my ( $invnumber,
                          $invdate,
                          $cust_po,
                          $amount,
                          $amount_open,
                          $order,
                          $invoice,
                          $disc_date,
                          $due_date ) = split /\t/, $_[0];
                     {
                     invnumber  => $invnumber,
                     invdate    => $invdate,
                     cust_po    => $cust_po,
                     amount     => $amount,
                     amount_open        => $amount_open,
                     order      => $order,
                     invoice    => $invoice,
                     disc_date  => $disc_date,
                     due_date   => $due_date,
                     }
                     }, $param{callback}, 
                     'list_open_ar', $param{customer} || '?' );
}

=head1 match

Finds matches of order numbers for reference numbers.  Returns hash with keys:
refnum (customer reference number), file (OS filename), order (P21 order
number).

=cut

sub find_match {
    my $self = shift;
    my $args = get_args(\@_);
    $self->call( sub {  my ($refnum, $file, $order) = split /\t/, $_[0];
                        { refnum => $refnum, file => $file, order => $order } },
                 $args->{callback}, 'find_match', @{$args->{refs}} );
}

=head1 show_spool

Shows contents of order spool directory, one filename per line.

=cut

sub show_spool {
    my ($self, $callback) = @_;
    $self->call(sub { $_[0] }, $callback, 'show_spool');
}

=head1 cleanup_spool

Removes one or more files from order spool directory.

Synopsis:

$client->cleanup_spool(file=>['file1', 'file2']);

=cut

sub cleanup_spool {
    my $self = shift;
    my $args = get_args(\@_);
    $self->call(sub { 0 }, undef, 'cleanup_spool', @{$args->{file}} );
}

=head1 BUGS

The documentation is too incomplete.
Remote exceptions are unhandled.

=head1 AUTHOR

E.Karpachov, jk@xao.com

=head1 SEE ALSO

perl(1), P21_Acclaim(3), XAO::Errors(3)

=cut

1;

__END__
