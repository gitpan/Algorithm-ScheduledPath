=head1 NAME

Algorithm::ScheduledPath::Path - path class for Algorithm::ScheduledPath

=cut

package Algorithm::ScheduledPath::Path;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.32';

use Carp;
use Algorithm::ScheduledPath::Edge;

=head1 DESCRIPTION

This is a class for managine paths (ordered sets of edges) in
L<Algorithm::ScheduledPath>.

=head2 Methods

=over

=item new

=cut

sub new {
  my $class = shift;
  my $route = [ ];       # Warning: this is problematic for overloading '@{}'
  bless $route, $class;

  if (@_) {
    while (my $edge = shift) {
      $route->add_edge($edge);
    }
  }

  return $route;
}

=item add_edge

=cut

sub add_edge {
  my $route = shift;
  while (my $edge = shift) {
    if ($edge->isa("Algorithm::ScheduledPath::Edge")) {
      push @{$route}, $edge;
    }
    elsif ($edge->isa(__PACKAGE__)) {
      $route->add_edge( @{$edge->get_edges} );
    }
    else {
      croak "expected ".__PACKAGE__;
    }
  }
  return $route;
}

=item first_edge

=cut

sub first_edge {
  my $route = shift;
  if (@$route) {
    return $route->[0];
  }
  else {
    return;
  }
}

=item last_edge

=cut

sub last_edge {
  my $route = shift;
  if (@$route) {
    return $route->[-1];
  }
  else {
    return;
  }
}

=item depart_time


=cut

sub depart_time {
  my $route = shift;
  return $route->first_edge->depart_time;
}

=item arrive_time

=cut

sub arrive_time {
  my $route = shift;
  return $route->last_edge->arrive_time;
}

=item travel_time


=cut

sub travel_time {
  my $route = shift;
  return ($route->arrive_time - $route->depart_time);
}

=item get_edges

  @edges = @{ $path->get_edges };

Returns a reference to an array containing the component
L<Algorithm::ScheduledPath::Edge> objects.

=cut

sub get_edges {
  my $route = shift;
  return [ @{$route} ];
}

=item num_edges

  $size = $path->num_edges;

Returns the number of edges in the path.

=cut

sub num_edges {
  my $route = shift;
  return scalar( @{$route} );
}

=item has_vertex

  if ($path->has_vertex('LEV')) { ... }

Returns true if a path passes through a given vertex.

=cut

sub has_vertex {
  my $route = shift;
  my $vertex = shift;
  if ($route->first_edge->origin eq $vertex) {
    return 1;
  }
  foreach my $edge ( @$route ) {
    if ($edge->destination eq $vertex) {
      return 1;
    }
  }
  return;
}

=item has_cycle

  if ($path->has_cycle) { ... }

Returns true if the path has a "cycle" (that is, if it passes through
the same vertex more than once).

=cut

sub has_cycle {
  my $route = shift;
  my %vertices = ( $route->first_edge->origin => 1, );
  foreach my $edge ( @$route ) {
    if (++$vertices{ $edge->destination } > 1) {
      return 1;
    }
  }
  return;
}

=item compressed

  $cpath = $path->compressed;

Produces a "compressed" version of the path, where sequential edges
sharing the same path identifier are merged.  The result may be
a path with "virtual" edges.

For instance, if the path represents a route one might take on a bus
line, where the path identifier refers to bus routes, then the
compressed version would merge bus stops on the same route so as to
make it easier to identify where one needs to transfer to different
bus lines.  (One could also use this to facilitate analysis of the
number of transfers.)

=cut

sub compressed {
  my $route = shift;
  my $comp  = __PACKAGE__->new;
  foreach my $edge (@$route) {
    if ($comp->num_edges) {
      if ($comp->last_edge->path_id eq $edge->path_id) {
	foreach my $method (qw( destination arrive_time )) {
	  $comp->last_edge->$method( $edge->$method );
	}
	carp "data() attribute will be lost", if (defined $edge->data);
      }
      else {
	$comp->add_edge($edge);
      }
    }
    else {
      $comp->add_edge($edge);
    }
  }
  return $comp;
}

# alias to maintain compatiability with version prior to 0.32

BEGIN {
  *add_leg   = \&add_edge;
  *first_leg = \&first_edge;
  *last_leg  = \&last_edge;
  *get_legs  = \&get_edges;
  *num_legs  = \&num_edges;
}


=back

=head1 AUTHOR

Robert Rothenberg <rrwo at cpan.org>

=head1 LICENSE

Copyright (c) 2004 Robert Rothenberg. All rights reserved.  This
program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut


1;
__END__
