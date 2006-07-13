#!/usr/bin/perl -w

# Main testing for File::HomeDir

use strict;
use lib ();
use File::Spec::Functions ':ALL';
use English '-no_match_vars';
BEGIN {
	$| = 1;
	unless ( $ENV{HARNESS_ACTIVE} ) {
		require FindBin;
		$FindBin::Bin = $FindBin::Bin; # Avoid a warning
		chdir catdir( $FindBin::Bin, updir() );
		lib->import(
			catdir('blib', 'arch'),
			catdir('blib', 'lib' ),
			catdir('lib'),
			);
	}
}

use Test::More tests => 40;
use File::HomeDir;

# For what scenarios can we be sure that we have desktop/documents
my $HAVETOYS = 0;
if ( $^O eq 'MSWin32' ) {
	$HAVETOYS = 1;
}
if ( $^O eq 'darwin' and $< ) {
	$HAVETOYS = 1;
}

# Find this user's homedir
my $home = home();
ok( $home, 'Found our home directory'     );
ok( -d $home, 'Our home directory exists' );

# this call is not tested:
# File::HomeDir->home

eval {
    home(undef);
};
like( $@, qr{Can't use undef as a username}, 'home(undef)' );
my $warned = 0;
eval {
	local $SIG{__WARN__} = sub { $warned++ };
	my $h = $~{undef()};
};
is( $warned, 1, 'Emitted a single warning' );
like( $@, qr{Can't use undef as a username}, '%~(undef())' );


# Check error messages for unavailable tie constructs
eval {
    $~{getpwuid($UID)} = "new_dir";
};
like( $@, qr{You can't STORE with the %~ hash}, 'Cannot store in %~ hash' );

eval {
    exists $~{getpwuid($UID)};
};
like( $@, qr{You can't EXISTS with the %~ hash}, 'Cannot store in %~ hash' );

eval {
    delete $~{getpwuid($UID)};
};
like( $@, qr{You can't DELETE with the %~ hash}, 'Cannot store in %~ hash' );

eval {
    %~ = ();
};
like( $@, qr{You can't CLEAR with the %~ hash}, 'Cannot store in %~ hash' );

eval {
    my ($k, $v) = each(%~);
};
like( $@, qr{You can't FIRSTKEY with the %~ hash}, 'Cannot store in %~ hash' );


# right now if you call keys in void context
# keys(%~);
# it does not throw an exception while if you call it in list context it
# throws an exception.
my @usernames;
eval {
    @usernames = keys(%~);
};
like( $@, qr{You can't FIRSTKEY with the %~ hash}, 'Cannot store in %~ hash' );

# How to test NEXTKEY error if FIRSTKEY already throws an exception?




# Find this user's home explicitly
my $my_home = File::HomeDir->my_home;
ok( $my_home, 'Found our home directory'     );
ok( -d $my_home, 'Our home directory exists' );
is( $home, $my_home, 'Different APIs give same results' );
is( home(getpwuid($UID)), $home, 'home(username) returns the same value' );

is( $~{""}, $home, 'Legacy %~ tied interface' );
is( $~{getpwuid($UID)}, $home, 'Legacy %~ tied interface' );


my $my_home2 = File::HomeDir::my_home();
ok( $my_home2, 'Found our home directory'     );
ok( -d $my_home2, 'Our home directory exists' );
is( $home, $my_home2, 'Different APIs give same results' );

# shall we test using -w if the home directory is writable ?

# Find this user's documents
my $my_documents = File::HomeDir->my_documents;
SKIP: {
	skip("Cannot assume existance of certain directories", 1) unless $HAVETOYS;
	ok( $my_documents, 'Found our documents directory' );
}
SKIP: {
	skip("No directory to test", 1) unless $my_documents;
	ok( -d $my_documents, 'Our documents directory exists' );
}

my $my_documents2 = File::HomeDir::my_documents();
SKIP: {
	skip("Cannot assume existance of certain directories", 1) unless $HAVETOYS;
	ok( $my_documents2, 'Found our documents directory' );
}
SKIP: {
	skip("No directory to test", 2) unless $my_documents2;
	ok( -d $my_documents2, 'Our documents directory exists' );
	is( $my_documents, $my_documents2, 'Different APIs give the same results' );
}

# Find this user's local data
my $my_data = File::HomeDir->my_data;
SKIP: {
	skip("Cannot assume existance of certain directories", 1) unless $HAVETOYS;
	ok( $my_data, 'Found our local data directory'     );
}
SKIP: {
	skip("No directory to test", 1) unless $my_data;
	ok( -d $my_data, 'Our local data directory exists' );
}

my $my_data2 = File::HomeDir::my_data();
SKIP: {
	skip("Cannot assume existance of certain directories", 1) unless $HAVETOYS;
	ok( $my_data2, 'Found our local data directory'     );
}
SKIP: {
	skip("No directory to test", 2) unless $my_data2;
	ok( -d $my_data2, 'Our local data directory exists' );
	is( $my_data, $my_data2, 'Different APIs give the same results' );
}



# On windows, we also implement my_desktop
SKIP: {
	unless ( $HAVETOYS ) {
		skip("Cannot assume existance of certain directories", 5 );
	}

	# Find this user's local data
	my $my_desktop = File::HomeDir->my_desktop;
	ok( $my_desktop,    'Found our desktop directory'  );
	ok( -d $my_desktop, 'Our local data directory exists' );
	my $my_desktop2 = File::HomeDir::my_desktop();
	ok( $my_desktop2,    'Found our desktop directory'  );
	ok( -d $my_desktop2, 'Our local data directory exists' );
	is( $my_desktop, $my_desktop2, 'Different APIs give the same results' );
}

# Shall we check name space pollution by testing functions in main before
# and after calling use ?

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
