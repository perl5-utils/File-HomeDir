package File::HomeDir;

# See POD at end for docs

use 5.005;
use strict;
use Carp       ();
use File::Spec ();

# Globals
use vars qw{$VERSION @ISA @EXPORT @EXPORT_OK $IMPLEMENTED_BY};
BEGIN {
	$VERSION = '0.10';

	# Inherit manually
	require Exporter;
	@ISA       = ( 'Exporter' );
	@EXPORT    = ( 'home'     );
	@EXPORT_OK = qw{
		my_home
		my_desktop
		my_documents
		my_local_data
		};

	# %~ doesn't need (and won't take) exporting, as it's a magic
	# symbol name that's always looked for in package 'main'.
}

# Don't do platform detection at compile-time
if ( $^O eq 'MSWin32' ) {
	$IMPLEMENTED_BY = 'File::HomeDir::Win32';
	require File::HomeDir::Win32;
} elsif ( $MacPerl::VERSION || $MacPerl::VERSION ) {
	$IMPLEMENTED_BY = 'File::HomeDir::Mac';
	require File::HomeDir::Mac;
} else {
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

sub my_local_data {
	$IMPLEMENTED_BY->my_local_data;
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
		# Get our homedir
		if ( ! defined $_[1] or ! length $_[1] ) {
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

File::HomeDir - Get home directory for yourself or other users

=head1 SYNOPSIS

  use File::HomeDir;
  print "My dir is ", home(), " and root's is ", home('root'), "\n";
  print "My dir is $~{''} and root's is $~{root}\n";
  # These both print the same thing, something like:
  #  "My dir is /home/user/mojo and root's is /"

=head1 DESCRIPTION

This module provides a function, C<home>, and also ties the
in-all-packages variable C<%~>.

=over

=item home()

Returns a filespec to this user's home directory.

=item home($user)

Returns a filespec to the home directory of the given user, or undef
if no such user.

Note that the argument to this must be a defined value, and mustn't be
a zero-length string, or a fatal error will result.

=item C<$~{$user}>

=item C<$~{username}>

=item C<"...$~{$user}...">

=item C<"...$~{username}...">

This calls C<home($user)> or C<home('username')> -- except that if you
ask for C<$~{some_user}> and there is no such user, a fatal error
results!

Note that this is especially useful in double-quotish strings, like:

     print "Jojo's .newsrc is ", -s "$~{jojo}/.newsrc", "b long!\n";
      # (helpfully dies if there is no user 'jojo')

If you want to avoid the fatal errors, first test the value of
C<home('jojo')>, which will return undef (instead of dying) in case of
there being no such user.

Note, however, that if the hash key is "" or undef (whether thru being
a literal "", or a scalar whose value is empty-string or undef), then
this returns zero-argument C<home()>, i.e., your home directory:

=item C<$~{""}>

=item C<$~{undef}>

=item C<"...$~{''}...">

These all return C<home()>, i.e., your home directory.

=back

If running under an OS that doesn't implement C<getpwid>, this library
tries to provide a sane return value for the no-argument C<home()>.
Under MacOS, for example, it tries returning the pathspec to the
desktop folder.  See source for full details.

Under OSs that don't implement C<getpwnam> (as C<home($user)> calls),
you will always get a failed lookup, just as if you'd tried to look up
the home dir for a nonexistent user on an OS that I<does> support
C<getpwnam>.

=head1 BUGS AND CAVEATS

* One-argument C<home($username)> is memoized.  Read the source if you
need it unmemoized.

* According to the fileio.c in one version of Emacs, MSWindows (NT?)
does have the concept of users having home directories, more or less.
But I don't know if MSWin ports of Perl allow accessing that with
C<getpwnam>.  I hear that it (currently) doesn't.

=cut

#What it says is, and I quote:
#
#|
#|#ifdef  WINDOWSNT
#|          /* DebPrint(("EMACS broken @-"__FILE__ ": %d\n", __LINE__)); */
#|          /*
#|           * Emacs wants to know the user's home directory...  This is set by
#|           * the user-manager, but how do I get that information from the
#|           * system?
#|           *
#|           * After a bit of hunting I discover that the user's home directroy
#|           * is stored at:  "HKEY_LOCAL_MACHINE\\security\\sam\\"
#|           * "domains\\account\\users\\<account-rid>\\v" in the registry...
#|           * Now I could pull it out but this location only contains local
#|           * accounts... so if you're logged on to some non-local domain this
#|           * may run into a security problem... i.e. I may not always be able
#|           * to read this information even for myself...
#|           *
#|           * What's here is a hack to make things work...
#|           */
#|
#|          newdir = (unsigned char *) egetenv ("HOME");
#|#else /* !WINDOWSNT */
#|          pw = (struct passwd *) getpwnam (o + 1);
#|          if (pw)
#|            {
#|              newdir = (unsigned char *) pw -> pw_dir;
#|#ifdef VMS
#|              nm = p + 1;       /* skip the terminator */
#|#else
#|              nm = p;
#|#endif                          /* VMS */
#|            }
#|#endif /* !WINDOWSNT */
#|

=pod

* This documentation gets garbled by some AIX manual formatters.
Consider C<perldoc -t File::HomeDir> instead.

=head1 COPYRIGHT

Copyright (c) 2000 Sean M. Burke. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Sean M. Burke C<sburke@cpan.org>

=cut
