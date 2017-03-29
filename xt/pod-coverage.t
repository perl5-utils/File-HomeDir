#! perl

use strict;
use warnings;

use Test::More;
use Test::Pod::Coverage;
use Pod::Coverage;

all_pod_coverage_ok(
    {
        also_private => [
            qr/^(?:my|users)_(?:cache|config|home|desktop|documents|data|music|pictures|videos|download|publicshare|templates)+$/,
            qr/^[A-Z_]+$/
        ]
    }
);
