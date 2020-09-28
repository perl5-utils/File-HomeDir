#!perl

use strict;
use warnings;

## in a separate test file
use Test::More;

BEGIN
{
    $] >= 5.008 or plan skip_all => "Test::Spelling requires perl 5.8";
}
use Test::Spelling;

add_stopwords(<DATA>);
all_pod_files_spelling_ok();

__END__
CGI
FreeDesktop
GetFolderPath
Jens
Quelin
Rehsack
Steneker
TODO
UNC
my_data
my_desktop
my_documents
my_home
my_music
my_pictures
my_videos
org
stat
users_data
users_desktop
users_documents
users_home
