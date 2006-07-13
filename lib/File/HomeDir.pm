package File::HomeDir;

# See POD at end for docs

use 5.005;
use strict;
use Carp       ();
use File::Spec ();

# Globals
use vars qw{$VERSION @ISA @EXPORT @EXPORT_OK $IMPLEMENTED_BY};
BEGIN {
	$VERSION = '0.60_02';

	# Inherit manually
	require Exporter;
	@ISA       = ( 'Exporter' );
	@EXPORT    = ( 'home'     );
	@EXPORT_OK = qw{
		home
		my_home
		my_desktop
		my_documents
		my_data
		};

	# %~ doesn't need (and won't take) exporting, as it's a magic
	# symbol name that's always looked for in package 'main'.
}

# Don't do platform detection at compile-time
if ( $^O eq 'MSWin32' ) {
	$IMPLEMENTED_BY = 'File::HomeDir::Windows';
	require File::HomeDir::Windows;
} elsif ( $^O eq 'darwin' ) {
	$IMPLEMENTED_BY = 'File::HomeDir::Darwin';
	require File::HomeDir::Darwin;
} elsif ( $^O eq 'MacOS' ) {
	$IMPLEMENTED_BY = 'File::HomeDir::MacOS9';
	require File::HomeDir::MacOS9;
} else {
	# Default to Unix semantics
	$IMPLEMENTED_BY = 'File::HomeDir::Unix';
	require File::HomeDir::Unix;
}





#####################################################################
# Current User Methods

sub my_home {
	$IMPLEMENTED_BY->my_home;
}

sub my_desktop {
	$IMPLEMENTED_BY->my_desktop;
}

sub my_documents {
	$IMPLEMENTED_BY->my_documents;
}

sub my_data {
	$IMPLEMENTED_BY->my_data;
}





#####################################################################
# General User Methods

# Find the home directory of an arbitrary user
sub home (;$) {
	# Allow to be called as a method
	if ( $_[0] and $_[0] eq 'File::HomeDir' ) {
		shift();
	}

	# No params means my home
	return my_home() unless @_;

	# Check the param
	my $name = shift;
	if ( ! defined $name ) {
		Carp::croak("Can't use undef as a username");
	}
	if ( ! length $name ) {
		Carp::croak("Can't use empty-string (\"\") as a username");
	}

	# A dot also means my home
	### Is this meant to mean File::Spec->curdir?
	if ( $name eq '.' ) {
		return my_home();
	}

	# Now hand off to the implementor
	$IMPLEMENTED_BY->users_home($name);
}





#####################################################################
# Tie-Based Interface

# Okay, things below this point get scary

CLASS: {
	# Make the class for the %~ tied hash:
	package File::HomeDir::TIE;

	# Make the singleton object.
	# (We don't use the hash for anything, though)
	### THEN WHY MAKE IT???
	my $SINGLETON = bless {};

	sub TIEHASH { $SINGLETON }

	sub FETCH {
		# Catch a bad username
		unless ( defined $_[1] ) {
			Carp::croak("Can't use undef as a username");
		}

		# Get our homedir
		unless ( length $_[1] ) {
			return File::HomeDir::my_home();
		}

		# Get a named user's homedir
		return File::HomeDir::home($_[1]);
	}

	sub STORE    { _bad('STORE')    }
	sub EXISTS   { _bad('EXISTS')   }
	sub DELETE   { _bad('DELETE')   }
	sub CLEAR    { _bad('CLEAR')    }
	sub FIRSTKEY { _bad('FIRSTKEY') }
	sub NEXTKEY  { _bad('NEXTKEY')  }

	sub _bad ($) {
		Carp::croak("You can't $_[0] with the %~ hash")
	}
}

# Do the actual tie of the global %~ variable
tie %~, 'File::HomeDir::TIE';

1;

__END__

=pod

=head1 NAME

File::HomeDir - Get the home directory for yourself or other users

=head1 SYNOPSIS

  use File::HomeDir;
  
  # Modern Interface (Current User)
  $home = File::HomeDir->my_home;
  $docs = File::HomeDir->my_documents;
  $data = File::HomeDir->my_data;
  
  # Modern Interface (Other Users)
  $home = File::HomeDir->users_home('foo');
  $docs = File::HomeDir->users_documents('foo');
  $data = File::HomeDir->users_data('foo');
  
  # Legacy Interfaces
  print "My dir is ", home(), " and root's is ", home('root'), "\n";
  print "My dir is $~{''} and root's is $~{root}\n";
  # These both print the same thing, something like:
  #  "My dir is /home/user/mojo and root's is /"

=head1 DESCRIPTION

B<File::HomeDir> is a module for dealing with issues relating to the
location of directories for various purposes that are "owned" by a user,
and to solve these problems consistently across a wide variety of
platforms.

This module provides two main interfaces.

The first is a modern L<File::Spec>-style interface with a consistent
OO API and different implementation modules to support various
platforms, and the second is a legacy interface from version 0.07 that
exported a home() function by default and tied the %~ variable.

=head2 Platform Neutrality

In the Unix world, many different types of data can be mixed together
in your home directory.  On some other platforms, seperate directories
are allocated for different types of data.

When writing applications, you should try to use the most specific
method you can. User documents should be saved in C<my_documents>,
data to support an application should go in C<my_data>.

On platforms that do not make this distinction, all these methods will
harmlessly degrade to the main home directory, but on platforms that
care B<File::HomeDir> will Do The Right Thing(tm).

=head1 METHODS

Two types of methods are provided. The C<my_method> series of methods for
finding resources for the current user, and the C<users_method> (read as
"user's method") series for finding resources for arbitrary users.

This split is necesary, as on many platforms it is MUCH easier to find
information about the current user compared to other users.

All methods via a C<-d> test that the directory actually exists before
returning. However, because in some cases, certain platforms may not
support the concept of home directories at all, a method may return
C<undef> (both in scalar and list context) to indicate that there is
no matching directory on the system. But anything returned can be
trusted to actually exist.

=head2 my_home

The C<my_home> takes no arguments and returns the main home/profile
directory for the current user.

Returns the directory path as a string, C<undef> if the current user
does not have a home direcotry, or dies on error.

=head2 my_documents

The C<my_documents> takes no arguments and returns the directory for
the current user where the user's documents are stored.

Returns the directory path as a string, C<undef> if the current user
does not have a documents directory, or dies on error.

=head2 my_data

The C<my_data> takes no arguments and returns the directory where
local applications should stored their internal data for the current
user.

Generally an application would create a subdirectory such as C<.foo>,
beneath this directory, and store its data there. By creating your
directory this way, you get an accurate result on the maximum number
of platforms.

For example, on Unix you get C<~/.foo> and on Win32 you get
C<~/Local Settings/Application Data/.foo>

Returns the directory path as a string, C<undef> if the current user
does not have a data directory, or dies on error.

=head2 users_home

  $home = File::HomeDir->users_home('foo');

The C<users_home> method takes a single param and is used to locate the
parent home/profile directory for an identified user on the system.

While most of the time this identifier would be some form of user name,
it is permitted to vary per-platform to support user ids or UUIDs as
applicable for that platform.

Returns the directory path as a string, C<undef> if that user
does not have a home directory, or dies on error.

=head2 users_documents

  $docs = File::HomeDir->users_documents('foo');

Returns the directory path as a string, C<undef> if that user
does not have a documents directory, or dies on error.

=head2 users_data

Returns the directory path as a string, C<undef> if that user
does not have a data directory, or dies on error.

=head1 FUNCTIONS

=head2 home

  use File::HomeDir;
  $home = home();
  $home = home('foo');
  $home = File::HomeDir::home();
  $home = File::HomeDir::home('foo');

The C<home> function is exported by default and is provided for
compatibility with legacy applications. In new applications, you should
use the newer method-based interface above.

Returns the directory path to a named user's home/profile directory.

If provided no param, returns the directory path to the current user's
home/profile directory.

=head1 TIED INTERFACE

=head2 %~

  $home = $~{""};
  $home = $~{undef};
  $home = $~{$user};
  $home = $~{username};
  print "... $~{''} ...";
  print "... $~{$user} ...";
  print "... $~{username} ...";

This calls C<home($user)> or C<home('username')> -- except that if you
ask for C<$~{some_user}> and there is no such user, it will die.

Note that this is especially useful in double-quotish strings, like:

     print "Jojo's .newsrc is ", -s "$~{jojo}/.newsrc", "b long!\n";
      # (helpfully dies if there is no user 'jojo')

If you want to avoid the fatal errors, first test the value of
C<home('jojo')>, which will return undef (instead of dying) in case of
there being no such user.

Note, however, that if the hash key is "" or undef (whether thru being
a literal "", or a scalar whose value is empty-string or undef), then
this returns zero-argument C<home()>, i.e., your home directory:

=head1 TO DO

- Become generally clearer on situations in which a user might not
have a particular resource.

- Add support for the root Mac user (requested by JKEENAN).

- Add support for my_desktop (requested by RRWO)

- Add support for my_music (requested by MIYAGAWA)

- Merge remaining edge case code in File::HomeDir::Win32

- Add more granularity to Unix, and add support to VMS and other
esoteric platforms, so we can consider going core.

Anyone wishing to add support for the above are welcome to get an account
to my SVN and add it directly.

=head1 SUPPORT

Bugs should be always be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=File-HomeDir>

For other issues, or commercial enhancement or support, contact the author.

=head1 AUTHORS

Adam Kennedy E<lt>cpan@ali.asE<gt>

Original implementation by:

Sean M. Burke C<sburke@cpan.org>

=head1 SEE ALSO

L<File::ShareDir>, L<File::HomeDir::Win32> (legacy)

=head1 COPYRIGHT

Copyright 2005, 2006 Adam Kennedy. All rights reserved.

Some parts copyright 2000 Sean M. Burke. All rights reserved.

Some parts copyright 2006 Chris Nandor. All rights reserved.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
