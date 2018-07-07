use strict;
use Test::More 0.98;
use Parse::Debian::Watch;

my $package = Parse::Debian::Watch->new(path => 't/bare/no_bare.txt');
is($package->bare, 0, "no bare");

my $package = Parse::Debian::Watch->new(path => 't/bare/bare.txt');
is($package->bare, 1, "bare");

done_testing;
