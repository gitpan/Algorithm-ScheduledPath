#!/usr/bin/perl

# TODO: It seems difficult to determine the exact conditions where a
# cycle can be generated, so this test is ineffective against testing
# for bug #8248.

use Test::More tests => 7;
BEGIN {
  use_ok('Algorithm::ScheduledPath::Edge');
  use_ok('Algorithm::ScheduledPath::Path');
  use_ok('Algorithm::ScheduledPath');
};

my $g = new Algorithm::ScheduledPath();
ok(defined $g);
ok($g->isa("Algorithm::ScheduledPath"));

$g->add_edge(
  new Algorithm::ScheduledPath::Edge({
    path_id     =>   1,
    origin      => 'A', depart_time =>   0,
    destination => 'B', arrive_time =>   0,
  }),
)->add_edge(
  new Algorithm::ScheduledPath::Edge({
    path_id     =>   2,
    origin      => 'B', depart_time =>   0,
    destination => 'C', arrive_time =>   0,
  }),
)->add_edge(
  new Algorithm::ScheduledPath::Edge({
    path_id     =>   3,
    origin      => 'C', depart_time =>   0,
    destination => 'B', arrive_time =>   0,
  }),
)->add_edge(
  new Algorithm::ScheduledPath::Edge({
    path_id     =>   4,
    origin      => 'C', depart_time =>   0,
    destination => 'D', arrive_time =>   0,
  }),
);

my $p = $g->find_paths('A', 'D', { alternates => 10 });

# use YAML 'Dump';
# print STDERR Dump($p);

ok(@$p == 1);

foreach my $e (@$p) {
  ok(!$e->has_cycle);
}


