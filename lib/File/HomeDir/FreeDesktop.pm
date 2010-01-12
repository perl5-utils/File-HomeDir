package File::HomeDir::FreeDesktop;

# specific functionality for unixes running free desktops

use 5.00503;
use strict;
use Carp                ();
use File::Spec          ();
use File::HomeDir::Unix ();

use vars qw{$VERSION @ISA};
BEGIN {
	$VERSION = '0.90_01';
	@ISA     = 'File::HomeDir::Unix';
}

# xdg uses ~/.config/user-dirs.dirs to know where are the
# various "my xxx" directories.
sub _my_thingy {
	my ($class, $wanted, $user) = @_;

	# Find the user's config file
	my $home = defined($user)
		? $class->users_home($user)
		: $class->my_home;
	return unless -d $home;
	my $conf = $home . '/.config/user-dirs.dirs';
	unless ( -e $conf and -r _ and ! -d _ ) {
		return $class->_default_thingy($wanted, $user);
	}

	# Slurp in the file.
	# This involves reading a little more of the file than we might
	# need, but keeps the handle open for less total time (I think)
	# NOTE: Since the file path is not provided by the user,
	# the two argument open is safe in this case.
	local *FILE;
	unless ( open(FILE, "<$conf") ) {
		warn "Error opening $conf for reading: $!\n";
		return;
	}
	my @buffer = <FILE>;
	close FILE or die "Unable to close $conf: $!";

	foreach my $line ( @buffer ) {
		# A chomp that is more resistant to accidental newline
		# problems caused by editing the file remotely from windows.
		$line =~ s/[\015\012]+\z//g;

		next if $line =~ m{^#};
		my($name, $value) = split m{=}, $line, 2;
		$name  =~ s/XDG_(.+?)_DIR/$1/;
		next if lc $name ne $wanted;
		$value =~ tr/"//d;
		$value =~ s/\$HOME/$home/g;
		return $value;
	}

	# Failed to find a value
	return undef;
}

sub _default_thingy {
	my ($class, $wanted, $user) = @_;

	my $conf = '/etc/xdg/user-dirs.defaults';
	return if ! -e $conf || ! -r _ || -d _;

	# Slurp in the file.
	# This involves reading a little more of the file than we might
	# need, but keeps the handle open for less total time (I think)
	# NOTE: Since the file path is not provided by the user,
	# the two argument open is safe in this case.
	local *FILE;
	unless ( open(FILE, "<$conf") ) {
		warn "Error opening $conf for reading: $!\n";
		return;
	}
	my @buffer = <FILE>;
	close FILE or die "Unable to close $conf: $!";

	my $home = defined($user)
		? $class->users_home($user)
		: $class->my_home;
	foreach my $line ( @buffer ) {
		# A chomp that is more resistant to accidental newline
		# problems caused by editing the file remotely from windows.
		$line =~ s/[\015\012]+\z//g;

		next if $line =~ m{^#};
		my($name, $value) = split m{=}, $line, 2;
		next if lc $name ne $wanted;
		return File::Spec->catdir( $home, $value );
	}

	return undef;
}

sub my_desktop   { shift->_my_thingy('desktop');   }
sub my_documents { shift->_my_thingy('documents'); }
sub my_music     { shift->_my_thingy('music');     }
sub my_pictures  { shift->_my_thingy('pictures');  }
sub my_videos    { shift->_my_thingy('videos');    }

sub my_data {
	$ENV{XDG_DATA_HOME}
	||
	File::Spec->catdir(shift->my_home, qw{ .local share });
}





#####################################################################
# General User Methods

sub users_desktop   { $_[0]->_my_thingy('desktop',   $_[1]); }
sub users_documents { $_[0]->_my_thingy('documents', $_[1]); }
sub users_music     { $_[0]->_my_thingy('music',     $_[1]); }
sub users_pictures  { $_[0]->_my_thingy('pictures',  $_[1]); }
sub users_videos    { $_[0]->_my_thingy('videos',    $_[1]); }

sub users_data {
	my ($class, $user) = @_;
	File::Spec->catdir($class->users_home($user), qw{ .local share });
}


1;

=pod

=head1 NAME

File::HomeDir::FreeDesktop - find your home and other directories, on unixes running free desktops

=head1 DESCRIPTION

This module provides implementations for determining common user
directories.  In normal usage this module will always be
used via L<File::HomeDir>.

=head1 SYNOPSIS

  use File::HomeDir;
  
  # Find directories for the current user
  $home    = File::HomeDir->my_home;        # /home/mylogin

  $desktop = File::HomeDir->my_desktop;
  $docs    = File::HomeDir->my_documents;
  $music   = File::HomeDir->my_music;
  $pics    = File::HomeDir->my_pictures;
  $videos  = File::HomeDir->my_videos;
  $data    = File::HomeDir->my_data;

