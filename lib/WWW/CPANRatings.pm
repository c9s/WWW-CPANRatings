package WWW::CPANRatings;
use strict;
use warnings;
our $VERSION = '0.01';

use Data::Dumper;
use Data::Dump;
use List::Util qw(sum);
use LWP::Simple;
use HTML::TokeParser::Simple;
use URI;
use Web::Scraper;
use JSON::XS;
use Text::CSV_PP;
use feature 'say';

sub new { 
    my $class = shift;
    my $args = shift || {};
    bless $args,$class;
}


sub prepare {
    my $self = shift;
    my $arg = shift;

    # if it's file
    my $text;
    if( $arg && -e $arg ) {
        open my $fh , "<" , $arg;
        local $/;
        $text = <$fh>;
        close $fh;
    }
    elsif( $arg && $arg =~ /^http/ ) {
        $text = get( $arg );
    }

    unless ( $text ) {
        $text = get('http://cpanratings.perl.org/csv/all_ratings.csv');
    }

    my @lines = split /\n/,$text;
    my $csv = Text::CSV_PP->new();     # create a new object

    # drop first 2 lines
    splice @lines,0,2;
    my @rating_data;
    for my $line ( @lines ) {
        chomp($line);
        my $status  = $csv->parse($line);
        die 'csv file parse failed.' unless $status;
        my ($dist,$rating,$review_count) = $csv->fields();

        # say $dist, $rating, $review_count;
        push @rating_data, { 
            dist => $dist,
            rating => $rating,
            review_cnt => $review_count,
        };
    }
    $self->{rating_data} = \@rating_data;
    return @rating_data;
}

sub rating_data { 
    my $self = shift;
    return $self->{rating_data};
}

# dist_name format 
sub get_module_reviews {
    my ($self,$modname) = @_;
    my $distname = $modname;
    $distname =~ s/::/-/g;
    my $base_url = "http://cpanratings.perl.org/dist/";
    my $url = $base_url . $distname;
    my $content = get($url);
    return unless $content =~ /$modname reviews/;
    my %json_hash = $self->parse_review_page($content);
}


# returned structure,
#     $VAR1 = {
#        'reviews' => [
#                 {
#                   'body' => ' Moose got me laid. Could you ask anything more of a CPAN module? ',
#                   'user_link' => bless( do{\(my $o = 'http://cpanratings.perl.org/user/funguy')}, 'URI::http' ),
#                   'attrs' => 'Fun Guy - 2011-04-12T14:30:46 ',
#                   'dist_name' => ' Moose',
#                   'user' => 'Fun Guy',
#                   'dist_link' => bless( do{\(my $o = 'http://search.cpan.org/dist/Moose/')}, 'URI::http' )
#                 },

sub parse_review_page {
    my ($self,$content) = @_;

    my $rating_scraper = scraper {
        process '.review' => 'reviews[]' => scraper {
            process '.review_header a', 
                    dist_link => '@href',
                    dist_name => 'TEXT';
            process '.review_text', body => 'TEXT';
            process '.review_attribution' ,
                'attrs' => 'TEXT';
            process '.review_attribution a' , 
                'user' => 'TEXT',
                'user_link' => '@href';
        };
    };
    my $res = $rating_scraper->scrape( URI->new("http://cpanratings.perl.org/dist/Moose") );
    return $res;
}


1;
__END__

=head1 NAME

WWW::CPANRatings - parsing CPANRatings data

=head1 SYNOPSIS

    use WWW::CPANRatings;


=head1 DESCRIPTION

WWW::CPANRatings is

=head1 AUTHOR

Yo-An Lin E<lt>cornelius.howl {at} gmail.comE<gt>

=head1 SEE ALSO

L<WWW::CPANRatings::RSS>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
