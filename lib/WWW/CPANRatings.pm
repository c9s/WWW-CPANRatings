package WWW::CPANRatings;
use strict;
use warnings;
our $VERSION = '0.01';

use List::Util qw(sum);
use LWP::Simple;
use DateTime::Format::DateParse;
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
    my %rating_data;

    for my $line ( @lines ) {
        chomp($line);
        my $status  = $csv->parse($line);
        die 'csv file parse failed.' unless $status;
        my ($dist,$rating,$review_count) = $csv->fields();

        # say $dist, $rating, $review_count;
        $rating_data{ $dist } = {
            dist => $dist,
            rating => $rating,
            review_cnt => $review_count,
        };
    }
    return $self->{rating_data} = \%rating_data;
}

sub rating_data { 
    my $self = shift;
    return $self->{rating_data};
}

sub get_ratings {
    my ($self,$distname) = @_;
    return $self->{rating_data}->{ $distname };
}

# dist_name format 
sub get_reviews {
    my ($self,$modname) = @_;
    my $distname = $modname;
    $distname =~ s/::/-/g;
    my $base_url = "http://cpanratings.perl.org/dist/";
    my $url = $base_url . $distname;
    my $content = get($url);
    return unless $content =~ /$modname reviews/;
    my $result = $self->parse_review_page($content);
    return @{ $result->{reviews} };
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

            process '.review_header',
                    header => 'TEXT';

            process '.review_text', body => 'TEXT';
            process '.review_attribution' ,
                'attrs' => 'TEXT';
            process '.review_attribution a' , 
                'user' => 'TEXT',
                'user_link' => '@href';
        };
    };
    my $res = $rating_scraper->scrape( URI->new("http://cpanratings.perl.org/dist/Moose") );

    # post process

    for my $review ( @{ $res->{reviews} } ) {
        if( $review->{header} =~ m{^\s*([a-zA-Z:]+)\s+\(([0-9.]+)\)\s*$} ) {
            $review->{version} = $2;
            say $review->{version};
        }

        if( $review->{attrs} =~ m{\s([0-9-T:]+)\s*$} ) {
            $review->{timestamp} = 
                DateTime::Format::DateParse->parse_datetime( $1 );
        }
    }
    return $res;
}


1;
__END__

=head1 NAME

WWW::CPANRatings - parsing CPANRatings data

=head1 SYNOPSIS

    use WWW::CPANRatings;

    my $r = WWW::CPANRatings->new;
    $r->prepare;   # download cpanrating csv file and build the data...

    my $all_ratings = $r->rating_data;  # get rating data.

    my $ratings = $r->get_ratings( 'Moose' );  # get Moose rating scores.

    my @reviews = $r->get_reviews( 'Moose' );  # parse review text from cpanratings.perl.org.

    for my $r ( @reviews ) {
        $r->{dist_name};
        $r->{dist_link};
        $r->{version}
        $r->{user};
        $r->{user_link};
        $r->{timestamp};  # DateTime object.
    }

=head1 DESCRIPTION

=head1 METHODS

=head2 $r->prepare()

Download/Parse csv rating data.

=head2 AllRatingData | HashRef = $r->rating_data()

Get csv rating data.

=head2 RatingData | HashRef = $r->get_ratings( DistName | String )

Get rating data of a distribution

=head2 Reviews | Array = $r->get_reviews( DistName | String )

Get distribution reviews (including text, user, timestamp)

=head1 AUTHOR

Yo-An Lin E<lt>cornelius.howl {at} gmail.comE<gt>

=head1 SEE ALSO

L<WWW::CPANRatings::RSS>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
