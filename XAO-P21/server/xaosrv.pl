#!/usr/bin/perl -w

use lib qw(/home/amaltsev/j /home/amaltsev/src/perl/lib/site_perl/5.005 /home/amaltsev/src/perl/lib/5.00503);

use vars qw($VERSION $REVISION);

use IO::Socket::INET;
use Errno qw/EINTR EAGAIN/;
use POSIX qw(:sys_wait_h setsid);

$VERSION='0.05';
$REVISION='$Id: xaosrv.pl,v 1.1 2002/03/06 02:40:10 am Exp $';

my $spooldir='/tmp/p21ec';

my $ServerName='xaotst';
$0 = $ServerName;

my $Debug = $ENV{DEBUG};
print "Debugging\n" if $Debug;
sub debug {
    print $_[0] if $Debug;
}

### <Hack>
$ENV{TERM}='ansi' unless $ENV{TERM};
### </Hack>

sub open_stream {
    local *IN;
    my $script=shift;
    open IN, qq(/usr/lpp/p21pro/bin/p21pro -d /usr/lpp/p21pro/src:/usr/lpp/p21pro/src/include -p "-p /home/amaltsev/current/$script.p -b"|) or die $!; # XXX FIXME
    *IN;  
}

sub open_query {
    local *IN;
    $ENV{'PROCNAME'}=shift;
    my $envn=0; 
    foreach (@_) {
        $ENV{"P$envn"}=$_;
        ++$envn;
    }
    $ENV{ORIGIN}='P21';
    open IN, qq(/usr/lpp/p21pro/bin/p21pro -S 0 -P p21/www/query/www.p -p -b|)
      or die $!; # XXX FIXME
    *IN;  
}

sub reopen_log {
    close STDERR;
    open STDERR, ">/tmp/$ServerName.log";
    select STDERR;
    $|=1;
}

######### Daemonizing
chdir '/';
close STDIN;
open STDIN, "</dev/null" or die "$!";
close STDOUT;
open STDOUT, ">/dev/null" or die "$!";
reopen_log;
my $pid=fork;
die "$!" unless defined $pid;
exit if $pid;
POSIX::setsid;
$pid=fork;
die "$!" unless defined $pid;
if($pid) {
    open STDERR, ">/tmp/$ServerName.pid" or die $!;
    print STDERR "$pid\n";
    close STDERR;
    exit;
}
reopen_log;
############

sub chld_handler {
    while((my $rc=waitpid(-1,&WNOHANG)) > 0) {
	print STDERR "Child exited ($rc/$?)\n";
    }
    $SIG{CHLD}=\&chld_handler;
}
$SIG{CHLD}=\&chld_handler;

$SIG{HUP}=\&reopen_log;

my $server = IO::Socket::INET->new( Proto => 'tcp',
                                    Listen => 10,
                                    LocalPort => 9010,
                                    Reuse => 1,
                                    LocalAddr => '127.0.0.1'
                                  );
die "Cannot create server: $!" unless $server;

my $socket;

while(1) {
    $socket=$server->accept;

    unless(defined $socket) {
        next if $!{EINTR} || $!{EAGAIN};
        print STDERR "$!\n";
        sleep 5;
        next;
    }

    my $flag = 0;
    local $SIG{PIPE} = sub { $flag = 1 };

    sub printsock {
        print $socket @_;
        die $! if $flag;
        print STDERR @_ if $Debug;
    };

    print STDERR "accepted \n";
    $pid=fork;
    unless (defined $pid) {
        print STDERR "$!\n";
        sleep 10;
        next;
    }

    if($pid) {
        $socket->close;
        next;
    }

    $socket->autoflush(1);

    my $answer = sub {
        my $in = open_query @_;
        while(<$in>) {
            next if /^(OK)*\s*$/;
            s/\t/ /g; s/\001/\t/g;
            printsock $_;
        }
    };
    
    while(<$socket>) {
        chomp;
        my ($opcode, @args) = split /\t/;
        next unless $opcode;
        $0 = "$ServerName $opcode";

=head1 items

Returns full items list from "item" table; items delimited with '\n', and each record contains:
item code, package size, sales unit, sku, list price, alternate unit name or "?",
alternate unit size or "?", description string 1, description string 2. All the fields delimited with "\t".

=cut  

        if($opcode eq "items") {
            my $in = open_stream "items";
            while(<$in>) {
                printsock $_;
            }

=head1 avail

Returns availability info for each of given item code. The info contains lines with non-zero quantities only.  

=cut  

        } elsif ($opcode eq "avail") {
            foreach my $code (@args) {
                my $in = open_query 'stk_item', '?', $code;
                while(<$in>) {
                    next if /^(OK)*\s*$/;
                    s/\t/ /g; s/\001/\t/g;
                    my ($location, $stock, @rest) = split /\t/;
                    printsock "$code\t$_" if ($stock);
                }
            }

=head1 catalog

Returns full catalog items list. See "items" for data layout and attributes order.

=cut  

        } elsif ($opcode eq "catalog") {
            my $in = open_stream "catalog";
            while(<$in>) {
                printsock $_;
            }

=head1 custinfo

Returns info about customers.  

=cut  

        } elsif ($opcode eq "custinfo") {
            if(@args) {
                foreach (@args) {
                    $ENV{"P0"} = $_;
                    my $in = open_stream 'custinfo1';
                    while(<$in>) {
                        s/\t/ /g; s/\001/\t/g;
                        printsock "$_";
                    }
                }
            } else {
                my $in=open_stream 'custinfo';
                while(<$in>) {
                    next if /^(OK)*\s*$/;
                    s/\t/ /g; s/\001/\t/g;
                    printsock "$_";
                }
            }

=head1 order

Placing order into spool. Input data is:

=cut  

        } elsif ($opcode eq "order_entry") {
            # XXX unique filename?
            # my $basename = "xao" . substr(time, -6) . $counter++ ;
            my $basename = $args[0];
            my $fname = "$spooldir/$basename.proc";
            eval {
                open(PROC_OUT,">>$fname~") or die "$!";
                while( @args > 0 ) {
                    my (@line, @rest);
                    ( @line[0..19], @rest ) = @args ;
                    $line[19]="" unless $line[19];
                    print PROC_OUT '"', join('","', @line), qq(",\n) ;
                    @args = @rest;
                }
                close(PROC_OUT) or die "$!";
                rename("$fname~", $fname) or die "$!";
            };
            if($@) {
                printsock "1\t$@\n";
                # unlink "$fname~" unless you_want_to_check_later;
            } else {
                printsock "0\t$basename\n";
            }

=head1 list_all_open_orders
 
=cut

        } elsif ($opcode eq "list_all_open_orders") {
            $answer->('ord_cust', $args[0]);
            
=head1 view_open_order_details

=cut

        } elsif ($opcode eq "view_open_order_details") {
            $answer->('ord_item', @args);
            
=head1 list_all_invoices

=cut

        } elsif ($opcode eq "list_all_invoices") {
            $answer->('ir_cust', $args[0]);

=head1 invoice_recall BROKEN

=cut

        } elsif ($opcode eq "invoice_recall") {
            my ($customer, $order, $shipment) = @args ;
            $ENV{PROCNAME} = 'ir_inv';
            $ENV{ORIGIN} = 'P21';
            $ENV{P0} = $customer;
            $ENV{P1} = $order;
            $ENV{P2} = $shipment;
            my $open = "/usr/lpp/p21/bin/pqlalog -s 0 -r \"invrecall_xr(" . int($order) . "," . int($shipment) . ").invoice\"|/usr/lpp/p21/bin/despool|";
            open (IN, $open) or die "$!";
            while(<IN>) {
                printsock $_;
            }
            printsock "\n";
            close IN;
            
=head1 list_open_ar

=cut

        } elsif ($opcode eq "list_open_ar") {
            $answer->('ar_cust', $args[0]);
            
=head1 price

Asks for price. Input data is: customer code or "?", item code, quantity.
Output: price for one unit, multiplier.

=cut  

        } elsif ($opcode eq "price") {
            $ENV{P0} = $args[0] eq '?' ? "" : $args[0];
            $ENV{P1} = $args[1];
            $ENV{P2} = 1;   #   XXX
            $ENV{P3} = 1;   #   XXX
            $ENV{P4} = $args[2];
            my $in = open_stream "price";
            my $line = <$in>;
            printsock $line;

=head1 find_match

=cut

        } elsif ($opcode eq 'find_match') {
            opendir DH, "$spooldir" or die "$!";
#my %files =
#              map { /([A-Za-z_]+)\.[^.]+\.(\d+)/ && ( $1 => [ $_, $2 ] ) } readdir DH;
            my %files ;
            foreach (readdir DH) {
                if (/([A-Za-z0-9_]+)\.[^.]+\.(\d+)/) {
                    $files{$1}=[$_, $2 ];
                }
            }
            closedir DH;
            foreach (@args) {
                printsock "$_\t$files{$_}->[0]\t$files{$_}->[1]\n" if defined $files{$_};
            }

=head1 show_spool

=cut

        } elsif ($opcode eq 'show_spool') {
            opendir DH, "$spooldir" or die $!;
            foreach (readdir DH) {
                printsock "$_\n" unless /^\./;
            }
            closedir DH;

=head1 cleanup_spool

=cut

        } elsif ($opcode eq 'cleanup_spool') {
            unlink("$spooldir/$_") || $!{ENOENT} || die "$!" foreach (@args);

=head1 mod_custinfo

=cut

        } elsif ($opcode eq 'mod_custinfo') {
            foreach (0..12) {
                print STDERR "export P$_=\'$args[$_]\'\n";
                $ENV{"P$_"} = $args[$_];
            }
            system q(/usr/lpp/p21pro/bin/p21pro -d /usr/lpp/p21pro/src:/usr/lpp/p21pro/src/include -p "-p /home/amaltsev/current/modcust.p -b" >/dev/null) or die $!; # XXX FIXME

=head1 undefined command

=cut  

        } else {
            printsock "undefined command\n";
        }
    printsock ".\n";
    }
    $socket->close;
    exit;
}

__END__
