package File::HomeDir::Mac;

# Mac-specific functionality

use 5.005;
use strict;
use Carp ();

# Globals
use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.10';
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

	# Next up, go via Mac::Files
	local $SIG{"__DIE__"} = "";
	require Mac::Files;
	my $home = Mac::Files::FindFolder(
		Mac::Files::kOnSystemDisk,
		Mac::Files::kDesktopFolderType,
		);
	if ( $home and -d $home ) {
		return $home;
	}

	### DESPERATION SETS IN

	# Light desperation on any platform
	SCOPE: {
		# On some platforms getpwuid dies if called at all
		local $SIG{'__DIE__'} = '';
		my $home = (getpwuid($<))[7];
		return $home if $home and -d $home;
	}

	Carp::croak("Could not locate current user's home directory");
}

sub my_desktop {
	Carp::croak("The my_desktop is not implemented on this platform");
}





#####################################################################
# General User Methods

sub user_home {
	my ($class, $name) = @_;

	SCOPE: {
		# On some platforms getpwnam dies if called at all
		local $SIG{'__DIE__'} = '';
		my $home = (getpwnam($name))[7];
		return $home if defined $home and -d $home;
	}

	Carp::croak("Failed to find home directory for user '$name'");
}

1;
