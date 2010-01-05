package File::HomeDir::FreeDesktop;

# specific functionality for unixes running free desktops

use 5.00503;
use strict;
use Carp                ();
use File::Spec          ();
use File::HomeDir::Unix ();

use vars qw{$VERSION @ISA};
BEGIN {
	$VERSION = '0.89';
	@ISA     = 'File::HomeDir::Unix';
}


# On unix by default, everything is under the same folder
sub my_desktop {
	shift->my_home;
}

sub my_documents {
	shift->my_home;
}

sub my_data {
    $ENV{XDG_DATA_HOME}
        || File::Spec->catdir(shift->my_home, qw{ .local share });
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

	# IF and only if we have getpwuid support, and the
	# name of the user is our own, shortcut to my_home.
	# This is needed to handle HOME environment settings.
	if ( $name eq getpwuid($<) ) {
		return $class->my_home;
	}

	SCOPE: {
		my $home = (getpwnam($name))[7];
		return $home if $home and -d $home;
	}

	return undef;
}

sub users_desktop {
	shift->users_home(@_);
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

  $desktop = File::HomeDir->my_desktop;     # All of these will... 
  $docs    = File::HomeDir->my_documents;   # ...default to home...
  $music   = File::HomeDir->my_music;       # ...directory at the...
  $pics    = File::HomeDir->my_pictures;    # ...moment.
  $videos  = File::HomeDir->my_videos;      #
  $data    = File::HomeDir->my_data;        # 

=head1 TODO

=over 4

=item * Add support for common unix desktop and data directories when using KDE / Gnome / ...

=back
