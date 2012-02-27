#!perl -T

use Test::More tests => 4;

BEGIN {
    use_ok( 'FWS::V2' ) || print "Bail out!\n";
    use_ok( 'FWS::V2::Check' ) || print "Bail out!\n";
    use_ok( 'FWS::Database' ) || print "Bail out!\n";
    use_ok( 'FWS::V2::Safety' ) || print "Bail out!\n";
}

diag( "Testing FWS::V2 $FWS::V2::VERSION, Perl $], $^X" );
