=head1 NAME

Algorithm::ScheduledPath - Find scheduled paths in a directed graph

=cut

package Algorithm::ScheduledPath;

use 5.006;
use strict;
use warnings;

use Carp;

use Algorithm::ScheduledPath::Edge 0.40;
use Algorithm::ScheduledPath::Path 0.40;

our $VERSION = '0.40_01';
$VERSION = eval $VERSION;

=head1 DESCRIPTION

This module is designed to find scheduled paths between vertices in a
directed graph.  For scheduled paths, each edge has a I<time
schedule>, so they a path must contain edges with successivly later
schedules.  It will not return cyclic paths (paths which pass through
a vertex more than once).

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

    if (ref($leg) eq 'HASH') {
      $leg = Algorithm::ScheduledPath::Edge->new($leg);
    }

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


=item find_paths

  $routes = $graph->find_paths( $origin, $dest );

  $routes = $graph->find_paths( $origin, $dest, \%options );

Returns an array reference of L<Algorithm::ScheduledPath::Path>
objects of any paths between the C<$origin> and C<$dest>.  (C<$origin>
and C<$dest> are assumed to be strings.)  Results are sorted in the
earliest arrival time first.

The following options are understood:

=over

=item alternates

Specifies the number of alternate branches to include (defaults to C<1>).

=item earliest

The earliest time value included in the routes (defaults to C<0>).

=back

=cut

sub find_paths {
  my $graph = shift;
  my ($origin, $dest, $options, $trace) = @_;

  local ($_);

  $options     ||= { };
  $options->{alternates} = 1, unless (defined $options->{alternates});
  $options->{earliest}   = 0, unless (defined $options->{earliest});

  $trace         = { $origin => 1, }, unless (defined $trace);
  my $trace_back = { %$trace };

  my @routes     = ( );

  my $sort = ($options->{numeric}) ? sub {
    if ($a == $dest) {
      return -1;
    } elsif ($b == $dest) {
      return 1;
    } else {
      return ($a <=> $b); # Note: assumes destinations str sorting
    }
  } : sub {
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

      # We also make sure to reject paths which are cyclic.

      if ($next eq $dest) {

	push @routes,
	  map { Algorithm::ScheduledPath::Path->new($_) }
	  grep $_->depart_time >= $options->{earliest},
	    @{ $graph->{$origin}->{$next} };
      }
      elsif (!exists $trace->{$next}) {

	$trace->{$next}++;

	my @head = grep(
          !($_->has_vertex($dest)||$_->has_cycle),
	  @{ $graph->find_paths($origin, $next, $options, $trace) }
        );

	if (@head) {

	  my $subopts  = { %$options, earliest => $head[0]->arrive_time, };

	  my @tail = grep(
            (!$_->has_cycle),
	    @{ $graph->find_paths($next, $dest, $subopts, $trace) }
          );

	  if (@tail) {

	    foreach my $route (@head) {

	      # Warning: values are sorted by arrival time, and there
	      # is nothing to favor continuing a leg on a route id!

	      my @xfers = 
		grep( ($route->arrive_time <= $_->depart_time),
		      @tail
		    );

	      if (@xfers) {
		for (my $i=0; (($i<$options->{alternates}) &&
			       ($i<@xfers)); $i++) {
		  my $path = Algorithm::ScheduledPath::Path->new(
		       $route, $xfers[$i] );

		  if ($route->destination ne $xfers[$i]->origin) {
		    croak "Something is wrong: unconnected path";
		  }

		  # We also reject paths that pass through the same
		  # vertex more than once (a possibility when we
		  # concatenate two paths).

		  push @routes, $path,
		    unless ($path->has_cycle);
		    
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
