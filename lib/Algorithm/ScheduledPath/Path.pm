=head1 NAME

Algorithm::ScheduledPath::Path - path class for Algorithm::ScheduledPath

=cut

package Algorithm::ScheduledPath::Path;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.30';

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
    while (my $leg = shift) {
      $route->add_leg($leg);
    }
  }

  return $route;
}

=item add_leg

=cut

sub add_leg {
  my $route = shift;
  while (my $leg = shift) {
    if ($leg->isa("Algorithm::ScheduledPath::Edge")) {
      push @{$route}, $leg;
    }
    elsif ($leg->isa(__PACKAGE__)) {
      $route->add_leg( @{$leg->get_legs} );
    }
    else {
      croak "expected ".__PACKAGE__;
    }
  }
  return $route;
}

=item first_leg

=cut

sub first_leg {
  my $route = shift;
  if (@$route) {
    return $route->[0];
  }
  else {
    return;
  }
}

=item last_leg

=cut

sub last_leg {
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
  return $route->first_leg->depart_time;
}

=item arrive_time

=cut

sub arrive_time {
  my $route = shift;
  return $route->last_leg->arrive_time;
}

=item travel_time


=cut

sub travel_time {
  my $route = shift;
  return ($route->arrive_time - $route->depart_time);
}

=item get_legs

  @edges = @{ $path->get_legs };

Returns a reference to an array containing the component
L<Algorithm::ScheduledPath::Edge> objects.

=cut

sub get_legs {
  my $route = shift;
  return [ @{$route} ];
}

=item num_legs

  $size = $path->num_legs;

Returns the number of legs (edges) in the path.

=cut

sub num_legs {
  my $route = shift;
  return scalar( @{$route} );
}

=item compressed

  $cpath = $path->compressed;

Produces a "compressed" version of the path, where sequential edges
(legs) sharing the same path identifier are merged.  The result may be
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
  foreach my $leg (@$route) {
    if ($comp->num_legs) {
      if ($comp->last_leg->path_id eq $leg->path_id) {
	foreach my $method (qw( destination arrive_time )) {
	  $comp->last_leg->$method( $leg->$method );
	}
	carp "data() attribute will be lost", if (defined $leg->data);
      }
      else {
	$comp->add_leg($leg);
      }
    }
    else {
      $comp->add_leg($leg);
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
