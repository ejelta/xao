package XAO::P21;
use strict;
use IO::Socket::INET;
use XAO::Errors qw(XAO::P21);
use XAO::Utils;

##
# Package version
#
use vars qw($VERSION);
$VERSION = '0.10';

###############################################################################

=head1 NAME

XAO::P21 - Perl extension for network interaction with prophet21.

=head1 SYNOPSIS

  use XAO::P21;

=head1 DESCRIPTION

This module is intended for remote interaction with prophet21 system; it is
mainly a client-side stub for web server.

=head1 METHODS

=over

=cut

###############################################################################

=item new

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

###############################################################################

=item call ($build, $callback, @params)

(Private method)

Sends untranslated list of parameters to the server and receives
results. Results are given to `build' subroutine and then to
`callback'. Usually `build' would split individual fields to an array or
hash, and `callback' would print or somehow use these values.

Default callback is to create an array of all resulting rows and then
return a reference to this array.

Build does not have a default and must be provided.

=cut

sub call {
    my ($self, $build, $callback, @params) = @_ ;

    ##
    # Fixing params, newlines are not acceptable in them
    #
    my $command=join("\t",map {
        my $s=defined($_) ? $_ : '';
        $s=~s/[\t\r\n]+/ /sg;
        $s=~s/^\s*(.*?)\s*$/$1/;
        $s;
    } @params);

    my $list;
    if(!$callback) {
        $list=[];
        $callback = sub { push @$list, $_[0]; $list };
    }

    $self->connect unless $self->{Socket};
    my $socket=$self->{Socket};

    my $flag=0;
    local $SIG{'PIPE'} = sub { $flag = 1 };
    print $socket $command."\n";
    unless ($flag) {
        my $result;
        while(<$socket>) {
            chomp;
            if(/ISAM.*file not found/i) {
                die "Got error from P21 server ($_)";
            }
            return $result if /^\.$/;
            $result = $callback->($build->($_));
        }
        delete $self->{'Socket'};
        throw XAO::E::P21 "call - unexpected eof reading from socket";
    }

    delete $self->{'Socket'};
    throw XAO::E::P21 "call - SIGPIPE writing to socket";
}

###############################################################################

=item items

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
            $desc1, $desc2, $upc, $cat_page) = split /\t/, $_[0];
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
            cat_page    => $cat_page,
        }
    }, $callback, $table || 'items');
}

###############################################################################

=item stock

Returns availability info for each of given item codes. The info contains
lines with non-zero quantities only.

Synopsis:

XAO::P21->new->stock( callback => sub { print $_[0], "\n" },
                      item => '021200-82221' );

or

XAO::P21->new->stock( item => [ '021200-82221', '021200-82222' ] );

=cut  

sub stock {
    my $self=shift;
    my $args=get_args(\@_);

    my $item=$args->{'item'};
    return $self->call(
        sub {
            my ($item_code, $location, $stock_level)=split(/\t/,$_[0]);
            return {
                item_code   => $item_code,
                location    => $location,
                stock_level => $stock_level,
            }
        },
        $args->{'callback'},
        'stock',
        ref($item) eq 'ARRAY' ? @$item : $item,
    );
}

###############################################################################

=item catalog

Returns full catalog items list. By default, if no 'callback' function
is provided it will return a reference to an array of hash references:

 item_code      => item code
 prod_group     => category
 sales_group    => sales schedule referencing sell_schd table
 vend_number    => secondary key for sales schedule matching
 pkg_size       => package size
 sales_unit     => sales unit
 sku            => stock keeping unit
 desc1          => description line 1
 desc2          => description line 2
 upc            => UPC
 cat_page       => product flags
 purc_group     => purc_group == 8000 indicates contract pricing
 list_price     => list price
 std_cost       => cost
 col1_price     => column 1 price
 col2_price     => column 1 price
 col3_price     => column 1 price
 catg_list      => category end point
 stock_free     => "free" stock level, total at all divisions
 stock_allocated=> "allocated" stock level, total at all divisions
 alt_units      => array of alternative units if any, each
                   one in NAME/SIZE format

=cut  

sub catalog {
    my ($self, $callback) = @_;
    $self->call( sub {
        my ($item_code, $prod_group, $sales_group, $vend_number,
            $pkg_size, $sales_unit,
            $sku, $desc1, $desc2, $upc, $cat_page, $purc_group,
            $list_price, $std_cost,
            $col1_price, $col2_price, $col3_price, $catg_list,
            $stock_free, $stock_allocated,
            @alt_units) = split /\t/, $_[0];
        return {
            item_code       => $item_code,
            prod_group      => $prod_group,
            sales_group     => $sales_group,
            vend_number     => $vend_number,
            pkg_size        => $pkg_size,
            sales_unit      => $sales_unit,
            sku             => $sku,
            desc1           => $desc1,
            desc2           => $desc2,
            upc             => $upc,
            cat_page        => $cat_page,
            purc_group      => $purc_group,
            list_price      => $list_price,
            std_cost        => $std_cost,
            col1_price      => $col1_price,
            col2_price      => $col2_price,
            col3_price      => $col3_price,
            catg_list	    => $catg_list,
            stock_free      => $stock_free,
            stock_allocated => $stock_allocated,
            alt_units       => \@alt_units,
        };
    }, $callback, 'catalog');
}

###############################################################################

=item cust_item

Returns custom priced items in an array of hashes:

  cust_code     => customer code
  item_code     => standard item code
  part_number   => custom part number for the item (optional)
  sales_price   => price to sell that item for
  int_desc      => content of int_desc field used to reference alias products

=cut  

sub cust_item {
    my $self=shift;
    my $args=get_args(\@_);

    my $callback=$args->{'callback'};

    my $build=$args->{'build'} || sub {
        my %row;
        @row{qw(cust_code item_code part_number sales_price int_desc)}=
            split('\t',$_[0]);
        $row{'int_desc'}||='';

        defined $row{'sales_price'} ||
            throw XAO::E::P21 "cust_item - P21 error ($_[0])";

        return \%row;
    };

    $self->call($build,$callback,'cust_item');
}

###############################################################################

=item edi_fetch

Fetches an EDI document form the server:

    my $res=$cl->edi_fetch(doc_number => 1234567);

Returns array of lines with the content of the document.

=cut

sub edi_fetch {
    my $self=shift;
    my $args=get_args(\@_);

    my $doc_number=$args->{'doc_number'} ||
        throw XAO::E::P21 "edi_fetch - no 'doc_number' given";

    my $build=sub {
        my $str=shift;
        return $str;
    };

    return $self->call($build,
                       $args->{'callback'},
                       'edi_fetch',
                       $doc_number);
}

###############################################################################

=item sell_schd

Returns sell_schd dump:

  disc_group                => code referenced by 'sales_group'
  vend_number               => vendor number from catalog or '' for default
  item_code                 => item_code
  disc_basis_disp           => PIECE or COL1
  disc_code_disp            => COL1 or LIST or PRICE
  disc_type_disp            => MULT
  break_1 .. break_8        => break levels
  discount_1 .. discount_8  => break values

The dump actually lists data from two similar P21 tables -- pc_override
and sell_schd. Pc_override has item_codes, but does not have
disc_group/vend_number. Sell_schd is the opposite, it does not have
item_code.

=cut  

sub sell_schd {
    my $self=shift;
    my $args=get_args(\@_);

    my $callback=$args->{'callback'};

    my $build=$args->{'build'} || sub {
        my ($group,$vendor,$basis,$code,$type,$breaks,$discounts,$item_code)=
            split('\t',$_[0]);

        (defined $breaks && defined $discounts) ||
            throw XAO::E::P21 "sell_schd - wrong P21 line ($_[0])";

        $group='' if ($group eq '*' || $group eq '?');
        $vendor='' if ($vendor eq '*' || $vendor eq '?');
        $item_code='' if ($item_code eq '*' || $item_code eq '?');

        my @b=split(/\//,$breaks);
        my @d=split(/\//,$discounts);
        my %row=(
            disc_group      => $group,
            vend_number     => $vendor,
            item_code       => $item_code,
            disc_basis_disp => $basis,
            disc_code_disp  => $code,
            disc_type_disp  => $type,
        );
        for(my $i=1; $i<=8; $i++) {
            $row{"break_$i"}=$b[$i-1] || 0;
            $row{"discount_$i"}=$d[$i-1] || 0;
        }
        return \%row;
    };

    $self->call($build,$callback,'sell_schd');
}

###############################################################################

=item custcreate

Creates a customer in P21 with a pre-defined cust-code.

=cut

sub custcreate {
    my $self=shift;
    my $info=get_args(\@_);

    my $constr=sub {
        my ($result, $info) = split /\t/, $_[0];
        return { result => $result, info => $info };
    };

    my $callback=sub {
        $_[0];
    };

    my $cust_code=$info->{'cust_code'} || throw XAO::E::P21 "custcreate - no 'cust_code' given";
    $cust_code=~/^\w{3,6}$/ || throw XAO::E::P21 "custcreate - bad cust_code='$cust_code'";
    $cust_code eq uc($cust_code) || throw XAO::E::P21 - "custcreate - cust_code ($cust_code) must be all-uppercase";

    my %stax=(
        'SOME'  => 1,
        'NONE'  => 2,
        'ALL'   => 3,
    );
    my $stax_flag=$info->{'stax_flag'} || ($info->{'stax_exemp'} ? 'NONE' : 'ALL');
    $stax_flag=$stax{uc($stax_flag)} if $stax{uc($stax_flag)};

    # We convert the customer data into an array in the same order as
    # expected by P21.
    #
    my @cust_array=map { (my $a=$_)=~s/[\t\r\n]+/ /g; $a } (
        $cust_code,                                 # 01 Customer Code         CHAR  6                                        
        $info->{'bill_to_contact_title'} || '',     # 02 Bill-To Contact Title CHAR 26                                        
        $info->{'bill_to_contact_name'} || '',      # 03 Bill-To Contact Name  CHAR 26                                        
        $info->{'bill_to_name'} || '',              # 04 Bill-To Name          CHAR 30                                        
        $info->{'bill_to_addr1'} || '',             # 05 Bill-To Address 1     CHAR 26                                        
        $info->{'bill_to_addr2'} || '',             # 06 Bill-To Address 2     CHAR 26                                        
        $info->{'bill_to_addr3'} || '',             # 07 Bill-To Address 3     CHAR 26                                        
        $info->{'bill_to_city'} || '',              # 08 Bill-To City          CHAR 14                                        
        $info->{'bill_to_state'} || '',             # 09 Bill-To State         CHAR  3                                        
        $info->{'bill_to_zip'} || '',               # 10 Bill-To Zip           CHAR 10                                        
        $info->{'bill_to_country'} || '',           # 11 Bill-To Country       CHAR 30                                        
        $info->{'telephone'} || '',                 # 12 Bill-To Telephone     CHAR 30                                        
        $info->{'aux_fax'} || '',                   # 13 Bill-To Fax           CHAR 30                                        
        $info->{'email_address'} || '',             # 14 Bill-To Email         CHAR 48                                        
        $info->{'ship_to_name'} || '',              # 15 Ship-To Name          CHAR 30                                        
        $info->{'ship_to_addr1'} || '',             # 16 Ship-To Address 1     CHAR 26                                        
        $info->{'ship_to_addr2'} || '',             # 17 Ship-To Address 2     CHAR 26                                        
        $info->{'ship_to_addr3'} || '',             # 18 Ship-To Address 3     CHAR 26                                        
        $info->{'ship_to_city'} || '',              # 19 Ship-To City          CHAR 14                                        
        $info->{'ship_to_state'} || '',             # 20 Ship-To State         CHAR  3                                        
        $info->{'ship_to_zip'} || '',               # 21 Ship-To Zip           CHAR 10                                        
        $info->{'ship_to_country'} || '',           # 22 Ship-To Country       CHAR 30                                        
        $info->{'invoice_batch_number'} || 0,       # 23 Invoice Batch Number   NUM 99  None.                                 
        $info->{'packing_basis'} || 0,              # 24 Packing Basis          NUM 99  PART, IT-P, ORD, HOLD, IT-C, P-ORD, TAG
        $info->{'stax_exemp'},                      # 25 State Tax Exempt ID   CHAR 12                                        
        $stax_flag,                                 # 26 State Tax Flag         NUM 99  SOME=1, NONE=2, ALL=3
        $info->{'ship_to_contact_name'} || '',      # 27 Ship-To Contact Name  CHAR 26                                        
        $info->{'ship_to_contact_title'} || '',     # 28 Ship-To Contact Title CHAR 26                                        
        $info->{'ship_to_telephone'} || '',         # 29 Ship-To Phone         CHAR 30                                        
        $info->{'ship_to_fax'} || '',               # 30 Ship-To Fax           CHAR 30                                        
        $info->{'ship_to_email_address'} || '',     # 31 Ship-To E-mail        CHAR 48                                        
        $info->{'shipment_transit_days'} || '',     # 32 Shipment Transit Days  NUM 99  None. 
        'KEEP',
    );

    return $self->call($constr,$callback,'custcreate',@cust_array);
}

###############################################################################

=item custinfo

Returns list with info about customers. Each entry in the list is a
hash:

  cust_code     => 
  bill_to_name  => 
  bill_to_addr1 => 
  bill_to_addr2 => 
  bill_to_addr3 => 
  bill_to_city  => 
  bill_to_state => 
  bill_to_zip   => 
  telephone     => 
  aux_fax       => 
  email_address => 
  slm_number    => territory/salesman number
  first_sale    => date of first sale
  stax_exemp    => if non-empty then this customer has tax exempt
                   documents on file
  stax_flag     => one of ALL/NONE/SOME
  otax_exemp    => if non-empty then this customer has federal tax exemption
  otax_flag     => one of ALL/NONE/SOME
  inv_batch     => invoice batch number
  sic           => SIC number
  default_loc   => default warehouse for the customer
  sales_loc     => sales warehouse for the customer
  source_loc    => source warehouse for the customer

Default is to return complete list of all customers, be careful as it
can take a lot of time to do so.

Synopsis:

 my $rlist=$client->custinfo;

 $client->custinfo(callback => \&some_callback,
                   code     => ['21CASH, 'PI10MP']);

 my $rlist = $client->custinfo(code => '21CASH');

=cut  

sub custinfo {
    my $self=shift;
    my $args=get_args(\@_);

    my $custinfo=$args->{'code'} || [];
    $custinfo=[ $custinfo ] unless ref($custinfo) eq 'ARRAY'; 

    my $callback=$args->{'callback'};

    my $build=$args->{'build'} || sub {
        my %row;
        @row{qw(bill_to_name cust_code bill_to_addr1 bill_to_addr2
                bill_to_addr3 bill_to_city bill_to_state bill_to_zip
                telephone aux_fax email_address slm_number first_sale
                stax_exemp stax_flag otax_exemp otax_flag
                inv_batch sic
                default_loc sales_loc source_loc
               )}=map { $_ eq '?' ? undef : $_ } split('\t',$_[0]);
        return \%row;
    };

    $self->call($build,$callback,'custinfo',map { uc } @$custinfo);
}

###############################################################################

=item modcust

Modifies customer data, according to custinfo.

=cut

sub modcust {
    my $self=shift;
    my $args=get_args(\@_);
    throw $self "modcust - not supported, has never been tested";
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

###############################################################################

=item order

Places order into spool. The only argument is ref to list of hash-refs.
Each hash contains following attributes:

 reference_number => a unique string which is used to name the temporary
                     order file in the P21 ecommerce spool folder.
 customer         => the Prophet 21 unique customer code.
 date             => formatted Year Month Day without any delimiters,
                     e.g. 020206
 po               => the customer's purchase order number
 credit_card      => the customer's credit card number if applicable
 card_exp_month   => customer's cc expiry month
 card_exp_year    => customer's cc expiry year
 name             => the customer's dba name
 address1         => the first ship-to address line
 address2         => optional second ship-to address line
 address3         => optional third ship-to address line
 city             => the customer's ship-to city
 state            => the customer's ship-to state
 zip              => the customer's ship-to zip
 country          => ship-to country
 inst1            => a short instruction field of 30 characters
 inst2            => the second short instruction field of 30 chars
 line_number      => the row number for this entry, first row being 1 (one)
 qty              => quantity ordered for this item
 itemcode         => a valid P21 itemcode (not a customer itemcode!)
 price            => base unit price (unit_price/unit_size)
 unit_name        => unit name
 unit_size        => unit size
 email            => email address for further notification
 stax_exemp       => order line sales tax exemption status
 suspended_order  => boolean for the initial state of the order
                     once injected into p21
 taker_number     => taker number
 schedule         => delivery schedule (list reference)
    quantity          => quantity to ship
    ship_date         => mm/dd/yy of when to ship

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

    ##
    # Building a single array that contains all of the data. Not the
    # best way to handle it, admittedly.
    #
    my @order_array;
    foreach my $l (@$order_list) {

        ##
        # Preparing a schedule line if needed. The line gets parsed on the
        # receiving end and then stored into the corresponding .release
        # file.
        # NOTE: The receiving counterpart has to split it up into
        # exactly the same number of fields.
        #
        my $schedule='';
        my $sdata=$l->{'schedule'};
        if($sdata && @$sdata) {
            for(my $i=0; $i<18 && $i<@$sdata; ++$i) {
                my $qty=$sdata->[$i]->{'quantity'};
                my $ship_date=$sdata->[$i]->{'ship_date'};
                next unless $qty && $ship_date =~ /^\d+\/\d+\/\d+$/;
                $schedule.="|" if $schedule;
                $schedule.="$qty:$ship_date:$ship_date:$ship_date";
            }
        }

        if(length(uc($l->{'customer'}))>6) {
            eprint "Order $l->{'reference_number'} has cust-code longer than 6 chars '$l->{'customer'}'";
            return {
                error => 'Data format error',
            };
        }

        for(@{$l}{qw(customer po name address1 address2 city state inst1 inst2)}) {
            s/\//-/g;
        }

        push(@order_array,(
            substr(uc($l->{'reference_number'}),0,30),  #  1 |  1
            substr(uc($l->{'customer'}),0,6),           #  2 |  2
            substr(uc($l->{'date'}),0,6),               #  3 |  3
            substr(uc($l->{'po'}),0,18),                #  4 |  4
            substr(uc($l->{'credit_card'}),0,16),       #  5 |  5
            substr(uc($l->{'card_exp_month'}),0,2),     #  6 |  6
            substr(uc($l->{'card_exp_year'}),0,4),      #  7 |  7
            substr(uc($l->{'name'}),0,30),              #  8 |  8
            substr(uc($l->{'address1'}),0,26),          #  9 |  9
            substr(uc($l->{'address2'}),0,26),          # 10 | 10
            substr(uc($l->{'city'}),0,14),              # 11 | 11
            substr(uc($l->{'state'}),0,2),              # 12 | 12
            substr(uc($l->{'zip'}),0,10),               #  1 | 13
            substr(uc($l->{'inst1'}),0,30),             #  2 | 14
            substr(uc($l->{'inst2'}),0,30),             #  3 | 15
            uc($l->{'line_number'}),                    #  4 | 16
            $l->{'itemcode'},                           #  5 | 17
            uc($l->{'qty'}),                            #  6 | 18
            uc($l->{'price'}),                          #  7 | 19
            uc($l->{'email'}),                          #  8 | 20
            '',                                         #  9 | 21
            '',                                         # 10 | 22
            '',                                         # 11 | 23
            '',                                         # 12 | 24
            '',                                         #  1 | 25
            '',                                         #  2 | 26
            '',                                         #  3 | 27
            '',                                         #  4 | 28
            $l->{'stax_exemp'} ? 'N' : 'Y',             #  5 | 29
            $l->{'suspended_order'} ? 'Y' : 'N',        #  6 | 30
            uc($l->{'unit_name'} || ''),                #  7 | 31
            $l->{'unit_size'} || 1,                     #  8 | 32
            substr(uc($l->{'account_number'} || ''),0,14), #  9 | 33
            '',                                         # 10 | 34
            '',                                         # 11 | 35
            substr(uc($l->{'address3'} || ''),0,26),    # 12 | 36
            uc($l->{'country'} || ''),                  #  1 | 37
            '',                                         #  2 | 38
            uc($l->{'taker_number'} || ''),             #  3 | 39 (SALES)
            '',                                         #  4 | 40
            $schedule || 'N',                           #  5 | 41 (BLANKET)
        ));
    }

    return $self->call($constr,$callback, 'order_entry', @order_array);
}

###############################################################################

=item price

Asks for price. Input data is: customer code ("?" is allowed), item_code,
quantity. Returns reference to a hash:

 price      => price per unit
 mult       => multiplier
 total      => price * mult * quantity

Net price is (price per unit) * multiplier.

=cut  

sub price {
    my $self=shift;
    my $args=get_args(\@_);

    my $quantity = $args->{quantity} || 1;
    my $customer = $args->{customer};
    my $itemcode = $args->{itemcode} || $args->{item};

    $self->call(sub {
                    my ($price, $mult) = split /\t/, $_[0];
                    $price=0 if $price eq '?';
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

###############################################################################

=item puser

Returns a list of all users, their authorization levels, branches and
encrypted passwords.

  user_id   => 
  branch    => 
  security  => 
  name      => 
  password  => 
  generic   => generic name lookup in /etc/mail/generics

=cut  

sub puser {
    my $self=shift;
    my $args=get_args(\@_);

    my $callback=$args->{'callback'};

    my $build=$args->{'build'} || sub {
        my %row;
        @row{qw(user_id branch name security_2 password generic)}=split('\t',$_[0]);
        return \%row;
    };

    $self->call($build,$callback,'puser');
}

###############################################################################

=item view_order_details

Returns full information about the given order. Example:

    my $res=$cl->view_order_details(order_id => 1234567);

Returns array of hash references with order line infos.

Another example:

    my $res=$cl->view_order_details(order_id => 1234567,
                                    callback => \&print_each_line);

=cut

sub view_order_details {
    my $self=shift;
    my $args=get_args(\@_);

    my $order_id=$args->{'order_id'} ||
        throw XAO::E::P21 "view_order_details - no 'order_id' given";

    my $build=sub {
        my $str=shift;
        my @arr=split(/\t/,$str);

        my %line;
        if($arr[0] eq 'LINE') {
            @arr==15 ||
                throw XAO::E::P21 "view_order_details - wrong LINE ($str)";
            @line{qw(type line_number item_code entry_date
                     ord_qty inv_qty canc_qty
                     ut_price ut_size
                     disposition disposition_desc
                     ship_loc
                     req_date
                     suspend_flag
		     part_number
		    )}=@arr;
            $line{'suspend_flag'}=lc($line{'suspend_flag'} || '') eq 'no' ? 0 : 1;
            $line{'part_number'}='' if $line{'part_number'} eq '?';
        }
        elsif($arr[0] eq 'INVOICE') {
            @arr==20 ||
                throw XAO::E::P21 "view_order_details - wrong INVOICE ($str)";
            @line{qw(type ship_number ord_date inv_date ship_date
                     total_stax_amt out_freight cust_code
                     ship_inst1 ship_branch
                     ship_to_name ship_to_addr1 ship_to_addr2 ship_to_addr3
                     ship_to_city ship_to_state ship_to_zip
                     ar_amt cust_po sales_loc
                    )}=@arr;
        }
        elsif($arr[0] eq 'ITEM') {
            @arr==6 ||
                throw XAO::E::P21 "view_order_details - wrong ITEM ($str)";
            @line{qw(type ship_number item_code inv_qty line_number part_number)}=@arr;
            $line{'part_number'}='' if $line{'part_number'} eq '?';
        }
        elsif($arr[0] eq 'BLANKET') {
            @arr==13 ||
                throw XAO::E::P21 "view_order_details - wrong BLANKET ($str)";
            @line{qw(type line_number item_code
                     date_number
                     release_exp_date release_inv_date
                     release_rel_qty release_inv_qty
                     release_allo_qty release_canc_qty
                     release_comp_flag release_disp
                     release_rel_date
                    )}=@arr;
        }
        elsif($arr[0] eq 'ORDER') {
            @arr==8 ||
                throw XAO::E::P21 "view_order_details - wrong ORDER ($str)";
            @line{qw(type line_number cust_code cust_po sales_loc req_date ord_date suspend_flag
                    )}=@arr;
        }
        elsif($arr[0] eq 'SHIPPED') {
            @arr==6 ||
                throw XAO::E::P21 "view_order_details - wrong SHIPPED ($str)";
            @line{qw(type line_number inv_date ship_number ship_line ship_qty
                    )}=@arr;
        }
        else {
            throw XAO::E::P21 "view_order_details - unknown type=$arr[0] ($str)";
        }

        return \%line;
    };

    return $self->call($build,
                       $args->{'callback'},
                       'view_order_details',
                       $order_id);
}

###############################################################################

=item find_match

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

###############################################################################

=item isalive

Checks if P21 system is ready and connected to its database -- tables
are available.

=cut

sub isalive {
    my $self=shift;
    my $response='';
    $self->call(sub { $response.=$_[0] }, undef, 'isalive');
    return $response eq 'catalog/customer/order/wbw_head/' ? $response : undef;
}

###############################################################################

=item show_spool

Shows contents of order spool directory, one filename per line.

=cut

sub show_spool {
    my ($self, $callback) = @_;
    $self->call(sub { $_[0] }, $callback, 'show_spool');
}

###############################################################################

=item cleanup_spool

Removes one or more files from order spool directory.

Synopsis:

$client->cleanup_spool(file=>['file1', 'file2']);

=cut

sub cleanup_spool {
    my $self = shift;
    my $args = get_args(\@_);
    $self->call(sub { 0 }, undef, 'cleanup_spool', @{$args->{file}} );
}

###############################################################################

=item ord_past

Retrieves data about items shipped for past orders both from real p21
orders and from web orders. Takes date and returns data for only items
with ord_line.entry_date past that given date.

Example:

 $client->ord_past(year => 2003, month => 11, day => 21);

Accepts 'callback' argument and will pass all fields to it in a hash
reference:

 cust_code  => order.cust_code
 ord_date   => order.ord_date
 ord_number => ord_line.ord_number = order.ord_number
 item_code  => ord_line.item_code
 entry_date => ord_line.entry_date

=cut

sub ord_past ($%) {
    my $self=shift;
    my $args=get_args(\@_);

    my $year=$args->{year} ||
        throw XAO::E::P21 "ord_past - no 'year' given";
    my $month=$args->{month} ||
        throw XAO::E::P21 "ord_past - no 'month' given";
    my $day=$args->{day} ||
        throw XAO::E::P21 "ord_past - no 'day' given";

    my $build=sub {
        my $str=shift;

        my @arr=split(/\t/,$str);
        scalar(@arr)>=5 ||
            throw XAO::E::P21 "ord_past - expected 5 fields ($str)";

        my %line;
        @line{qw(cust_code ord_date ord_number item_code entry_date)}=@arr;

        return \%line;
    };

    $self->call($build,
                $args->{callback},
                'ord_past',
                $year,$month,$day);
}

###############################################################################

=item ping

Pings remote server.

=cut

sub ping {
    my $self=shift;
    my $response='';
    $self->call(sub { $response.=$_[0] }, undef, 'ping');
    return $response;
}

###############################################################################

=item units

Returns a list of unit_name/unit_description pairs

=cut  

sub units {
    my $self=shift;
    my $args=get_args(\@_);

    my $callback=$args->{'callback'};

    my $build=$args->{'build'} || sub {
        my %row;
        @row{qw(unit_name unit_description)}=split('\t',$_[0]);
        return \%row;
    };

    $self->call($build,$callback,'units');
}


###############################################################################
1;
__END__

=back

=head1 BUGS

The documentation is too incomplete. Remote exceptions are unhandled.

=head1 AUTHORS

Copyright (c) 2001-2002 XAO Inc.

E.Karpachov <jk@xao.com>, Andrew Maltsev <am@xao.com>

=head1 SEE ALSO

perl(1), P21_Acclaim(3), XAO::Errors(3)
