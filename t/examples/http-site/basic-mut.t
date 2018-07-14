use strict;
use Test::More 0.98;
use Parse::Debian::Watch;

my $package = Parse::Debian::Watch->new(path => 't/examples/http-site/basic-mut.txt');

is($package->version, 4, "detects d/watch version 4");
is($package->pgpmode, "mangle", "detects pgpmode");
my $expected = [
   's%$%.sig%'
]
is_deeply($package->pgpsigurlmangle, $expected, "detects pgpsigurlmangle");

done_testing;
