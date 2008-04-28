#!/usr/bin/perl

# Compile-testing for File::HomeDir

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}
use File::Spec::Functions ':ALL';

use Test::More tests => 8;

# This module is destined for the core.
# Please do NOT use convenience modules
# use English; <-- don't do this

ok( $] > 5.005, 'Perl version is 5.005 or newer' );

use_ok( 'File::HomeDir::Driver'  );
use_ok( 'File::HomeDir'          );
use_ok( 'File::HomeDir::Unix'    );
use_ok( 'File::HomeDir::Darwin'  );
use_ok( 'File::HomeDir::Windows' );
use_ok( 'File::HomeDir::MacOS9'  );

ok( defined &home, 'Using File::HomeDir exports home()' );
