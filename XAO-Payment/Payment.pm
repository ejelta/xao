=head1 NAME

XAO::DO::Payment - Payments authorization

=head1 SYNOPSIS

    my $apengine=XAO::Objects->new(objname => 'Payment',
                                   system => 'AuthorizeNet',
                                   merchant => 'testdriver');
    my $apinfo1=$apengine->run( ... );
    my $apinfo2=$apengine->run( ... );

=head1 DESCRIPTION

Authorizes credit cards using Authorize.net, 3DSI or other vendors.
Depends on CPAN modules: Bundle::LWP, Crypt::SSLeay.

=head1 METHODS

=over

=cut

###############################################################################
package XAO::DO::Payment;
use strict;
use CGI;
use Crypt::SSLeay 0.16;
use LWP::UserAgent 1.73;
use XAO::Utils qw(:debug :args :html);
use XAO::Objects;
use XAO::Projects;

use base XAO::Objects->load(objname => 'Atom');

use vars qw($VERSION);
($VERSION)=(q$Id: Payment.pm,v 1.1 2002/11/09 02:26:35 am Exp $ =~ /(\d+\.\d+)/);

###############################################################################

=item run (%)

Authorizing a single transaction.

Arguments are:

 system            must be either "AuthorizeNet" or "3DSI" currently
 type              one of [ auth_only, capture_only, auth_capture,
                   credit, void, prior_auth_capture ]. The default is
                   "auth_only".
 test              [ 1 | 0 ]
 merchant          merchant ID
 merchant_user     merchant user ID if different from merchant ID (optional)
 password          merchant password (optional)
 transact_id       unique transaction ID
 customer          customer ID
 invoice           invoice number (defaults to transact_id)
 method            authorization method (must be 'cc' or not defined)
 amount            transaction amount
 ccname            name on credit card
 ccnum             credir card number
 ccemonth          credit card expiration date
 cceyear           credit card expiration date
 bill_to_line1     billing address line1
 ccaddr1           billing address line1 (obsolete name)
 bill_to_line2     billing address line2
 ccaddr2           billing address line2 (obsolete name)
 bill_to_city      billing address city
 cccity            billing address city (obsolete name)
 bill_to_state     billing address state
 ccstate           billing address state (obsolete name)
 bill_to_country   billing address country
 cccountry         billing address country (obsolete name)
 bill_to_zipcode   billing address zip code
 cczipcode         billing address zip code (obsolete name)

For level 3 processing (only supported by 3DSI currently) the following
arguments may be used as well:

 freight_amount    Freight amount (shipping charge)
 tax_amount        Tax
 duty_amount       Duty
 ship_from_zipcode Shipped from zipcode
 ship_to_line1     Shipping address line1
 ship_to_line2     Shipping address line2
 ship_to_city      Shipping address city
 ship_to_state     Shipping address state
 ship_to_zipcode   Shipping address zipcode
 items             Array reference describing ordered items, see below.

Items array consists of several hash reference describing ordered
items. Each hash has must have the following records:

 quantity     Item quantity
 description  Item description
 amount       Item amount (price)
 unit         Item unit of measure
 partnum      Item part number (SKU)

Returns hash reference:

 error        0 | 1
 approved     0 | 1
 reason       text or error
 code         code of error
 refid        transaction reference id
 tcode        transaction code (long)
 avscode      address verification system code

=cut

sub run ($%) {
    my $self=shift;
    my $args=get_args(\@_);

    ##
    # Merging arguments given to us originally with the query
    #
    $args=merge_refs($self,$args);

    ##
    # Checking authorization system name
    #
    my $system=$args->{system};
    if($system eq 'authorize.net' || $system eq 'AuthorizeNet') {
        return $self->run_authorize_net($args);
    }
    elsif($system eq '3DSI') {
        return $self->run_3dsi($args);
    }
    else {
        throw $self "run - unknown payment system '$args->{system}'";
    }
}

###############################################################################

=item run_3dsi (%)

Processing via 3DSI (http://3dsi.com). Accepts the same arguments as the
generic run() method, but should not be called directly.

Supports Level 3 processing -- full details, including item descriptions
and shipping details.

=cut

sub run_3dsi ($%) {
    my $self=shift;
    my $args=get_args(\@_);

    my %params;

    my $type=lc($args->{type} || 'auth_only');
    if($type eq 'auth_only') {
        $params{AuthType}='A';
        $params{DbCr}='D';
    }
    elsif($type eq 'auth_capture') {
        $params{AuthType}='B';
        $params{DbCr}='D';
    }
    elsif($type eq 'capture_only') {
        $params{AuthType}='C';
        $params{DbCr}='D';
    }
    elsif($type eq 'credit') {
        $params{AuthType}='C';
        $params{DbCr}='C';
    }
    elsif($type eq 'void') {
        throw $self "run_3dsi - 'void' transactions are not supported";
    }
    elsif($type eq 'prior_auth_capture') {
        $params{AuthType}='F';
        $params{DbCr}='D';
    }
    else {
        throw $self "run_3dsi - unknown transaction type '$type'";
    }
        
    $params{MerchId}=$args->{merchant} ||
        throw $self "run_3dsi - no merchant ID";
    #$params{UserId}=$args->{merchant_user} || $args->{merchant};
    $params{Pwd}=$args->{password} if $args->{password};

    $params{TranNum}=$args->{transact_id} || $args->{invoice} ||
        throw $self "run_3dsi - 'transact_id' or 'invoice' must present";
    $params{InvoiceNo}=$args->{invoice} || '';
    $params{CustCode}=$args->{customer} if $args->{customer};

    $args->{amount} ||
        throw $self "run_3dsi - no transaction amount";
    $params{TotalAmt}=sprintf('%03u',$args->{amount}*100);

    $params{TaxAmt}=sprintf('%03u',$args->{tax_amount}*100)
        if $args->{tax_amount};
    $params{FreightAmt}=sprintf('%03u',$args->{freight_amount}*100)
        if $args->{freight_amount};
    $params{DutyAmt}=sprintf('%03u',$args->{duty_amount}*100)
        if $args->{duty_amount};

    my $cardnum=$args->{ccnum} ||
        throw $self "run_3dsi - no card number";
    $cardnum=~s/\D//g;
    $params{CreditCardNo}=$cardnum;
    $params{NameOnCard}=$args->{ccname} || '';
    $params{ExpireMM}=sprintf('%02u',$args->{ccemonth} || 0);
    $params{ExpireYY}=sprintf('%02u',$args->{cceyear} || 0);

    $params{ShipFrom}=$args->{ship_from_zipcode}
        if $args->{ship_from_zipcode};
    $params{ShipToStreet}=$args->{ship_to_line1} ||
                          $args->{bill_to_line1} ||
                          $args->{ccaddr1} || '';
    $params{ShipToZip}=$args->{ship_to_zipcode} ||
                          $args->{bill_to_zipcode} ||
                          $args->{cczipcode} || '';

    my $items=$args->{items} || [];
    $params{NumberOfItems}=scalar(@$items);
    for(my $i=0; $i<@$items; ) {
        my $item=$items->[$i++];
        $params{"ItemQty$i"}=$item->{quantity} || 0;
        $params{"ItemDesc$i"}=$item->{description} || 0;
        $params{"ItemAmt$i"}=sprintf("%03u",($item->{amount} || 0)*100);
        $params{"ItemUOM$i"}=$item->{unit} || 0;
        $params{"ItemPartNo$i"}=$item->{partnum} || 0;
    }

    # URL does not really matter, 3DSI will simply send it back to us as
    # a redirect with parameters.
    #
    $params{URL}=XAO::Projects::get_current_project->get('base_url') . 
                 '/3dsi/index.html';

    ##
    # Building query string
    #
    my $qs='';
    foreach my $key (keys %params) {
        next unless defined $params{$key};
        $qs.='&' if $qs;
        $qs.=t2hq($key) . '=' . t2hq($params{$key});
    }

    ##
    # Sending query
    #
    my $ua=LWP::UserAgent->new();
    $ua->agent("XAO/Payment-$VERSION");  
    my $req=HTTP::Request->new(POST => 'https://www.ec-zonedemo.com/secure/extern/ExternalAuth.asp');
    $req->content_type('application/x-www-form-urlencoded');
    $req->content($qs);
    my $res=$ua->request($req);

    ##
    # As the result 3DSI gives us a redirection request (302) with
    # information embedded into Location field.
    #
    if($res->code != 302) {
        return {
            error => 1,
            reason => "Wrong HTTP code in the answer, expected 302",
        };
    }
    my $str=$res->header('Location');
    $str=~s/^.*?\?(.*)$/$1/;
    if(!$str) {
        return {
            error => 1,
            reason => "Wrong response",
        };
    }

    my $vars=CGI->new($str)->Vars;
    exists $vars->{Status} && exists $vars->{ReturnCode} ||
        return {
            error => 1,
            reason => "Wrong response syntax",
        };

    my $status=$vars->{Status};
    my $return_code=$vars->{ReturnCode};

    my $error;
    my $approved;

    if(grep { $status eq $_ } qw(A V C F)) {
        $error=0;
        $approved=1;
    }
    elsif($status eq 'D' || $status eq 'E') {
        $error=0;
        $approved=0;
    }
    else {
        $error=1;
        $approved=0;
    }

    return merge_refs($vars, {
        error       => $error,
        approved    => $approved,
        code        => $return_code,
        reason      => $vars->{AuthMsg},
        refid       => $vars->{Pcode} || $vars->{PCode},
        avscode     => $vars->{AVS},
        tcode       => $vars->{OrgTranNum} || '',
    });
}

###############################################################################

=item run_authorize_net (%)

Processing via Authorize.net.  Accepts the same arguments as the generic
run() method, but should not be called directly.

=cut

sub run_authorize_net ($;%) {
    my $self=shift;
    my $args=get_args(\@_);

    ##
    # Checking and converting parameters
    #
    my %params;
    $params{x_Type}=uc($args->{type} || 'auth_only');
    $params{x_Method}=uc($args->{method} || 'cc');
    $params{x_Login}=$args->{merchant} ||
        throw $self "run_authorize_net - No merchant ID";
    $params{x_Password}=$args->{password};
    $params{x_Cust_ID}=$args->{customer};
    $params{x_Invoice_Num}=$args->{invoice} || $args->{transact_id};
    $params{x_Amount}=$args->{amount} ||
        throw $self "run_authorize_net - no transaction amount";
    $params{x_Card_Num}=$args->{ccnum} ||
        throw $self "run_authorize_net - no card number";
    $params{x_Card_Num}=~s/\D//g;
    $params{x_Exp_Date}=sprintf('%02u/%04u',$args->{ccemonth} || 0,$args->{cceyear} || 0);
    $params{x_Address}=$args->{bill_to_line1} || $args->{ccaddr1};
    $params{x_City}=$args->{bill_to_city} || $args->{cccity};
    $params{x_State}=$args->{bill_to_state} || $args->{ccstate};
    $params{x_Country}=$args->{bill_to_country} || $args->{cccountry};
    $params{x_Zip}=$args->{bill_to_zipcode} || $args->{cczipcode};
    ($params{x_First_Name},$params{x_Last_Name})=(($args->{ccname} || '') =~ /^(.*?)\s*(.*)$/);
    $params{x_Test_Request}=$args->{test} ? 'TRUE' : 'FALSE';

    ##
    # Standard parameters
    #
    $params{x_Version}='3.0';
    $params{x_ADC_Delim_Character}='|';
    $params{x_ADC_Delim_Data}='TRUE';
    $params{x_ADC_URL}='FALSE';

    ##
    # Building query string
    #
    my $qs;
    foreach my $key (keys %params) {
        next unless defined $params{$key};
        $qs.='&' if $qs;
        $qs.=t2hq($key) . '=' . t2hq($params{$key});
    }

    ##
    # Sending query
    #
    my $ua=LWP::UserAgent->new();
    $ua->agent("XAO/AuthPayment-$VERSION");  
    my $req=HTTP::Request->new(POST => 'https://secure.authorize.net/gateway/transact.dll');
    $req->content_type('application/x-www-form-urlencoded');
    $req->content($qs);
    my $res=$ua->request($req);

    ##
    # Analyzing results
    #
    if (! $res->is_success) {
        return {
            error => 1,
            reason => 'connection error'
        };
    }

    ##
    # Parsing results. Authorize.net does not escape delimiters in their
    # strings. So we just hope that there would be no '|' inside strings.
    #
    my @answer=split(/\|/,$res->content);
    my $error;
    my $approved;
    if($answer[0] !~ /^\d+$/) {
        ##
        # Some sort of major problem -- we got a text message instead of
        # normal encoded string.
        #
        return {
            error => 1,
            reason => $res->content,
        };
    }
    elsif($answer[0] == 1) {
        $error = 0;
        $approved = 1;
    }
    elsif($answer[0] == 2) {
        $error = 0;
        $approved = 0;
    }
    elsif($answer[0] == 3) {
        $error = 1;
        $approved = 0;
    }

    return {
        error       => $error,
        approved    => $approved,
        code        => $answer[2],
        reason      => $answer[3],
        refid       => $answer[4],
        avscode     => $answer[5],
        tcode       => $answer[37],
    };
}

###############################################################################
1;
