#!/usr/bin/perl

use Test::More tests => 18;
BEGIN {
  use_ok('Algorithm::ScheduledPath::Edge');
#  use_ok('Algorithm::ScheduledPath::Types');
};

sub stringlike {
  goto &Algorithm::ScheduledPath::Types::_stringlike;
}

sub numberlike {
  goto &Algorithm::ScheduledPath::Types::_numberlike;
}

ok(stringlike(undef));
ok(stringlike(''));
ok(stringlike(1234));
ok(stringlike(1234.56));
ok(stringlike('1234'));
ok(stringlike('1234.56'));
ok(stringlike('string'));
ok(!stringlike( [ ] ));
ok(!stringlike( { } ));

ok(numberlike(undef));
ok(numberlike(1234));
ok(numberlike(1234.56));
ok(numberlike(1234.56E7));
ok(numberlike('1234'));
ok(numberlike(-1234.56E7));
ok(!numberlike('A'));
ok(!numberlike('1234ABC'));
