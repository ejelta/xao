=head1 NAME

XAO::DO::Web::PodView::Parser - POD parser for XAO::DO::Web::PodView

=head1 SYNOPSIS

Should not be called directly, see XAO::DO::Web::PodView usage
synopsis.

=head1 DESCRIPTION

Extends Pod::Parser class to allow Pod parsing for
XAO::DO::Web::PodView.

=head1 EXPORTS

Nothing.

=head1 AUTHOR

Copyright (c) 2001 XAO Inc.

Andrew Maltsev <am@xao.com>.

=head1 SEE ALSO

Recommended reading:
L<XAO::Web>,
L<XAO::DO::Web::PodView>.

=cut

###############################################################################
package XAO::DO::Web::PodView::Parser;
use strict;
use XAO::Utils qw(:args :html :debug);
use base qw(Pod::Parser);

use vars qw($VERSION);
($VERSION)=(q$Id: Parser.pm,v 1.6 2002/01/04 03:21:04 am Exp $ =~ /(\d+\.\d+)/);

##
# List of entities from Pod::Checker. I wonder who originally wrote that
# code? It seems that everyone "borrows" it from some place else :)
#
my %ENTITIES = (
 # Some normal chars that have special meaning in SGML context
 amp    => '&',  # ampersand 
'gt'    => '>',  # greater than
'lt'    => '<',  # less than
 quot   => '"',  # double quote

 # PUBLIC ISO 8879-1986//ENTITIES Added Latin 1//EN//HTML
 AElig	=> 'Æ',  # capital AE diphthong (ligature)
 Aacute	=> 'Á',  # capital A, acute accent
 Acirc	=> 'Â',  # capital A, circumflex accent
 Agrave	=> 'À',  # capital A, grave accent
 Aring	=> 'Å',  # capital A, ring
 Atilde	=> 'Ã',  # capital A, tilde
 Auml	=> 'Ä',  # capital A, dieresis or umlaut mark
 Ccedil	=> 'Ç',  # capital C, cedilla
 ETH	=> 'Ð',  # capital Eth, Icelandic
 Eacute	=> 'É',  # capital E, acute accent
 Ecirc	=> 'Ê',  # capital E, circumflex accent
 Egrave	=> 'È',  # capital E, grave accent
 Euml	=> 'Ë',  # capital E, dieresis or umlaut mark
 Iacute	=> 'Í',  # capital I, acute accent
 Icirc	=> 'Î',  # capital I, circumflex accent
 Igrave	=> 'Ì',  # capital I, grave accent
 Iuml	=> 'Ï',  # capital I, dieresis or umlaut mark
 Ntilde	=> 'Ñ',  # capital N, tilde
 Oacute	=> 'Ó',  # capital O, acute accent
 Ocirc	=> 'Ô',  # capital O, circumflex accent
 Ograve	=> 'Ò',  # capital O, grave accent
 Oslash	=> 'Ø',  # capital O, slash
 Otilde	=> 'Õ',  # capital O, tilde
 Ouml	=> 'Ö',  # capital O, dieresis or umlaut mark
 THORN	=> 'Þ',  # capital THORN, Icelandic
 Uacute	=> 'Ú',  # capital U, acute accent
 Ucirc	=> 'Û',  # capital U, circumflex accent
 Ugrave	=> 'Ù',  # capital U, grave accent
 Uuml	=> 'Ü',  # capital U, dieresis or umlaut mark
 Yacute	=> 'Ý',  # capital Y, acute accent
 aacute	=> 'á',  # small a, acute accent
 acirc	=> 'â',  # small a, circumflex accent
 aelig	=> 'æ',  # small ae diphthong (ligature)
 agrave	=> 'à',  # small a, grave accent
 aring	=> 'å',  # small a, ring
 atilde	=> 'ã',  # small a, tilde
 auml	=> 'ä',  # small a, dieresis or umlaut mark
 ccedil	=> 'ç',  # small c, cedilla
 eacute	=> 'é',  # small e, acute accent
 ecirc	=> 'ê',  # small e, circumflex accent
 egrave	=> 'è',  # small e, grave accent
 eth	=> 'ð',  # small eth, Icelandic
 euml	=> 'ë',  # small e, dieresis or umlaut mark
 iacute	=> 'í',  # small i, acute accent
 icirc	=> 'î',  # small i, circumflex accent
 igrave	=> 'ì',  # small i, grave accent
 iuml	=> 'ï',  # small i, dieresis or umlaut mark
 ntilde	=> 'ñ',  # small n, tilde
 oacute	=> 'ó',  # small o, acute accent
 ocirc	=> 'ô',  # small o, circumflex accent
 ograve	=> 'ò',  # small o, grave accent
 oslash	=> 'ø',  # small o, slash
 otilde	=> 'õ',  # small o, tilde
 ouml	=> 'ö',  # small o, dieresis or umlaut mark
 szlig	=> 'ß',  # small sharp s, German (sz ligature)
 thorn	=> 'þ',  # small thorn, Icelandic
 uacute	=> 'ú',  # small u, acute accent
 ucirc	=> 'û',  # small u, circumflex accent
 ugrave	=> 'ù',  # small u, grave accent
 uuml	=> 'ü',  # small u, dieresis or umlaut mark
 yacute	=> 'ý',  # small y, acute accent
 yuml	=> 'ÿ',  # small y, dieresis or umlaut mark

 # Some extra Latin 1 chars that are listed in the HTML3.2 draft (21-May-96)
 copy   => '©',  # copyright sign
 reg    => '®',  # registered sign
 nbsp   => "\240", # non breaking space

 # Additional ISO-8859/1 entities listed in rfc1866 (section 14)
 iexcl  => '¡',
 cent   => '¢',
 pound  => '£',
 curren => '¤',
 yen    => '¥',
 brvbar => '¦',
 sect   => '§',
 uml    => '¨',
 ordf   => 'ª',
 laquo  => '«',
'not'   => '¬',    # not is a keyword in perl
 shy    => '­',
 macr   => '¯',
 deg    => '°',
 plusmn => '±',
 sup1   => '¹',
 sup2   => '²',
 sup3   => '³',
 acute  => '´',
 micro  => 'µ',
 para   => '¶',
 middot => '·',
 cedil  => '¸',
 ordm   => 'º',
 raquo  => '»',
 frac14 => '¼',
 frac12 => '½',
 frac34 => '¾',
 iquest => '¿',
'times' => '×',    # times is a keyword in perl
 divide => '÷',

# some POD special entities
 verbar => '|',
 sol => '/'
);

sub new ($%) {
    my $proto=shift;
    my $args=get_args(\@_);

    my $self=$proto->SUPER::new();

    $self->{'-dispobj'}=$args->{dispobj} ||
        $self->throw("new - no 'dispobj' argument given");
    $self->{'-format'}=lc($args->{format} || 'html');

    $self;
}

sub display ($%) {
    my $self=shift;
    $self->{'-dispobj'}->display(@_);
}

sub expand ($%) {
    my $self=shift;
    $self->{'-dispobj'}->expand(@_);
}

sub paragraph_text ($$) {
    my $self=shift;
    my $text=shift;
    $text;
}

sub interpolate ($$$) {
    my $self=shift;
    my ($text,$line_num)=@_;
    my $ptree=$self->parse_text( { -expand_seq => 'interior_sequence',
                                   -expand_text => 'html_encode'
                                 },
                                 $text,$line_num);
    return join('',$ptree->children());
}

sub html_encode ($$$) {
    my $self=shift;
    my $text=shift;
    #dprint "html_encode: $text";
    $text=t2ht($text);
    $text=~s/(\s+)(\(c\))([\s[:punct:]]+)/$1&copy;$3/ig;
    $text=~s/(\s+)(\(r\))([\s[:punct:]]+)/$1&reg;$3/ig;
    $text;
}

##
# Returns path to the template file
#
sub path ($$) {
    my $self=shift;
    my $format=$self->{-format};
    my $name=shift;
    "/bits/podview/$format/$name";
}

sub command ($$$$) {
    my $self=shift;
    my ($command, $paragraph, $line_num) = @_;
    $self->verbatim_stop($line_num);
    $self->textblock_stop($line_num);
    #dprint "command: command=$command paragraph=$paragraph line_num=$line_num";

    $paragraph=$self->strip_spaces($paragraph);

    ##
    # Some special processing. Getting out of all levels of =over on
    # =head1 and =head2; calculating level of =over.
    #
    # On =over we do not print anything and wait until we get first
    # =item in that scope. Then we decide if it is an enumerated list or
    # not.
    #
    if($command eq 'over') {
        $self->{-had_item}=($self->{-over_level} || 0)+1;
        return;
    }
    elsif($command eq 'back') {
        $self->{-over_level}--;
        $self->{-had_item}--;
        my $style=pop(@{$self->{-over_type}});
        $command.="-$style";
    }
    elsif($command eq 'item') {

        ##
        # For =item on top level without previous =over, which is
        # illegal, but could happen out of ignorance.
        #
        if(! $self->{-had_item}) {
            $self->{-had_item}=1;
        }

        if(($self->{-had_item} || 0) != ($self->{-over_level} || 0)) {
            $self->{-over_level}++;

            ##
            # What is the type of our list? We support bullets, enums
            # and item/definition lists.
            #
            my $style;
            if($paragraph eq '1') {
                $style='number';
            }
            elsif($paragraph =~ /^\W$/) {
                $style='bullet';
            }
            else {
                $style='text';
            }
            $self->{-over_type}->[$self->{-over_level}-1]=$style;

            $command.="-$style";

            $self->display(
                path => $self->path("command-over-$style"),
                COMMAND => 'over',
                LINENUM => $line_num,
                OVERLEVEL => $self->{-over_level},
                TEXT => $self->paragraph_text($self->interpolate($paragraph,$line_num)),
                UNPARSED => $paragraph,
            );
        }
        else {
            my $style=$self->{-over_type}->[$self->{-over_level}-1];
            $command="item-$style";
        }
    }
    elsif($command eq 'head1' || $command eq 'head2') {
        while($self->{-over_level}) {
            $self->command('back',$paragraph,$line_num);
        }
    }
    elsif($command eq 'cut' || $command eq '=pod') {
        return;
    }
    elsif($command eq 'for') {
        my $format=$self->{-format};
        return unless $paragraph =~ /^\s*($format)\s+(.*)$/;
        $paragraph=$2;
    }
    elsif($command eq 'begin') {
        return unless $paragraph =~ /^\s*(.*?)(\s+(.*))?$/;
        push @{$self->{-begin_stack}},$1;
    }
    elsif($command eq 'end') {
        return unless $paragraph =~ /^\s*(.*?)(\s+(.*))?$/;
        my $f=$1;
        if(!@{$self->{-begin_stack}}) {
            eprint ref($self)."::command - no '=begin' for '=end $f' at line $line_num";
            return;
        }
        if($self->is_in_format($f)) {
            eprint ref($self)."::command - unmatched format '=end $f' at line $line_num";
        }
        pop @{$self->{-begin_stack}};
        return;
    }
    else {
        $self->display(
            path => $self->path("command-unknown"),
            TEXT => $self->paragraph_text($self->interpolate($paragraph,$line_num)),
            COMMAND => $command,
            LINENUM => $line_num,
            UNPARSED => $paragraph,
        );
        return;
    }

    ##
    # Displaying paragraph in the appropriate command template if we got
    # here.
    #
    my $ptext=$self->paragraph_text($self->interpolate($paragraph,$line_num));
    $self->display(
        path        => $self->path("command-$command"),
        COMMAND     => $command,
        LINENUM     => $line_num,
        TEXT        => $ptext,
        UNPARSED    => $paragraph,
    );
}

sub verbatim ($$$) {
    my $self=shift;
    my ($paragraph, $line_num) = @_;
    return undef if !$self->{-verbatim_mode} && $paragraph =~ /^[\s\r\n]$/;
    $self->textblock_stop($line_num);
    #dprint "verbatim: paragraph=$paragraph line_num=$line_num";
    if(! $self->{-verbatim_mode}) {
        $self->display(
            path => $self->path("verbatim-start"),
            TEXT => '',
            LINENUM => $line_num,
            UNPARSED => '',
        );
        $self->{-verbatim_mode}=1;
    }
    else {
        $self->display(
            path => $self->path("verbatim-text"),
            TEXT => "\n",
            LINENUM => $line_num,
            UNPARSED => "\n",
        );
    }

    chomp($paragraph);
    $self->display(
        path => $self->path("verbatim-text"),
        TEXT => $self->paragraph_text($paragraph),
        LINENUM => $line_num,
        UNPARSED => $paragraph,
    );
}

sub verbatim_stop ($$) {
    my $self=shift;
    if($self->{-verbatim_mode}) {
        $self->display(
            path => $self->path('verbatim-stop'),
            TEXT => '',
            LINENUM => $_[0] || 0,
            UNPARSED => ''
        );
        $self->{-verbatim_mode}=0;
    }
}

sub textblock ($$$) {
    my $self=shift;
    my ($paragraph, $line_num) = @_;

    return undef if $paragraph =~ /^[\s\r\n]$/;

    $paragraph=$self->strip_spaces($paragraph);

    $self->verbatim_stop($line_num);
    if(! $self->{-textblock_mode}) {
        $self->display(path => $self->path('textblock-start'),
                       TEXT => '',
                       LINENUM => $line_num,
                       UNPARSED => ''
                      );
        $self->{-textblock_mode}=1;
    }

    $self->display(path => $self->path('textblock-text'),
                   TEXT => $self->paragraph_text($self->interpolate($paragraph,$line_num)),
                   LINENUM => $line_num,
                   UNPARSED => $paragraph
                  );
}

sub textblock_stop ($$)
{ my $self=shift;
  if($self->{-textblock_mode})
   { $self->display(path => $self->path('textblock-stop'),
                    TEXT => '',
                    LINENUM => $_[0] || 0,
                    UNPARSED => ''
                   );
     $self->{-textblock_mode}=0;
   }
}

##
# Does not display what it gets, but returns it instead! Pay attention
# to not add any code at the end as it uses "last value is returned"
# style..
#
sub interior_sequence ($$$)
{ my $self=shift;
  my ($command,$text)=@_;
  #dprint "iseq: command=$command, text=$text";
  if($command eq 'I')
   { $self->expand(path => $self->path('embed-italic'),
                   COMMAND => $command,
                   TEXT => $text
                  );
   }
  elsif($command eq 'B')
   { $self->expand(path => $self->path('embed-bold'),
                   COMMAND => $command,
                   TEXT => $text
                  );
   }
  elsif($command eq 'S')
   { $self->expand(path => $self->path('embed-nbsp'),
                   COMMAND => $command,
                   TEXT => $text
                  );
   }
  elsif($command eq 'C')
   { $self->expand(path => $self->path('embed-code'),
                   COMMAND => $command,
                   TEXT => $text
                  );
   }
  elsif($command eq 'F')
   { $self->expand(path => $self->path('embed-file'),
                   COMMAND => $command,
                   TEXT => $text
                  );
   }
  elsif($command eq 'X')
   { $self->expand(path => $self->path('embed-index'),
                   COMMAND => $command,
                   TEXT => $text
                  );
   }
  elsif($command eq 'Z')
   { $self->expand(path => $self->path('embed-zero'),
                   COMMAND => $command,
                   TEXT => $text
                  );
   }
  elsif($command eq 'L')
   { if($text =~ /^((.*)\|)?((http|ftp|news):\/\/.*)$/)
      { my $url=$3;
        my $comment=$2 || $url;
        $self->expand(path => $self->path('embed-link-url'),
                      COMMAND => $command,
                      TEXT => $comment,
                      URL => $url
                     );
      }
     else
      { $text =~ /^((.*?)\|)?(.*?)(\/(.*))?$/;
        my $manpage=$3;
        my $section=$5 || '';
        my $comment=$2 || "the $manpage manpage";
        return $comment unless $manpage;
        if($self->find_module_file($manpage))
         { $self->expand(path => $self->path('embed-link-pod'),
                         COMMAND => $command,
                         TEXT => $comment || '',
                         MODULE => $manpage,
                         SECTION => $section || ''
                        );
         }
        else
         { $self->expand(path => $self->path('embed-link-man'),
                         COMMAND => $command,
                         TEXT => $comment || '',
                         MANPAGE => $manpage,
                         SECTION => $section || ''
                        );
         }
      }
   }
  elsif($command eq 'E')
   { $self->expand(path => $self->path('embed-escape'),
                   COMMAND => $command,
                   TEXT => defined($ENTITIES{$text}) ? $ENTITIES{$text} : $text,
                   ESCAPE => $text
                  );
   }
  else
   { $self->expand(path => $self->path('embed-unknown'),
                   COMMAND => $command,
                   TEXT => $text
                  );
   }
}

##
# Looks through the @INC in search of the module file return the full
# name or undef.
#
# Static method, does not get reference to $self!
#
my %module_cache;
sub find_module_file ($$) {
    my $self=shift;
    my $module=shift;
    my $file=$INC{$module} || $module_cache{$module};
    return $file if $file;
    my $mp=$module;
    $mp=~s/::/\//g;
    $mp=~s/\s//g;
    foreach my $dir (@INC) {
        if(-r "$dir/${mp}.pod") {
            $file="$dir/${mp}.pod";
            last;
        }
        elsif(-r "$dir/${mp}.pm") {
            $file="$dir/${mp}.pm";
            last;
        }
    }
    $file || undef;
}

##
# Strips all spaces from both sides of the string.
#
sub strip_spaces ($$) {
    my $self=shift;
    my $text=shift;
    return undef unless defined $text;
    $text=~s/^\s*(.*?)\s*$/$1/;
    $text;
}

###############################################################################
1;
