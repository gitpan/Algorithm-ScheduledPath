#!/usr/bin/perl

use Test::More tests => 65;
use Test::Warn;

use warnings;

BEGIN {
  use_ok('Algorithm::ScheduledPath::Edge');
};

my $e = new Algorithm::ScheduledPath::Edge();
ok( defined $e);
ok( $e->isa("Algorithm::ScheduledPath::Edge") );

my $i = 0;
foreach my $method (qw(
  id path_id origin depart_time destination arrive_time data )) {
  ok($e->$method(++$i));
  ok($e->$method == $i);
}

my $f = $e->clone;
foreach my $method (qw(
  id path_id origin depart_time destination arrive_time data )) {
  ok(defined $f->$method);
  ok($e->$method eq $f->$method);
}

# # check that copying a reference gives a warning

# $f->data( { } );
# ok( ref($f->data) ne "" );

# warning_like { my $g = $f->copy; }
#   qr/Warning: copied data attribute is a reference/;

ok($e->travel_time == ($e->arrive_time - $e->depart_time));
ok($e->travel_time == 2);

# check that changing original does not affect copy

$i = 100;
foreach my $method (qw(
  id path_id origin depart_time destination arrive_time data )) {
  ok($e->$method(++$i));
  ok($e->$method ne $f->$method);
}

$e = Algorithm::ScheduledPath::Edge->new(
  id => 1, path_id => 2, origin => 3, depart_time => 4,
  destination => 5, arrive_time => 6, data => 7,
);
ok( defined $e);
ok( $e->isa("Algorithm::ScheduledPath::Edge") );

$i = 0;
foreach my $method (qw(
  id path_id origin depart_time destination arrive_time data )) {
  ok($e->$method(++$i));
  ok($e->$method == $i);
}

ok($e->travel_time == ($e->arrive_time - $e->depart_time));
ok($e->travel_time == 2);
