use strict;
use Test::More 0.98;

use_ok $_ for qw(
    Parse::Debian::Watch
);

my $missing = undef;
eval {
     $missing = Parse::Debian::Watch->new();
};
is($missing, undef, "Missing path");

done_testing;

