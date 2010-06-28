use inc::Module::Install 1.00;
use Config;

all_from      'lib/File/HomeDir.pm';
requires      'Carp'        => 0;
requires      'Cwd'         => $^O eq 'darwin' ? '3' : '3.12';
requires      'File::Spec'  => $^O eq 'darwin' ? '3' : '3.12';
requires      'File::Path'  => '2.01';
requires      'File::Temp'  => '0.19';
requires      'File::Which' => '0.05';
test_requires 'Test::More'  => '0.47';

# Dependencies for specific platforms
### Use variable twice to avoid a warning
if ( $MacPerl::Version and $MacPerl::Version ) {
	# Old Mac OS 9
	requires 'Mac::Files'  => 0;

} elsif ( $^O eq 'darwin' && $Config{ptrsize} != 8 ) {
	# Modern Max OS X but only for 32-bit bit
	requires 'Mac::Carbon' => '0.77';
	requires 'Mac::Files'  => '1.09';

} elsif ( $^O eq 'MSWin32' ) {
	requires  'Win32'      => '0.31';
}

WriteAll;
