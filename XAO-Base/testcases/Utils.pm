package testcases::Utils;
use strict;

use base qw(testcases::base);

sub test_html {
    my $self=shift;

    use XAO::Utils qw(:html);

    my $str;
    my $got;
    $str='\'"!@#$%^&*()_-=[]\<>?';
    $got=t2ht($str);
    $self->assert($got eq '\'"!@#$%^&amp;*()_-=[]\&lt;&gt;?',
                  "Wrong value from t2ht ($got)");

    $got=t2hq($str);
    $self->assert($got eq '\'%22!@%23$%25^%26*()_-%3d[]\%3c%3e%3f',
                  "Wrong value from t2hq ($got)");

    $got=t2hf($str);
    $self->assert($got eq '\'&quot;!@#$%^&amp;*()_-=[]\&lt;&gt;?',
                  "Wrong value from t2hf ($got)");
}

sub test_args {
    my $self=shift;

    use XAO::Utils qw(:args);

    my $args;

    $args=get_args(a => 1, b => 2);
    $self->assert($args->{a} == 1 && $args->{b} == 2,
                  "get_args - can't parse a hash");

    $args=get_args([a => 2, b => 3]);
    $self->assert($args->{a} == 2 && $args->{b} == 3,
                  "get_args - can't parse an 'arrayed' hash");

    $args=get_args({a => 3, b => 4});
    $self->assert($args->{a} == 3 && $args->{b} == 4,
                  "get_args - can't parse a hash reference");

    my %a=(aa => 1, bb => '');
    my %b=(bb => 2, cc => undef);
    my %c=(cc => 3, dd => 3);
    my $r=merge_refs(\%a,\%b,\%c);
    $self->assert($a{aa} == 1 && $a{bb} eq '' &&
                  $b{bb} == 2 && !defined($b{cc}) &&
                  $c{cc} == 3 && $c{dd} == 3 &&
                  $r->{aa} == 1 && $r->{bb} == 2 &&
                  $r->{cc} == 3 && $r->{dd} == 3 &&
                  scalar(keys %$r) == 4,
                  "merge_refs doesn't work right");
}

sub test_keys {
    my $self=shift;

    use XAO::Utils qw(:keys);

    for(1..1000) {
        my $key=generate_key();
        $self->assert($key && $key =~ /^[0-9A-Z]{8}/,
                      "Wrong key generated ($key)");
    }

    my $key=repair_key('01V34567');
    $self->assert($key eq 'OIU3456I',
                  "repair_key returned wrong value for 01V34567 ($key)");
}

1;
