#!/usr/bin/env perl
use lib 'lib';
use Test::More;
use URI;
use Web::Scraper;

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
ok( $res );
ok( $res->{reviews} );

for my $review ( @{ $res->{reviews} } ) {
    ok( $review );
    ok( $review->{body} );
    ok( $review->{dist_name} );
    ok( $review->{dist_link} );
    ok( $review->{user} );
    ok( $review->{user_link} );
    ok( $review->{attrs} );
}

done_testing;
