package AIR2::HTML;
use strict;
use warnings;
use HTML::Parser;
use Carp;

sub clean {
    my $buf = pop;
    return '' unless defined $buf;

    # remove style attributes and anything else that affects display.
    my $cleaned = '';
    my $parser  = new_cleaning_parser( \$cleaned );
    $parser->parse($buf) or return $buf;
    return sprintf( '<div class="pin-cleaned">%s</div>', $cleaned );
}

# c.f. https://metacpan.org/source/GAAS/HTML-Parser-3.71/eg/hstrip
my @ignore_attr = qw(
    onblur onchange onclick ondblclick onfocus onkeydown onkeyup onload
    onmousedown onmousemove onmouseout onmouseover onmouseup
    onreset onselect onunload
);
my @ignore_tags     = qw();
my @ignore_elements = qw();

# make it easier to look up attributes
my %ignore_attr = map { $_ => 1 } @ignore_attr;

sub new_cleaning_parser {
    my $bufref = pop or confess "string reference required";
    my $start_h = sub {
        my ( $pos, $tagname, $text ) = @_;
        my $has_style;
        if ( @$pos >= 4 ) {

            # kill some attributes
            my ( $k_offset, $k_len, $v_offset, $v_len ) = @{$pos}[ -4 .. -1 ];
            my $next_attr
                = $v_offset ? $v_offset + $v_len : $k_offset + $k_len;
            my $edited;
            while ( @$pos >= 4 ) {
                ( $k_offset, $k_len, $v_offset, $v_len ) = splice @$pos, -4;
                my $attrname = lc substr( $text, $k_offset, $k_len );
                if ( $attrname eq 'style' ) {
                    $has_style = 1;
                }
                if ( $ignore_attr{$attrname} ) {
                    substr( $text, $k_offset, $next_attr - $k_offset ) = "";
                    $edited++;
                }
                $next_attr = $k_offset;
            }

            # if we killed all attributed, kill any extra whitespace too
            $text =~ s/^(<\w+)\s+>$/$1>/ if $edited;
        }

        # http://redmine.publicradio.org/issues/11239
        # explicit margin on p tags
        if ( lc($tagname) eq 'p' ) {
            if ($has_style) {

                #warn "has_style: $text";
                if ( $text =~ m/margin(\-\w+)?:/ ) {

                    # do nothing, since margin already defined.
                    #warn "has margin: $text";
                }
                else {
                    $text =~ s/(style=.)/$1margin-bottom:1em;/;
                }
            }
            else {
                #warn "no style: $text";
                $text =~ s/<p>/<p style="margin-bottom:1em;">/;
            }
        }

        $$bufref .= $text;
    };

    my $parser = HTML::Parser->new(
        api_version     => 3,
        start_h         => [ $start_h, "tokenpos, tagname, text" ],
        process_h       => [ "", "" ],
        comment_h       => [ "", "" ],
        declaration_h   => [ sub { }, "tagname, text" ],              # ignore
        default_h       => [ sub { $$bufref .= shift }, "text" ],
        ignore_tags     => \@ignore_tags,
        ignore_elements => \@ignore_elements,
    );
    return $parser;
}

1;
