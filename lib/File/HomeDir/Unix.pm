package File::HomeDir::Unix;

# Unix-specific functionality

use 5.005;
use strict;

# Globals
use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.54';
}





#####################################################################
# Current User Methods

sub my_home {
	my $class = shift;
	return $ENV{HOME} if defined $ENV{HOME};

	# This is from the original code, but I'm guessing
	# it means "login directory".
	return $ENV{LOGDIR} if $ENV{LOGDIR};

	### More-desperate methods

	# Light desperation on any platform
	SCOPE: {
		# On some platforms getpwuid dies if called at all
		my $home = (getpwuid($<))[7];
		return $home if $home and -d $home;
	}

	Carp::croak("Could not locate current user's home directory");
}

sub my_desktop {
	Carp::croak("The my_desktop is not implemented on this platform");
}

# On unix, we keep both data and documents under the same folder
sub my_documents {
	shift->my_home;
}

sub my_data {
	shift->my_home;
}





#####################################################################
# General User Methods

sub users_home {
	my ($class, $name) = @_;

	SCOPE: {
		# On some platforms getpwnam dies if called at all
		my $home = (getpwnam($name))[7];
		return $home if $home and -d $home;
	}

	Carp::croak("Failed to find home directory for user '$name'");
}

sub users_desktop {
	my ($class, $name) = @_;
	Carp::croak("Failed to find desktop for user '$name'");
}

sub users_documents {
	shift->users_home(@_);
}

sub users_data {
	shift->users_home(@_);
}

1;
