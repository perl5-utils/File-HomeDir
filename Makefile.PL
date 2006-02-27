use inc::Module::Install;

# For a Module::Install script, this is actually a quite
# complex installer, as it needs to pull in different
# dependencies on different platforms.

name           'File-HomeDir';
all_from       'lib/File/HomeDir.pm';
requires       'File::Spec' => '0.80';
build_requires 'Test::More' => '0.47';

# Dependencies for specific platforms
### Use variable twice to avoid a warning.
if ( $MacPerl::Version and $MacPerl::Version ) {
    requires   'Mac::Files' => 0;
}
if ( $^O eq 'MSWin32' ) {
    requires   'Win32API::Registry' => 0;
    requires   'Win32::TieRegistry' => 0;
}

auto_install;
WriteAll;
