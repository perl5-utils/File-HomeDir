package File::HomeDir::MacOS9;

# Half-assed implementation for the legacy Mac OS9 operating system.
# Provided mainly to provide legacy compatibility. May be removed at
# a later date.

use 5.005;
use strict;
use Carp ();

# Globals
use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.56';
}

# If prefork is available, set Mac::Files
# to be preloaded if needed.
eval "use prefork 'Mac::Files'";





#####################################################################
# Current User Methods

sub my_home {
	my $class = shift;

	# Try for $ENV{HOME} if we have it
	if ( defined $ENV{HOME} ) {
		return $ENV{HOME};
	}

	### DESPERATION SETS IN

	# We could use the desktop
	eval {
		my $home = $class->my_desktop;
		return $home if $home and -d $home;
	};

	# Desperation on any platform
	SCOPE: {
		# On some platforms getpwuid dies if called at all
		local $SIG{'__DIE__'} = '';
		my $home = (getpwuid($<))[7];
		return $home if $home and -d $home;
	}

	Carp::croak("Could not locate current user's home directory");
}

sub my_desktop {
	my $class = shift;

	# Find the desktop via Mac::Files
	local $SIG{'__DIE__'} = '';
	require Mac::Files;
	my $home = Mac::Files::FindFolder(
		Mac::Files::kOnSystemDisk(),
		Mac::Files::kDesktopFolderType(),
		);
	return $home if $home and -d $home;

	Carp::croak("Could not locate current user's desktop");
}

sub my_documents {
	Carp::croak("my_documents is not implemented on Mac OS 9");
}

sub my_data {
	Carp::croak("my_data is not implemented on Mac OS 9");
}





#####################################################################
# General User Methods

sub users_home {
	my ($class, $name) = @_;

	SCOPE: {
		# On some platforms getpwnam dies if called at all
		local $SIG{'__DIE__'} = '';
		my $home = (getpwnam($name))[7];
		return $home if defined $home and -d $home;
	}

	Carp::croak("Failed to find home directory for user '$name'");
}

sub users_desktop {
	my ($class, $name) = @_;
	Carp::croak("users_desktop is not implemented on this platform");
}

sub users_documents {
	my ($class, $name) = @_;
	Carp::croak("users_documents is not implemented on this platform");
}

sub users_data {
	my ($class, $name) = @_;
	Carp::croak("users_data is not implemented on this platform");
}
	
1;
