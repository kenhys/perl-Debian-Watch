use strict;
use Test::More 0.98;
use Parse::Debian::Watch;

my $package = Parse::Debian::Watch->new(path => 't/examples/http-site/pgpsigurlmangle-decompress.txt');

is($package->version, 4, "detects d/watch version 4");
is($package->pgpmode, "mangle", "detects pgpmode: mangle");
is($package->decompress, 1, "detects decompress");

my $expected = ["s%(?i)\\.(?:tar\\.xz|tar\\.bz2|tar\\.gz|zip|tgz|tbz|txz)\$%.asc%"];
is_deeply($package->pgpsigurlmangle, $expected, "detects pgpsigurlmangle");

done_testing;
