#!/usr/bin/perl

use Test::More tests => 53;
BEGIN {
  use_ok('Algorithm::ScheduledPath::Edge');
  use_ok('Algorithm::ScheduledPath::Path');
};

sub new_edge {
  my ($path_id, $orig, $o_time, $dest, $d_time) = @_;
  my $e = new Algorithm::ScheduledPath::Edge( {
    path_id     => $path_id,
    origin      => $orig, depart_time => $o_time,
    destination => $dest, arrive_time => $d_time,
  });
  ok( defined $e );
  ok( $e->isa("Algorithm::ScheduledPath::Edge") );
  return $e;
}

my $p = new Algorithm::ScheduledPath::Path();
ok(defined $p);
ok($p->isa("Algorithm::ScheduledPath::Path"));

for(my $i=1; $i<=4; $i++) {
  $p->add_edge( new_edge( 1+int($i/2), $i, (10*$i), $i+1, (10*$i)+9 ) );
  ok( $p->size == $i );
  ok( $p->first_edge->path_id == 1 );
  ok( $p->last_edge->path_id  == 1+int($i/2) );
  ok( $p->depart_time == 10 );
  ok( $p->arrive_time == ((10*$i)+9) );
  ok( $p->travel_time == ((10*($i-1))+9) );
  ok( !$p->has_cycle );
}

for(my $i=1; $i<=4; $i++) {
  ok( $p->has_vertex($i) );
}

ok( $p->compressed->size == 3 );
ok( $p->compressed->travel_time == $p->travel_time );
ok( $p->compressed->depart_time == $p->depart_time );
ok( $p->compressed->arrive_time == $p->arrive_time );

my $legs = $p->get_edges();
ok(@$legs == $p->size);

foreach my $leg (@$legs) {
  ok( $leg->isa("Algorithm::ScheduledPath::Edge") );
}
