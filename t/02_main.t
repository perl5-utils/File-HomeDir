#!/usr/bin/perl -w

# Main testing for File::HomeDir

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

use Test::More tests => 7;
use File::HomeDir;

# Find this user's homedir
my $home = home();
ok( $home, 'Found our home direcotry'     );
ok( -d $home, 'Our home directory exists' );

# On platforms other than windows, find root's homedir
SKIP: {
	if ( $^O eq 'MSWin32' ) {
		skip("Skipping root test on Windows", 5 );
	}

	# Determine root
	my $root = getpwuid(0);
	unless ( $root ) {
		skip("Skipping, can't determine root", 5 );
	}

	# Get root's homedir
	my $root_home1 = home($root);
	ok( $root_home1,    "Got root's home direcotry"   );
	ok( -d $root_home1, "Found root's home direcotry" );

	# Confirm against %~ hash
	my $root_home2 = $~{$root};
	ok( $root_home2,    "Got root's home direcotry"   );
	ok( -d $root_home2, "Found root's home direcotry" );

	# Root account via different methods match
	is( $root_home1, $root_home2, 'Home dirs match' );
}

exit(0);
