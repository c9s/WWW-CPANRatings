#!/usr/bin/env perl
use Test::More;
use WWW::CPANRatings;

my $r = WWW::CPANRatings->new;
ok( $r );


ok( $r->prepare );
ok( $r->rating_data );

my @reviews;
ok( @reviews = $r->get_reviews('Moose') );

for ( @reviews ) {
    ok( $_->{dist_name} );
    ok( $_->{user} );
    ok( $_->{user_link} );
}

done_testing;
