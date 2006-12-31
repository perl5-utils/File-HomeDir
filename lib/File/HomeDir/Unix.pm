package File::HomeDir::Unix;

# Unix-specific functionality

use 5.005;
use strict;
use Carp ();

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.60_08';
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

	return undef;
}

# On unix, we usually keep both data and documents under the same folder
sub my_documents {
	shift->my_home;
}

sub my_data {
	shift->my_home;
}

sub my_music {
	shift->my_home;
}

sub my_pictures {
	shift->my_home;
}

sub my_videos {
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

	return undef;
}

sub users_documents {
	shift->users_home(@_);
}

sub users_data {
	shift->users_home(@_);
}

sub users_music {
	shift->users_home(@_);
}

sub users_pictures {
	shift->users_home(@_);
}

sub users_videos {
	shift->users_home(@_);
}

1;

=pod

=head1 NAME

File::HomeDir::Unix - find your home and other directories, on Unix

=head1 DESCRIPTION

This module provides implementations for determining common user
directories.  In normal usage this module will always be
used via L<File::HomeDir>.

=head1 SYNOPSIS

  use File::HomeDir;
  
  # Find directories for the current user
  $home    = File::HomeDir->my_home;        # /home/mylogin

  $desktop = File::HomeDir->my_desktop;     # .. all of these will default to home directory at the moment ..
  $docs    = File::HomeDir->my_documents;   #
  $music   = File::HomeDir->my_music;       #
  $pics    = File::HomeDir->my_pictures;    #
  $videos  = File::HomeDir->my_videos;      #
  $data    = File::HomeDir->my_data;        # 

=head1 TODO

=over 4

=item * Add support for common unix desktop and data directories when using KDE / Gnome / ...

=back
