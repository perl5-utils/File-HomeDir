package File::HomeDir::Windows;

# Generalised implementation for the entire Windows family of operating
# systems.

use 5.005;
use strict;
use Carp       ();
use File::Spec ();

# Globals
use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.52';
}

# If prefork is available, set Win32::TieRegistry
# to be preloaded if needed.
eval "use prefork 'Win32::TieRegistry'";





#####################################################################
# Current User Methods

sub my_home {
	my $class = shift;

	# Do we have a user profile?
	if ( $ENV{USERPROFILE} ) {
		return $ENV{USERPROFILE};
	}

	# Some Windows use something like $ENV{HOME}
	if ( $ENV{HOMEDRIVE} and $ENV{HOMEPATH} ) {
		return File::Spec->catpath(
			$ENV{HOMEDRIVE}, $ENV{HOMEPATH}, '',
			);
	}

	Carp::croak("Could not locate current user's home directory");
}

sub my_desktop {
	my $class = shift;

	# The most correct way to find the desktop
	SCOPE: {
		my $home = $class->my_win32_folder('Desktop');
		return $home if $home and -d $home;
	}

	# MSWindows sets WINDIR, MS WinNT sets USERPROFILE.
	foreach my $e ( 'USERPROFILE', 'WINDIR' ) {
		next unless $ENV{$e};
		my $desktop = File::Spec->catdir($ENV{$e}, 'Desktop');
		return $desktop if $desktop and -d $desktop;
	}

	# As a last resort, try some hard-wired values
	foreach my $fixed (
		"C:\\windows\\desktop",
		"C:\\win95\\desktop",
		# In the original, I can only assume this is Cygwin stuff
		"C:/win95/desktop",
		"C:/windows/desktop",
	) {
		return $fixed if $fixed and -d $fixed;
	}

	Carp::croak("Failed to find current user's desktop");
}

sub my_documents {
	my $class = shift;

	# The most correct way to find my documents
	SCOPE: {
		my $home = $class->my_win32_folder('Personal');
		return $home if $home and -d $home;
	}

	Carp::croak("Failed to find current user's documents");
}

sub my_data {
	my $class = shift;

	# The most correct way to find my documents
	SCOPE: {
		my $home = $class->my_win32_folder('Local AppData');
		return $home if $home and -d $home;
	}

	Carp::croak("Failed to find current user's documents");
}

# The explorer shell holds all sorts of folder information.
# This method is specific to this platform
sub my_win32_folder {
	my $class = shift;

	# Find the shell's folder hash
	local $SIG{'__DIE__'} = '';
	require Win32::TieRegistry;
	my $folders = Win32::TieRegistry->new(
		'HKEY_CURRENT_USER/Software/Microsoft/Windows/CurrentVersion/Explorer/Shell Folders',
		{ Delimiter => '/' },
		) or return undef;

	# Find the specific folder
	my $folder = $folders->GetValue(shift);
	return $folder;
}





#####################################################################
# General User Methods

sub users_home {
	my ($class, $name) = @_;
	Carp::croak("users_home is not implemented on this platform");
}

sub users_documents {
	my ($class, $name) = @_;
	Carp::croak("users_documents is not implemented on this platform");
}

sub users_data {
	my ($class, $name) = @_;
	Carp::croak("users_data is not implemented on this platform");
}

sub users_desktop {
	my ($class, $name) = @_;
	Carp::croak("users_desktop is not implemented on this platform");
}

1;
