package XAO::DO::Web::PayMethod;
use XAO::Utils;
use XAO::Errors qw(XAO::DO::Web::PayMethod);

use base XAO::Objects->load(objname => 'Web::FS');

###############################################################################
sub check_mode ($%) {
    my $self=shift;
    my $args=get_args(\@_);
    $self->SUPER::check_mode($args);
}
###############################################################################
sub edit_object ($%) {
    my $self=shift;
    my $args=get_args(\@_);

    my $list=$self->get_object($args);

    my @fields=@{$self->form_fields};
    my @fnames=map { $_->{name} } @fields;

    ##
    # If we have ID then we're editing this pm otherwise we're
    # creating a new one.
    #
    my $id=$args->{id};
    my %values;
    if($id) {
        my $pm=$list->get($id);
        @values{@fnames}=$pm->get(@fnames);
    }

    my $form=$self->object(objname => 'Web::FilloutForm');
    $form->setup(
        fields => \@fields,
        values => \%values,
        submit_name => $id ? 'done' : undef,
        check_form => sub {
                          my $form=shift;

                          ##
                          # Checking uniqueness of Reference Name
                          #
                          my $ref_name=$form->field_desc('ref_name')->{value};
                          my $sr=$list->search('ref_name', 'eq', $ref_name);
                          if(($id && @$sr>1) || (!$id && @$sr)) {
                              return 'Payment method with this reference name already exists';
                          }

                          ##
                          # Checking credit card number if this is a credit card.
                          #
                          my $method=$form->field_desc('method')->{value};
                          my $number=$form->field_desc('number')->{value};
                          if($method ne 'Credit') {
                              my $errstr=$form->cc_validate(
                                                    number => $number,
                                                    type   => $method,
                                                );
                              if($errstr) {
                                  return $form->field_desc('number')->{text} .
                                         ' ' .
                                         $errstr;
                              }
                          }
                          return '';
                      },
        form_ok => sub {
                       my $form=shift;
                       my $pm=$list->get_new();
                       foreach my $name (map { $_->{name} } @fields) {
                           my $value=$form->field_desc($name)->{value};
                           $value=substr($value,0,2) if $name eq 'state';
                           $pm->put($name => $value);
                       }
                       if($id) { $list->put($id => $pm); }
                       else       { $list->put($pm); }
                       $self->object->display(path => $args->{'success.path'});
                   },
    );

    $form->display('form.path' => $args->{'form.path'});
}
###############################################################################
sub form_fields {
    my $self=shift;
    return [
        {   name => 'ref_name',
            required => 1,
            unique => 1,
            style => 'text',
            maxlength => 50,
            minlength => 3,
            param => 'REF_NAME',
            text => 'Reference Name',
        },
        {   name        => 'method',
            required    => 1,
            style       => 'selection',
            options     => {
                'Visa'              => 'VISA',
                'American Express'  => 'American Express',
                'MasterCard'        => 'MasterCard',
                'Discover'          => 'Discover',
            },
            param       => 'METHOD',
            text        => 'Payment Method',
        },
        {   name        => 'number',
            required    => 1,
            style       => 'text',
            minlength   => 1,
            maxlength   => 16,
            param       => 'NUMBER',
            text        => 'Pay Number',
            encrypt     => 1,
        },
        {   name        => 'expire_month',
            required    => 1,
            style       => 'month',
            param       => 'EXPIRE_MONTH',
            text        => 'Expiration Month',
            encrypt     => 1,
        },
        {   name        => 'expire_year',
            required    => 1,
            style       => 'year',
            minyear     => 2001,
            maxyear     => 2011,
            param       => 'EXPIRE_YEAR',
            text        => 'Expiration Year',
            encrypt     => 1,
        },
        {   name        => 'name',
            required    => 1,
            style       => 'text',
            maxlength   => 50,
            minlength   => 3,
            param       => 'NAME',
            text        => 'Name',
        },
        {   name => 'line_1',
            required => 1,
            style => 'text',
            maxlength => 100,
            minlength => 5,
            param => 'LINE_1',
            text => 'Address (line 1)',
        },
        {   name => 'line_2',
            style => 'text',
            maxlength => 100,
            param => 'LINE_2',
            text => 'Address (line 2)',
        },
        {   name => 'city',
            required => 1,
            style => 'text',
            maxlength => 50,
            minlength => 2,
            param => 'CITY',
            text => 'City',
        },
        {   name => 'state',
            required => 1,
            style => 'uscontst',
            param => 'STATE',
            text => 'State',
        },
        {   name => 'zipcode',
            required => 1,
            style => 'text',
            maxlength => 20,
            minlength => 5,
            param => 'ZIPCODE',
            text => 'Zip-Code',
        },
        {   name => 'phone',
            style => 'usphone',
            param => 'PHONE',
            text => 'Phone',
        },
    ];
}
###############################################################################
1;
