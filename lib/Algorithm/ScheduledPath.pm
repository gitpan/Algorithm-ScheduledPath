=head1 NAME

Algorithm::ScheduledPath - Find scheduled paths in a directed graph

=head1 REQUIREMENTS

The following non-standard modules are used:

  Carp::Assert
  Class::Meta
  Scalar::Util

=cut

package Algorithm::ScheduledPath;

use 5.006;
use strict;
use warnings::register;

use Carp;
use Carp::Assert;

use Algorithm::ScheduledPath::Edge 0.41; # uses Class::Meta
use Algorithm::ScheduledPath::Path 0.41;

our $VERSION = '0.41_02';
$VERSION = eval $VERSION;

=head1 SYNOPSIS

  use Algorithm::ScheduledPath;
  use Algorithm::ScheduledPath::Path;

  $graph = new Algorithm::ScheduledPath();

  $graph->add_edge(
    {
      path_id     => 'R',
      origin      => 'A', depart_time =>   1,
      destination => 'B', arrive_time =>   4,
    },
    {
      path_id     => 'R',
      origin      => 'B', depart_time =>   5,
      destination => 'C', arrive_time =>   9,
    },
    {
      path_id     => 'D',
      origin      => 'A', depart_time =>   2,
      destination => 'C', arrive_time =>   7,
    }
  );

  my $paths = $graph->find_paths('A', 'C');

  foreach my $path (@$paths) {
    print join(" ", map { $path->$_ } (qw(
      origin depart_time destination arrive_time ))), "\n";
  }

  # Outputs the following:
  #  A 2 C 7
  #  A 1 C 9

=head1 DESCRIPTION

This module is designed to find scheduled paths between vertices in a
directed graph.  For scheduled paths, each edge has a I<time
schedule>, so that a path must contain edges with successivly later
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
    {
      path_id => 1, origin      => 'A', depart_time => 100,
                    destination => 'B', arrive_time => 200,
    },
    {
      path_id => 1, origin      => 'B', depart_time => 200,
                    destination => 'C', arrive_time => 300,
    },
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

  $graph->add_edge( {
      id          =>   0, path_id => 1,
      origin      => 'C', depart_time => 300,
      destination => 'D', arrive_time => 400,
    }
  );

Adds edges to the graph.  Arguments must either be hash references or 
C<Algorithm::ScheduledPath::Edge> objects.

See L<Algorithm::ScheduledPath::Edge> for more information.

=cut

sub add_edge {
  my $graph = shift;

  while (my $leg = shift) {

    if (ref($leg) eq 'HASH') {
      $leg = Algorithm::ScheduledPath::Edge->new(%$leg);
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
and C<$dest> are assumed to be strings.)

Results are sorted by the earliest arrival time and then by the
shorted travel time.

The following options are understood:

=over

=item alternates

Specifies the number of alternate branches to include (defaults to
C<1>) for a path.

=item earliest

The earliest departure time value included in the routes (defaults to
C<0>).

If edges have negative departure and arrival times, then earliest must
be defined.

=item latest

The latest arrival time value included in the routes.

=item max_time

The maximum travel time a route may have.

=item callback

Define a callback routine to evaluate a path.  If the routine returns
a true value, the path is accepted; otherwise it is rejected.

The callback is passed three values:

=over

=item $path

This is a L<Algorithm::ScheduledPath::Path> object which contains the
path to be filtered.

=item $options

This contains the options passed to L</find_paths>.  You may specify
custom options for your callback.  However, to ensure that your
parameter names do not conflict with parameters that may be added in
future versions, you should start them with an underscore (e.g.
"C<_name>").

=item $index

This is the index in the path where two paths were joined:

  if ($index > 0) {
    my $last = $path->get_edges->[$index-1];
    my $edge = $path->get_edges->[$index];
    ...
  }

It the index is C<0>, then it contains paths with a single edge.

=back 

The following example implements a "pass through" option that requires
all paths to pass through a given vertex:

   callback => sub {
     my ($path, $options, $index) = @_;
     return ( ($index == 0) ||
	      (!defined $options->{pass_through}) ||
	      $path->has_vertex($options->{pass_through})
     );
   },

An example of using callbacks to filter results is in the F<eg/bus.pl>
script included with the distribution.

Remember that the callback is called for each set of edges.  There is
a balance between improving the search speed by filtering out unwanted
paths during the search and slowing down the search by computationally
expensive filtering.

=back

=cut

sub find_paths {
  my $graph = shift;
  my ($origin, $dest, $options, $trace) = @_;

  local ($_);

  $options     ||= { };
  $options->{alternates} = 1, unless (defined $options->{alternates});
  $options->{earliest}   = 0, unless (defined $options->{earliest});

  if ( (defined $options->{latest}) &&
       ($options->{latest} < $options->{earliest}) ) {
    croak "latest < earliest";
  }

  $trace         = { $origin => 1, }, unless (defined $trace);
  my $trace_back = { %$trace };

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
      # limit the number of alternative connections to speed up the
      # algorithm.

      # We also make sure to reject paths which are cyclic.

      if ($next eq $dest) {

	push @routes,
	  grep (
            ( (!defined $options->{callback}) ||
		(&{$options->{callback}}($_, $options, 0)) )
          ,
	  map { Algorithm::ScheduledPath::Path->new($_) }
	  grep(
            ( ($_->depart_time >= $options->{earliest}) &&
              ( (!defined $options->{latest}) ||
		($_->arrive_time <= $options->{latest}) )
            ), @{ $graph->{$origin}->{$next} } )
          );

      }
      elsif (!exists $trace->{$next}) {

	$trace->{$next}++;

	# Excluding destination vertex and cycles may be redundant.

	my @head = grep(
          ( (!($_->has_vertex($dest)||$_->has_cycle)) 
          ),
	  @{ $graph->find_paths($origin, $next, $options, $trace) }
        );

	if (@head) {

	  # We know that the first element of @head has the earliest
	  # arrival time because we sorted the results (see comment
	  # below).  We want to make sure connecting edges we search
	  # for do not depart earlier than the earliest arrival time.

	  my $subopts  = { %$options, earliest => $head[0]->arrive_time, };

	  # Do not search for the tail if the earliest arrival time is
	  # later than our latest arrival time (actually, this should
	  # not happen, and probably should be changed to an assertion).

	  assert( (!defined $subopts->{latest}) ||
	       ($subopts->{latest} >= $subopts->{earliest}) ), if DEBUG; 

	  # Excluding origin vertex and cycles may be redundant.

	  my @tail = grep(
            ( (!($_->has_vertex($origin)||$_->has_cycle)) ),
	    @{ $graph->find_paths($next, $dest, $subopts, $trace) }
          );

	  if (@tail) {

	    foreach my $route (@head) {

	      # Warning: values are sorted by arrival time, and there
	      # is nothing to favor continuing a leg on a route id!

	      my @connections = 
		grep( ($route->arrive_time <= $_->depart_time),
		      @tail
		    );

	      if (@connections) {
		for (my $i=0; (($i<$options->{alternates}) &&
			       ($i<@connections)); $i++) {

		  my $path = Algorithm::ScheduledPath::Path->new(
		       $route, $connections[$i] );

		  assert($route->destination eq $connections[$i]->origin),
		    if DEBUG;

		  push @routes, $path,
		    unless (
                      ( (defined $options->{callback}) &&
			(!&{$options->{callback}}($path, $options,
						  $route->size)) ) ||
                      $path->has_cycle ||
		      ( (defined $options->{max_time}) &&
			($path->travel_time > $options->{max_time}))
                      );
		    
		}
	      }

	    }
	  }
	}
      }
    }

    # We want to always return sorted results so that we know the
    # first element has the earliest arrival time.  This way we can
    # use it to specify the earliest departure time for connecting
    # edges.

    return [ sort _by_arrive_time @routes ];
  }
  else {
    return [ ];
  }

}

sub _by_arrive_time {
  $a->arrive_time <=> $b->arrive_time ||
  $a->travel_time <=> $b->travel_time;
}


=back

=head1 CAVEATS

The algorithm in this module is a brute-force search for all possible
non-cyclic paths between vertices.  No serious attempts have been made
to optimize it.

It is a hand-rolled method that appears correct, but I have not
attempted any formal proofs of the algorithm.

It has not been tested on huge datasets.

=cut

=head1 AUTHOR

Robert Rothenberg <rrwo at cpan.org>

Please submit bug reports and suggestions to the L<http://rt.cpan.org>.

=head2 Acknowledgements

Thanks to posters on L<http://www.perlmonks.org> for suggestions on
type checking for "string-like" and "number-like" objects.

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
