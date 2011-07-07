use inc::Module::Install 1.01;
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
if ( $MacPerl::Version and $MacPerl::Version
	or $^O eq 'darwin' and _check_old_mac_os_x() ) {
	# Old Mac OS 9, or Mac OS X before Mac::SystemDirectory is supported.
	requires 'Mac::Files' => 0;

} elsif ( $^O eq 'darwin' ) {
	# Modern Max OS X and Darwin OSS releases for 32bit and 64bit
	requires 'Mac::SystemDirectory' => '0.04';

} elsif ( $^O eq 'MSWin32' ) {
	requires  'Win32' => '0.31';
}

WriteAll;

sub _check_old_mac_os_x {
	local $@;
	$Config{ptrsize} == 8 and return;
	return eval {
		require POSIX;
		my $release = ( POSIX::uname() )[2];
		my ( $major ) = split qr{ [.] }smx, $release;
		# 'old' means before darwin 8 = Mac OS 10.4 = Tiger
		$major < 8; 
	};
}
