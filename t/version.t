use strict;
use Test::More 0.98;
use Parse::Debian::Watch;

my $package = Parse::Debian::Watch->new(path => 't/version/empty.txt');
is($package->version, 0, "empty d/watch returns version 0");

my $package = Parse::Debian::Watch->new(path => 't/version/align-space.txt');
is($package->version, 4, "aligned d/watch version 4 is detected");

my $package = Parse::Debian::Watch->new(path => 't/version/heading-tab.txt');
is($package->version, 4, "heading tab d/watch version 4 is detected");

my $package = Parse::Debian::Watch->new(path => 't/version/no-space.txt');
is($package->version, 4, "no space d/watch version 4 is detected");

my $package = Parse::Debian::Watch->new(path => 't/version/trailing-spaces.txt');
is($package->version, 4, "traling spaces d/watch version 4 is detected");

done_testing;
