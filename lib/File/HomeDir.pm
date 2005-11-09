package File::HomeDir;

# See POD at end for docs

require 5;

use strict;
use Carp       ();
use File::Spec ();

# Globals
use vars qw{$VERSION @ISA @EXPORT %Cache};
BEGIN {
	$VERSION = '0.07';

	# Inherit manually
	require Exporter;
	@ISA    = ( 'Exporter' );
	@EXPORT = ( 'home' );
	# %~ doesn't need (and won't take) exporting, as it's a magic
	# symbol name that's always looked for in package 'main'.

	# Define the homedir cache
	%Cache = ();
}

# Create constants for the platforms in advance
# to improve the optimisation at compile-time.
### Use some variables twice to prevent warnings.
use constant MACPERL => $MacPerl::VERSION || $MacPerl::VERSION;
use constant WIN32   => $^O eq 'MSWin32';





#####################################################################
# Main Functions

# Process user may change, so don't cache
sub my_home () {
	# Try the obvious UNIX methods
	return $ENV{HOME}   if $ENV{HOME};
	return $ENV{LOGDIR} if $ENV{LOGDIR};

	# Handle Windows Normally
	if ( WIN32 ) {
		# Some Windows use something like $ENV{HOME}
		if ( $ENV{HOMEDRIVE} and $ENV{HOMEPATH} ) {
			return File::Spec->catpath(
				$ENV{HOMEDRIVE},
				$ENV{HOMEPATH},
				);
		}

		### MORE SANE METHODS TO GO HERE
	}

	# Or try other ways...
	# Use twice to avoid "only used once" warnings
	if ( MACPERL ) {
		local $SIG{"__DIE__"} = "";
		require Mac::Files;
		my $home = Mac::Files::FindFolder(
			Mac::Files::kOnSystemDisk,
			Mac::Files::kDesktopFolderType,
			);
		return $home if $home and -d $home;
	}

	### DESPERATION SETS IN

	# Light desperation on any platform
	{
		# On some platforms getpwuid dies if called at all
		local $SIG{'__DIE__'} = '';
		my $home = (getpwuid($<))[7];
		return $home if $home and -d $home;
	}

	# Extra desperate things to do on Windows.
	# Mostly, this just involves using the desktop,
	# and trying to find it in a variety of ways.
	# The desktop isn't a great place, but at least it is
	# _somewhere_ inside this user's profile.
	if ( WIN32 ) {
		# The most correct way to find the desktop
		SCOPE: {
			local $SIG{"__DIE__"} = "";
			require Win32::TieRegistry;
			my $folders = Win32::TieRegistry->new(
				'HKEY_CURRENT_USER/Software/Microsoft/Windows/CurrentVersion/Explorer/Shell Folders',
				{ Delimiter => '/' }
				);
			if ( $folders ) {
				my $home = $folders->GetValue("Desktop");
				return $home if $home and -d $home;
			}
		}

		# MSWindows sets WINDIR, MS WinNT sets USERPROFILE.
		foreach my $e ( 'USERPROFILE', 'WINDIR' ) {
			next unless $ENV{$e};
			my $home = File::Spec->catdir(
				$ENV{$e}, 'Desktop',
				);
			return $home if $home and -d $home;
		}

		# As a last resort, try some hard-wired values
		foreach my $home (
		"C:\\windows\\desktop", "C:/windows/desktop",
		"C:\\win95\\desktop",   "C:/win95/desktop",
		) {
			return $home if $home and -d $home;
		}
	}

	# Now we are completely out of options
	die "Can't find ~/";
}

# Find the home directory of an arbitrary user
sub home (;$) {
	# No params means my home
	if ( @_ == 0 ) {
		return my_home();
	}

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

	# Although we are converned about changing user, we aren't
	# concerned about users changing homedir WHILE the program is
	# running, so lets cache the homedir for named users.
	if ( $Cache{$name} ) {
		# Returned the cached dir
		return $Cache{$name};
	}

	SCOPE: {
		# On some platforms getpwnam dies if called at all
		local $SIG{'__DIE__'} = '';
		$Cache{$name} = (getpwnam($name))[7];
		if ( $Cache{$name} and -d $Cache{$name} ) {
			return $Cache{$name};
		}
	}

	# Out of options
	die "Can't find home for $name";
}





#####################################################################
# Tie-Based Interface

# Okay, things below this point get scary

CLASS: {
	# Make the class for the %~ tied hash:
	package File::HomeDir::TIE;

	use vars qw($singleton);
	BEGIN {
		# Make the singleton object.
		# (We don't use the hash for anything, though)
		$singleton = bless {};
	}

	sub TIEHASH { $singleton }

	sub FETCH {
		# Get our homedir
		if ( ! defined $_[1] or ! length $_[1] ) {
			return File::HomeDir::home();
		}

		# Get a named user's homedir
		my $home = &File::HomeDir::home($_[1]);
		unless ( defined $home ) {
			Carp::croak("No home dir found for user \"$_[1]\"");
		}
		return $home;
	}

	sub bad ($) {
		Carp::croak("You can't $_[0] with the %~ hash")
	}

	sub STORE    { bad('STORE')    }
	sub EXISTS   { bad('EXISTS')   }
	sub DELETE   { bad('DELETE')   }
	sub CLEAR    { bad('CLEAR')    }
	sub FIRSTKEY { bad('FIRSTKEY') }
	sub NEXTKEY  { bad('NEXTKEY')  }

	# For a more generic approach to this sort of thing, see Dominus's
	# class "Interpolation" in CPAN.
}

# Do the actual tie of the global %~ variable
tie %~, 'File::HomeDir::TIE';

1;

__END__

=pod

=head1 NAME

File::HomeDir -- get home directory for self or other users

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

Note that this is especially useful in doublequotish strings, like:

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

