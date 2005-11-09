#!/usr/bin/perl -w

# Compile-testing for File::HomeDir

use strict;
use lib ();
use UNIVERSAL 'isa';
use File::Spec::Functions ':ALL';
BEGIN {
	$| = 1;
	unless ( $ENV{HARNESS_ACTIVE} ) {
		require FindBin;
		$FindBin::Bin = $FindBin::Bin; # Avoid a warning
		chdir catdir( $FindBin::Bin, updir() );
		lib->import('blib', 'lib');
	}
}

use Test::More tests => 3;

ok( $] > 5.004, 'Perl version is 5.004 or newer' );

use_ok( 'File::HomeDir' );

ok( defined &home, 'Using File::HomeDir exports home()'    );

exit(0);
