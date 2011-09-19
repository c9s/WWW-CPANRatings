#!/usr/bin/env perl
use Test::More;
use WWW::CPANRatings;



my $r = WWW::CPANRatings->new;
ok( $r );


ok( $r->prepare );
ok( $r->rating_data );

my $ret;
ok( $ret = $r->get_module_reviews('Moose') );

done_testing;
