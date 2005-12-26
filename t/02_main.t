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

use Test::More tests => 23;
use File::HomeDir;

# Find this user's homedir
my $home = home();
ok( $home, 'Found our home directory'     );
ok( -d $home, 'Our home directory exists' );

# Find this user's home explicitly
my $my_home = File::HomeDir->my_home;
ok( $my_home, 'Found our home directory'     );
ok( -d $my_home, 'Our home directory exists' );
$my_home = File::HomeDir::my_home();
ok( $my_home, 'Found our home directory'     );
ok( -d $my_home, 'Our home directory exists' );

# Find this user's documents
my $my_documents = File::HomeDir->my_documents;
ok( $my_documents, 'Found our documents directory'     );
ok( -d $my_documents, 'Our documents directory exists' );
$my_documents = File::HomeDir::my_documents();
ok( $my_documents, 'Found our documents directory'     );
ok( -d $my_documents, 'Our documents directory exists' );

# Find this user's local data
my $my_data = File::HomeDir->my_data;
ok( $my_data, 'Found our local data directory'     );
ok( -d $my_data, 'Our local data directory exists' );
$my_data = File::HomeDir::my_data();
ok( $my_data, 'Found our local data directory'     );
ok( -d $my_data, 'Our local data directory exists' );

# On windows, we also implement my_desktop
SKIP: {
	unless ( $^O eq 'MSWin32' ) {
		skip("Skipping desktop on non-Windows", 4 );
	}

	# Find this user's local data
	my $my_desktop = File::HomeDir->my_desktop;
	ok( $my_desktop,    'Found our local data directory'  );
	ok( -d $my_desktop, 'Our local data directory exists' );
	$my_desktop = File::HomeDir::my_desktop();
	ok( $my_desktop,    'Found our local data directory'  );
	ok( -d $my_desktop, 'Our local data directory exists' );
}

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
