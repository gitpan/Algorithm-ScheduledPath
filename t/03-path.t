#!/usr/bin/perl

use Test::More tests => 127;
use Test::Exception;
use Test::Warn;

use warnings;

BEGIN {
  use_ok('Algorithm::ScheduledPath::Edge');
  use_ok('Algorithm::ScheduledPath::Path');
};


# Test various types of constructors and add_edge calls

my ($x,$y);
$x = Algorithm::ScheduledPath::Path->new( );
ok( defined $x );
ok( $x->isa("Algorithm::ScheduledPath::Path") );
ok( $x->size == 0 );

$x = Algorithm::ScheduledPath::Path->new( {
  path_id => 1, origin => 'A', destination => 'B',
  depart_time => 0, arrive_time => 0, } );
ok( defined $x );
ok( $x->isa("Algorithm::ScheduledPath::Path") );
ok( $x->size == 1 );

$x = Algorithm::ScheduledPath::Path->new(
  Algorithm::ScheduledPath::Edge->new(
  path_id => 1, origin => 'A', destination => 'B',
  depart_time => 0, arrive_time => 0, ) );
ok( defined $x );
ok( $x->isa("Algorithm::ScheduledPath::Path") );
ok( $x->size == 1 );

$y = Algorithm::ScheduledPath::Path->new( $x );
ok( defined $y );
ok( $y->isa("Algorithm::ScheduledPath::Path") );
ok( $y->size == 1 );

dies_ok {
  $y->add_edge( 'something' );
}, qr/expected Edge or Path/;

#

sub new_edge {
  my ($path_id, $orig, $o_time, $dest, $d_time) = @_;
  my $e = new Algorithm::ScheduledPath::Edge(
    path_id     => $path_id,
    origin      => $orig, depart_time => $o_time,
    destination => $dest, arrive_time => $d_time,
  );
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

  throws_ok {
    $p->add_edge( new_edge( 100+int($i/2), $i+100, (10*$i), $i, (10*$i)+9 ) );
  } qr/unconnected path/;
  ok($p->size == $i);

  throws_ok {
    $p->add_edge( new_edge( 100+int($i/2), $i+1, (10*$i)+100, $i, (10*$i) ) );
  } qr/depart_time \> arrive_time/;
  ok($p->size == $i);
}

for(my $i=1; $i<=4; $i++) {
  ok( $p->has_vertex($i) );
}

ok( $p->compressed->size == 3 );
ok( $p->compressed->travel_time == $p->travel_time );
ok( $p->compressed->depart_time == $p->depart_time );
ok( $p->compressed->arrive_time == $p->arrive_time );

# my $q = new Algorithm::ScheduledPath::Path(
#   { path_id => 0, origin => 'A', depart_time => 0,
#     destination => 'B', arrive_time => 0, },
#   { path_id => 1, origin => 'B', depart_time => 0,
#     destination => 'C', arrive_time => 0, },
#   { path_id => 1, origin => 'C', depart_time => 0,
#     destination => 'D', arrive_time => 0, data => 'foo', },
# );

# warning_like { $q->compressed; }
#   qr/Warning: data attribute will not be copied/;


my $legs = $p->get_edges();
ok(@$legs == $p->size);

foreach my $leg (@$legs) {
  ok( $leg->isa("Algorithm::ScheduledPath::Edge") );
}

my $c = $p->clone;
my $clegs = $c->get_edges;
ok(@$legs == @$clegs);
ok($p->size == $c->size);
ok(@$clegs == $c->size);

foreach my $i (0..($p->size-1)) {
  foreach my $method (qw( id path_id origin depart_time destination arrive_time )) {
    ok( ($legs->[$i]->$method||'') eq ($clegs->[$i]->$method||'') );
  }
}

ok($c->destination eq $p->destination);
$p->last_edge->destination('ZAZAZ');
ok($c->destination ne $p->destination);

