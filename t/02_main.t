#!/usr/bin/perl -w

# Main testing for File::HomeDir

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}
use File::Spec::Functions ':ALL';
use Test::More;
use File::HomeDir;

# This module is destined for the core.
# Please do NOT use convenience modules
# use English; <-- don't do this





#####################################################################
# Environment Detection and Plan

# For what scenarios can we be sure that we have desktop/documents
my $HAVETOYS    = 0;
my $NO_GETPWUID = 0;
if ( $^O eq 'MSWin32' ) {
	$HAVETOYS    = 1;
	$NO_GETPWUID = 1;
}
if ( $^O eq 'darwin' and $< ) {
	$HAVETOYS    = 1;
}

plan tests => 41;





#####################################################################
# Main Tests

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
SKIP: {
	skip("getpwuid not available", 3) if $NO_GETPWUID;

	eval {
    	$~{getpwuid($<)} = "new_dir";
	};
	like( $@, qr{You can't STORE with the %~ hash}, 'Cannot store in %~ hash' );

	eval {
	    exists $~{getpwuid($<)};
	};
	like( $@, qr{You can't EXISTS with the %~ hash}, 'Cannot store in %~ hash' );

	eval {
	    delete $~{getpwuid($<)};
	};
	like( $@, qr{You can't DELETE with the %~ hash}, 'Cannot store in %~ hash' );
}

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
SKIP: {
	skip("getpwuid not available", 1) if $NO_GETPWUID;
	is( home(getpwuid($<)), $home, 'home(username) returns the same value' );
}

is( $~{""}, $home, 'Legacy %~ tied interface' );
SKIP: {
	skip("getpwuid not available", 1) if $NO_GETPWUID;
	is( $~{getpwuid($<)}, $home, 'Legacy %~ tied interface' );
}


my $my_home2 = File::HomeDir::my_home();
ok( $my_home2, 'Found our home directory'     );
ok( -d $my_home2, 'Our home directory exists' );
is( $home, $my_home2, 'Different APIs give same results' );

# shall we test using -w if the home directory is writable ?

# Find this user's documents
my $my_documents = File::HomeDir->my_documents;
SKIP: {
	skip("Cannot assume existance of certain directories", 1) unless $HAVETOYS;
	ok( !!($my_documents and -d $my_documents), 'Found our documents directory' );
}

my $my_documents2 = File::HomeDir::my_documents();
SKIP: {
	skip("Cannot assume existance of certain directories", 1) unless $HAVETOYS;
	ok( !!($my_documents2 and $my_documents2), 'Found our documents directory' );
}
is( $my_documents, $my_documents2, 'Different APIs give the same results' );

# Find this user's local data
my $my_data = File::HomeDir->my_data;
SKIP: {
	skip("Cannot assume existance of certain directories", 1) unless $HAVETOYS;
	ok( !!($my_data and -d $my_data), 'Found our local data directory'     );
}

my $my_data2 = File::HomeDir::my_data();
SKIP: {
	skip("Cannot assume existance of certain directories", 1) unless $HAVETOYS;
	ok( !!($my_data2 and -d $my_data2), 'Found our local data directory'     );
}
is( $my_data, $my_data2, 'Different APIs give the same results' );

# Desktop cannot be assumed in all environments
SKIP: {
	unless ( $HAVETOYS ) {
		skip("Cannot assume existance of user Desktop directories", 12 );
	}

	# Find this user's desktop data
	my $my_desktop = File::HomeDir->my_desktop;
	ok( !!($my_desktop and -d $my_desktop),    'Our desktop directory exists'  );
	my $my_desktop2 = File::HomeDir::my_desktop();
	ok( !!($my_desktop2 and -d $my_desktop2), 'Our local data directory exists' );
	is( $my_desktop, $my_desktop2, 'Different APIs give the same results' );

	my $my_music = File::HomeDir->my_music;
	ok( !!($my_music and -d $my_music), 'Our local data directory exists' );
	my $my_music2 = File::HomeDir::my_music();
	ok( !!($my_music2 and -d $my_music2), 'Our local data directory exists' );
	is( $my_music, $my_music2, 'Different APIs give the same results' );

	my $my_pictures = File::HomeDir->my_pictures;
	ok( !!($my_pictures and -d $my_pictures), 'Our local data directory exists' );
	my $my_pictures2 = File::HomeDir::my_pictures();
	ok( !!($my_pictures2 and -d $my_pictures2), 'Our local data directory exists' );
	is( $my_pictures, $my_pictures2, 'Different APIs give the same results' );
	
	my $my_videos = File::HomeDir->my_videos;
	ok( !!($my_videos and -d $my_videos), 'Our local data directory exists' );
	my $my_videos2 = File::HomeDir::my_videos();
	ok( !!($my_videos2 and -d $my_videos2), 'Our local data directory exists' );
	is( $my_videos, $my_videos2, 'Different APIs give the same results' );
}

# Shall we check name space pollution by testing functions in main before
# and after calling use ?

# On platforms other than windows, find root's homedir
SKIP: {
	if ( $^O eq 'MSWin32' or $^O eq 'darwin') {
		skip("Skipping root test on $^O", 3 );
	}

	# Determine root
	my $root = getpwuid(0);
	unless ( $root ) {
		skip("Skipping, can't determine root", 3 );
	}

	# Get root's homedir
	my $root_home1 = home($root);
	ok( !!($root_home1 and -d $root_home1), "Found root's home directory" );

	# Confirm against %~ hash
	my $root_home2 = $~{$root};
	ok( !!($root_home2 and -d $root_home2), "Found root's home directory" );

	# Root account via different methods match
	is( $root_home1, $root_home2, 'Home dirs match' );
}

exit(0);
