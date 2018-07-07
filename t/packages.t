use strict;
use Test::More 0.98;
use Parse::Debian::Watch;

my $package = Parse::Debian::Watch->new(path => 't/packages/fonts-sawarabi-mincho.txt');
is($package->version, 4, "d/watch version must be 4");

done_testing;
