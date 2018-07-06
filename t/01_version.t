use strict;
use Test::More 0.98;

$package = Parse::Debian::Watch->new({path => 't/version/empty.txt'});
is($package->version, 1, "empty d/watch returns version 1");

done_testing;
