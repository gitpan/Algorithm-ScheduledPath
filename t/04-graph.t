#!/usr/bin/perl

use Test::More tests => 13;
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
    destination => 'B', arrive_time =>  10,
  }),
)->add_edge(
  new Algorithm::ScheduledPath::Edge({
    path_id     =>   2,
    origin      => 'B', depart_time =>  11,
    destination => 'C', arrive_time =>  20,
  }),
)->add_edge(
  new Algorithm::ScheduledPath::Edge({
    path_id     =>   3,
    origin      => 'C', depart_time =>  21,
    destination => 'A', arrive_time =>  30,
  }),
)->add_edge(
  new Algorithm::ScheduledPath::Edge({
    path_id     =>   4,
    origin      => 'A', depart_time =>   5,
    destination => 'C', arrive_time =>  15,
  }),
)->add_edge(
  new Algorithm::ScheduledPath::Edge({
    path_id     =>   4,
    origin      => 'C', depart_time =>  16,
    destination => 'D', arrive_time =>  20,
  }),
)->add_edge(
  new Algorithm::ScheduledPath::Edge({
    path_id     =>   1,
    origin      => 'B', depart_time =>  11,
    destination => 'D', arrive_time =>  20,
  }),
)->add_edge(
  {
    path_id     =>   1,
    origin      => 'D', depart_time =>  21,
    destination => 'C', arrive_time =>  25,
  },
);

my $p = $g->find_paths('A', 'C', { connects => 1 });
ok( @$p == 2);

# use YAML 'Dump'; print Dump($p);

for( my $i=1; $i<@$p; $i++) {
  ok( $p->[$i]->arrive_time > $p->[$i-1]->arrive_time );
}

$p = $g->find_paths('A', 'C', { alternates => 2 }); 
ok( @$p == 3);

for( my $i=1; $i<@$p; $i++) {
  ok( $p->[$i]->arrive_time > $p->[$i-1]->arrive_time );
}

$p = $g->find_paths('A', 'C', { alternates => 2, earliest => 0 }); 
ok( @$p == 3);

for( my $i=1; $i<@$p; $i++) {
  ok( $p->[$i]->arrive_time > $p->[$i-1]->arrive_time );
}

# use YAML 'Dump';
# print STDERR Dump($p);
