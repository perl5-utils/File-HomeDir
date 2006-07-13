use inc::Module::Install;

name           'File-HomeDir';
all_from       'lib/File/HomeDir.pm';
requires       'Carp'              => 0;
requires       'Cwd'               => '3.13';
requires       'File::Spec'        => '3.13';
build_requires 'English'           => 0;
build_requires 'Test::More'        => '0.47';
build_requires 'ExtUtils::Install' => '1.39';

# Dependencies for specific platforms
### Use variable twice to avoid a warning
if ( $MacPerl::Version and $MacPerl::Version ) {
	# Old Mac OS 9
	requires 'Mac::Files'         => 0;
}
if ( $^O eq 'darwin' ) {
	requires 'Mac::Files'         => '1.09';
}
if ( $^O eq 'MSWin32' ) {
	requires 'Win32API::Registry' => '0.27';
	requires 'Win32::TieRegistry' => '0.25';
}

WriteAll;
