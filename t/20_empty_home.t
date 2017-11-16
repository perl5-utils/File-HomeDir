#!/usr/bin/perl

use strict;

BEGIN {
	$|         = 1;
	$^W        = 1;
	$ENV{HOME} = '';
}

use Test::More;
use File::HomeDir;

plan( tests => 1 );
my $home = ( getpwuid($<) )[7];
is scalar File::HomeDir->my_home, $home, 'my_home found';
