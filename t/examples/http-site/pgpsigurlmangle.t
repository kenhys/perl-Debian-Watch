use strict;
use Test::More 0.98;
use Parse::Debian::Watch;

my $package = Parse::Debian::Watch->new(path => 't/examples/http-site/pgpsigurlmangle.txt');

is($package->version, 4, "detects d/watch version 4");

my $expected = ["s%$%.asc"];
is($package->pgpsigurlmangle, $expected, "detects d/watch version 4");

done_testing;
