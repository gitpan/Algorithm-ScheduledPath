=head1 NAME

Algorithm::ScheduledPath::Path - path class for Algorithm::ScheduledPath

=cut

package Algorithm::ScheduledPath::Path;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.40';
# $VERSION = eval $VERSION;

use Carp;
use Algorithm::ScheduledPath::Edge 0.40;

=head1 DESCRIPTION

This is a class for managine paths (ordered sets of edges) in
L<Algorithm::ScheduledPath>.

=head2 Methods

=over

=item new

=cut

sub new {
  my $class = shift;
  my $self = {
    PATH     => [ ],
    VERTICES => { },
  };
  bless $self, $class;

  if (@_) {
    while (my $edge = shift) {
      $self->add_edge($edge);
    }
  }

  return $self;
}

=item add_edge

=cut

sub add_edge {
  my $self = shift;
  while (my $edge = shift) {
    if (ref($edge) eq 'HASH') {
      $self->add_edge( Algorithm::ScheduledPath::Edge->new($edge) );
    }
    elsif ($edge->isa("Algorithm::ScheduledPath::Edge")) {
      if ($self->size == 0) {
	$self->{VERTICES}->{ $edge->origin }++;
      }
      else {
	if ($self->last_edge->destination ne $edge->origin) {	  
	  croak "Unconnected path: ",
	    $self->last_edge->destination, " ",
	    $edge->origin;
	}
      }
      $self->{VERTICES}->{ $edge->destination }++;
      push @{$self->{PATH}}, $edge;
    }
    elsif ($edge->isa(__PACKAGE__)) {
      $self->add_edge( @{$edge->get_edges} );
    }
    else {
      croak "expected Edge or Path";
    }
  }
  return $self;
}

=item first_edge

=cut

sub first_edge {
  my $self = shift;
  if ($self->size) {
    return $self->{PATH}->[0];
  }
  else {
    return;
  }
}

=item origin

=cut

sub origin {
  my $self = shift;
  my $edge = $self->first_edge;
  return (defined $edge) ? $edge->origin : undef;
}

=item last_edge

=cut

sub last_edge {
  my $self = shift;
  if ($self->size) {
    return $self->{PATH}->[-1];
  }
  else {
    return;
  }
}

=item destination

=cut

sub destination {
  my $self = shift;
  my $edge = $self->last_edge;
  return (defined $edge) ? $edge->destination : undef;
}

=item depart_time


=cut

sub depart_time {
  my $self = shift;
  my $edge = $self->first_edge;
  return (defined $edge) ? ($edge->depart_time) : undef;
}

=item arrive_time

=cut

sub arrive_time {
  my $self = shift;
  my $edge = $self->last_edge;
  return (defined $edge) ? ($edge->arrive_time) : undef;
}

=item travel_time


=cut

sub travel_time {
  my $self = shift;
  if ($self->size) {
    return ($self->arrive_time - $self->depart_time);
  }
  else {
    return;
  }
}

=item get_edges

  @edges = @{ $path->get_edges };

Returns a reference to an array containing the component
L<Algorithm::ScheduledPath::Edge> objects.

=cut

sub get_edges {
  my $self = shift;
  return $self->{PATH};
}

=item size

  $size = $path->size;

Returns the number of edges in the path.

=cut

sub size {
  my $self = shift;
  return scalar( @{$self->{PATH}} );
}

=item has_vertex

  if ($path->has_vertex('LEV')) { ... }

Returns true if a path passes through a given vertex.

=cut

sub has_vertex {
  my $self = shift;
  my $vertex = shift;
  return (exists $self->{VERTICES}->{$vertex});
}

=item has_cycle

  if ($path->has_cycle) { ... }

Returns true if the path has a "cycle" (that is, if it passes through
the same vertex more than once).

=cut

sub has_cycle {
  my $self = shift;
  local ($_);
  my @cycle = grep $_>1, values %{$self->{VERTICES}};
  return scalar(@cycle);
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
  my $self = shift;
  my $comp = __PACKAGE__->new;
  my $path = $self->get_edges;

  my $path_id;

  foreach my $edge (@$path) {
    if ( ($comp->size==0) || 
	 (!defined $path_id) || ($path_id ne $edge->path_id)) {
      $comp->add_edge( $edge->copy );
      $path_id = $edge->path_id;
    }
    else {
      $comp->last_edge->destination( $edge->destination );
      $comp->last_edge->arrive_time( $edge->arrive_time );
    }
  }
  return $comp;
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
