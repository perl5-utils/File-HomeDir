package File::HomeDir::Darwin;

# Basic implementation for the Dawin family of operating systems.
# This includes (most prominently) Mac OS X.

use 5.005;
use strict;
use base 'File::HomeDir::Unix';
use Carp ();

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.58';
}





#####################################################################
# Current User Methods

# sub my_home (no change)

sub my_desktop {
	my $class = shift;

	# On Darwin the desktop should live at ~/Desktop
	SCOPE: {
		my $dir = $class->_to_desktop( $class->my_home );
		return $dir if $dir;
	}

	Carp::croak("Could not locate current user's desktop");
}

sub my_documents {
	my $class = shift;

	# On Darwin the desktop should live at ~/Documents
	SCOPE: {
		my $dir = $class->_to_documents( $class->my_home );
		return $dir if $dir;
	}

	Carp::croak("Could not locate current user's documents");
}

sub my_data {
	my $class = shift;

	# On Darwin the desktop should live at ~/Library/Application Support
	SCOPE: {
		my $dir = $class->_to_data( $class->my_home );
		return $dir if $dir;
	}

	Carp::croak("Could not locate current user's application data");
}





#####################################################################
# Arbitrary User Methods

# sub users_home (no change)

sub users_desktop {
	my $class = shift;

	# On Darwin the desktop should live at ~/Documents
	SCOPE: {
		my $dir = $class->_to_desktop( $class->users_home(@_) );
		return $dir if $dir;
	}

	Carp::croak("Could not locate user's desktop");	
}

sub users_documents {
	my $class = shift;

	# On Darwin the desktop should live at ~/Documents
	SCOPE: {
		my $dir = $class->_to_documents( $class->users_home(@_) );
		return $dir if $dir;
	}

	Carp::croak("Could not locate user's desktop");	
}

sub users_data {
	my $class = shift;

	# On Darwin the desktop should live at ~/Documents
	SCOPE: {
		my $dir = $class->_to_data( $class->users_home(@_) );
		return $dir if $dir;
	}

	Carp::croak("Could not locate user's desktop");	
}





#####################################################################
# Support Methods

# On Darwin you can find a resource from the home directory consistently.

sub _to_documents {
	File::Spec->catdir( $_[1], 'Documents' );
}

sub _to_desktop {
	File::Spec->catdir( $_[1], 'Desktop' );
}

sub _to_data {
	File::Spec->catdir( $_[1], 'Library', 'Application Support' );
}

1;
