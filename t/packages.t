use strict;
use Test::More 0.98;
use Parse::Debian::Watch;

my $name = "fonts-sawarabi-mincho";

my $package = Parse::Debian::Watch->new(path => 't/packages/fonts-sawarabi-mincho.txt');
is($package->version, 4, "detects $name version");

my $expected = ["s/-beta/~beta/", "s/-rc/~rc/", "s/-preview/~preview/"];
is_deeply($package->uversionmangle, $expected, "detects $name uversionmangle");

$expected = ["s%<osdn:file url=\"([^<]*)</osdn:file>%<a href=\"\$1\">\$1</a>%g"];
is_deeply($package->pagemangle, $expected, "detects $name pagemangle");

$expected = ["s%projects/sawarabi-fonts/downloads%frs/redir\\\.php?m=iij&f=sawarabi-fonts%g", "s/xz\\//xz/"];
is_deeply($package->downloadurlmangle, $expected, "detects $name downloadurlmangle");

done_testing;
