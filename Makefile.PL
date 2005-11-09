require 5;
use strict;
use inc::Module::Install;

# For a Module::Install script, this is actually a quite
# complex installer, as it needs to pull in different
# dependencies on different platforms.

name           ( 'File-HomeDir'                  );
abstract       ( 'Get the home directory for ourself and other users' );
author         ( 'Adam Kennedy <cpan@ali.as>'    );
version_from   ( 'lib/File/HomeDir.pm'           );
license        ( 'perl'                          );
requires       ( 'perl'               => '5.004' );
requires       ( 'File::Spec'         => '0.80'  );
build_requires ( 'Test::More'         => '0.47'  );

# Dependencies for specific platforms
if ( $MacPerl::Version and $MacPerl::Version ) {
    requires   ( 'Mac::Files'         => 0       );
}
if ( $^O eq 'MXWin32' ) {
    requires   ( 'Win32::TieRegistry' => 0       );
}

auto_install ();
&WriteAll;
