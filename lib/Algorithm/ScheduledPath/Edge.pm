=head1 NAME

Algorithm::ScheduledPath::Edge - edge class for Algorithm::ScheduledPath

=cut

package Algorithm::ScheduledPath::Edge;

use 5.006;
use strict;
use warnings;

use base 'Class::Accessor::Fast';

our $VERSION = '0.32';

=head1 DESCRIPTION

This is a class used for managing edges in L<Algorithm::ScheduledPath::Path>
and L<Algorithm::ScheduledPath>.

=head2 Methods

=over

=item new

  $edge = Algorithm::ScheduledPath::Edge->new();

The constructor. Fields can be set from the constructor:

  $edge = Algorithm::ScheduledPath::Edge->new( {
    path_id     => 'X60',
    origin      => 'KDY', depart_time => 500,
    destination => 'EDH', arrive_time => 570,
  } );
  
=item id

  $edge->id( $id );

  $id = $edge->id;

An accessor method for the unique edge I<id>.  It is currently unused.

If the value is set to C<0> or C<undef>, it will automatically
generate a unique identifier.

=cut

my $UniqueId = 0;

sub id {
  my $self = shift;
  if (@_) {
    my $id = shift;
    $self->{id} = $id || ++$UniqueId;
  }
  return $self->{id};
}

=item path_id

  $edge->path_id( $id );

  $id = $edge->path_id;

An accessor method for the edge I<path id>.  This is a tag used to group
together multiple egdes into one path.

=item origin

An accessor method for identifying the I<origin vertex>.

=item depart_time

An accessor method for specifying the I<depature time>, as a number.

=item destination

An accessor method for identifying the I<destination vertex>.

=item arrive_time

An accessor method for specifying the I<arrival time>, as a number. It
is assumed to be greater than or equal to the depature time.

=item data

An accessor method for attaching additional data to the edge.

=cut

__PACKAGE__->mk_accessors(qw(
    path_id origin depart_time destination arrive_time data ));

=item travel_time

  $time = $edge->travel_time;

Returns the difference between the departure and arrival times.

=cut

sub travel_time {
  my $self = shift;
  return (($self->arrive_time) - ($self->depart_time));
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
