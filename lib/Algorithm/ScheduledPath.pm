=head1 NAME

Algorithm::ScheduledPath - Find scheduled paths in a directed graph

=cut

package Algorithm::ScheduledPath;

use 5.006;
use strict;
use warnings;

use Carp;

use Algorithm::ScheduledPath::Edge 0.32;
use Algorithm::ScheduledPath::Path 0.32;

our $VERSION = '0.32_01';
$VERSION = eval $VERSION;

=head1 DESCRIPTION

This module is designed to find scheduled paths between vertices in a
directed graph.  For scheduled paths, each edge has a I<time schedule>,
so they a path must contain edges with successivly later schedules.

In less technical parlance, this module lets you do things like take a
series of interconnected bus routes and determine a schedule of how to
get from point 'A' to point 'B' (noting any transfers in between).

=head2 Methods

=over

=item new

  $graph = Algorithm::ScheduledPath->new();

  $graph = Algorithm::ScheduledPath->new(
    Algorithm::ScheduledPath::Edge->new({
      path_id => 1, origin      => 'A', depart_time => 100,
                    destination => 'B', arrive_time => 200,
    }),
    Algorithm::ScheduledPath::Edge->new({
      path_id => 1, origin      => 'B', depart_time => 200,
                    destination => 'C', arrive_time => 300,
    }),
  );

Creates a new graph, and adds edges if they are specified.
(See L</add_edge> for more details.)

=cut

sub new {
  my $class = shift;
  my $graph = { };
  bless $graph, $class;
  if (@_) {
    $graph->add_edge(@_);
  }
  return $graph;
}

=item add_edge

  $graph->add_edge(
    Algorithm::ScheduledPath::Edge->new({
      id          =>   0, path_id => 1,
      origin      => 'C', depart_time => 300,
      destination => 'D', arrive_time => 400,
    })
  );

Adds an edge to the graph.  Arguments must be
C<Algorithm::ScheduledPath::Edge> objects.

See L<Algorithm::ScheduledPath::Edge> for more information.

=cut

sub add_edge {
  my $graph = shift;

  while (my $leg = shift) {

    croak "unexpected type",
      unless ($leg->isa("Algorithm::ScheduledPath::Edge"));

    croak "origin = destination",
      if ($leg->origin eq $leg->destination);

    croak "arrival time < departure time",
      if ($leg->travel_time < 0);

    $graph->{$leg->origin} = { },
      unless (exists $graph->{$leg->origin});

    
    $graph->{$leg->origin}->{$leg->destination} = [ ],
      unless (exists $graph->{$leg->origin}->{$leg->destination});

    # Warning: we intentionally do not check for duplicates.

    push @{ $graph->{$leg->origin}->{$leg->destination} }, $leg;
  }

  return $graph;
}

BEGIN {
  *add_leg = \&add_edge; # alias to maintain compatability w/v<0.32
}

=item find_routes

  $routes = $graph->find_routes( $origin, $dest );

  $routes = $graph->find_routes( $origin, $dest, $count );

  $routes = $graph->find_routes( $origin, $dest, $count, $earliest );

Returns an array reference of L<Algorithm::ScheduledPath::Path>
objects of any paths betweeb the C<$origin> and C<$dest>.  (C<$origin>
and C<$dest> are assumed to be strings.)  Results are sorted in the
earliest arrival time first.

C<$count> specifies the number of alternate branches to include (it
defaults to C<1>).

C<$earliest> is the earliest time value included in the routes.

=cut

sub find_routes {
  my $graph = shift;
  my ($origin, $dest, $connects, $depart, $trace) = @_;

  $connects      = 1, unless (defined $connects);

  $trace         = { $origin => 1, }, unless (defined $trace);
  my $trace_back = { %$trace };

  $depart      ||= 0; # we only return routes that depart after this time

  my @routes     = ( );

  my $sort = sub {
    if ($a eq $dest) {
      return -1;
    } elsif ($b eq $dest) {
      return 1;
    } else {
      return ($a cmp $b); # Note: assumes destinations str sorting
    }
  };

  if (exists $graph->{$origin}) {
    foreach my $next (sort $sort keys %{ $graph->{$origin} }) {

      $trace = $trace_back;

      # The algorithm is simple: given the origin vertex, we look at
      # all the edges that extend from it.  If they connect to the
      # destination vertex, we add them to the list.  For all other
      # vertices with a common edge to the origin, we check them
      # recursively to see if they have a common edge with the
      # destination (taking care not to follow previously covered
      # vertices).

      # We make sure to check the schedules for allowable transfer
      # times (that is, we don't continue on an earlier leg).  We also
      # limit the number of "connections" to speed up the algorithm.

      if ($next eq $dest) {

	push @routes,
	  map { Algorithm::ScheduledPath::Path->new($_) }
	  grep $_->depart_time >= $depart, @{ $graph->{$origin}->{$next} };
      }
      elsif (!exists $trace->{$next}) {

	$trace->{$next}++;

	my $head =
	  $graph->find_routes($origin, $next, $connects, $depart, $trace);

	if (@$head) {
	  my $earliest = $head->[0]->arrive_time;

	  my $tail =
	    $graph->find_routes($next, $dest, $connects, $earliest, $trace);

	  if (@$tail) {

	    foreach my $route (@$head) { # sort _by_arrive_time

	      # the "head" path could theorestically pass through our
	      # destination, so we ignore these

	      unless ($route->has_vertex($dest)) {

		# Warning: values are sorted by arrival time, and there
		# is nothing to favor continuing a leg on a route id!

		my @xfers = 
		  grep( ($route->arrive_time <= $_->depart_time),
			@$tail); #  

		if (@xfers) {
		  for (my $i=0; (($i<$connects) && ($i<@xfers)); $i++) {
		    my $path = Algorithm::ScheduledPath::Path->new(
		      $route, $xfers[$i] );

		    # We also reject paths that pass through the same
		    # vertex more than once

		    push @routes, $path,
		      unless ($path->has_cycle);
		    
		  }
		}
	      }
	    }
	  }
	}
      }
    }
    return [ sort _by_arrive_time @routes ];
  }
  else {
    return [ ];
  }

}

sub _by_arrive_time {
  $a->arrive_time <=> $b->arrive_time;
}


=back

=head1 CAVEATS

This module does not do any kind of sophisticated searching techniques
for finding paths or determining the most efficient schedule. It is a
hand-rolled recursive method that appears correct but I have not done
any proofs of the method.  The sorting techniques are certainly not
optimized.  It has not been tested on huge datasets.

=cut

# There may be a bug where bus routes double-back on themselves, in
# the form of A->B->C->D->C.  It seems to show up with displaying
# multiple possibilities.  It needs to be determined if this problem
# is because of the search function or because of a bug in the
# compression routine, if it can be reproduced at all.

=head1 AUTHOR

Robert Rothenberg <rrwo at cpan.org>

=head1 LICENSE

Copyright (c) 2004 Robert Rothenberg. All rights reserved.  This
program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

If you are looking for a generic (un)directed graph module, see the
L<Graph> package.  (This module does not make use of that package
intentionally.)

=cut


1;

__END__
