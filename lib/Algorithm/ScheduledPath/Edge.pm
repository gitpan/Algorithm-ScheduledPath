=head1 NAME

Algorithm::ScheduledPath::Edge - Edge class for Algorithm::ScheduledPath

=cut

package Algorithm::ScheduledPath::Types;

use strict;
use Class::Meta::Type;

# This is based on the Class::Meta::Types::(String|Number) modules but
# allows for objects which behave like strings or numbers in that they
# support apporopriate (string|number)ification and comparison
# operations.  If Class::Meta is updated to support "stringlike" and
# "numberlike" types, then this package will go away.

sub import {
    my ($pkg, $builder) = @_;
    $builder ||= 'default';
    return if eval "Class::Meta::Type->new('stringlike')";

    Class::Meta::Type->add(
        key     => "stringlike",
        name    => "Stringlike",
        desc    => "Stringlike",
        builder => $builder,
        check   => sub {
            return unless defined $_[0] && ref $_[0];
	    eval { ("$_[0]") && (($_[0] cmp $_[0])==0) }
	      and return;
            $_[2]->class->handle_error("Value '$_[0]' is not a valid string");
        }
    );

    Class::Meta::Type->add(
        key     => "numberlike",
        name    => "numberlike",
        desc    => "numberlike",
        builder => $builder,
        check   => sub {
            return unless defined $_[0];

	    # L<perlfunc> manpage notes that NaN != NaN, so we can
	    # verify that numeric conversion function works properly
	    # along with the comparison operator.

	    eval { ((0+$_[0]) == (0+$_[0])) && (($_[0] <=> $_[0])==0) }
	      and return;
            $_[2]->class->handle_error("Value '$_[0]' is not a valid number");
        }
    );
}

1;

package Algorithm::ScheduledPath::Edge;

use 5.006;
use strict;
use warnings::register;

our $VERSION = '0.41_01';
$VERSION = eval $VERSION;

use Carp;
use Class::Meta 0.44;
use Class::Meta::Types::Perl;

use Clone 'clone';

my $UniqueId = 0;

BEGIN {

  Algorithm::ScheduledPath::Types->import();

  my $cm = Class::Meta->new( );

  $cm->add_constructor( name   => 'new',
			create => 1 );

  $cm->add_attribute( name     => 'id',
		      required => 1,
                      once     => 0, # problematic...
                      type     => 'scalar',
		      default  => sub { ++$UniqueId; }, );

  $cm->add_attribute( name     => 'path_id',
		      required => 1,
                      type     => 'stringlike',
		      default  => undef, );

  $cm->add_attribute( name     => 'origin',
		      required => 1,
                      type     => 'stringlike',
		      default  => undef, );

  $cm->add_attribute( name     => 'depart_time',
		      required => 1,
                      type     => 'numberlike',
		      default  => undef, );

  $cm->add_attribute( name     => 'destination',
		      required => 1,
                      type     => 'stringlike',
		      default  => undef, );

  $cm->add_attribute( name     => 'arrive_time',
		      required => 1,
                      type     => 'numberlike',
		      default  => undef, );

  $cm->add_attribute( name     => 'data',
		      required => 0,
                      type     => 'scalar',
		      default  => undef, );

  $cm->add_method(    name     => 'travel_time',
		      view     => Class::Meta::PUBLIC );

  $cm->add_method(    name     => 'clone',
		      view     => Class::Meta::PUBLIC );

  $cm->build;

}

=head1 DESCRIPTION

This is a class used for managing edges in L<Algorithm::ScheduledPath::Path>
and L<Algorithm::ScheduledPath>.

=head2 Methods

=over

=item new

  $edge = Algorithm::ScheduledPath::Edge->new();

The constructor. Fields can be set from the constructor:

  $edge = Algorithm::ScheduledPath::Edge->new(
    path_id     => 'X60',
    origin      => 'KDY', depart_time => 500,
    destination => 'EDH', arrive_time => 570,
  );

Note that the call style has changed from versions prior to 0.41.  It no
longer accepts a hash reference.

=item id

  $edge->id( $id );

  $id = $edge->id;

An accessor method for the unique edge I<id>.  It is currently unused.

If the value is set to C<0> or C<undef>, it will automatically
generate a unique identifier.

=item path_id

  $edge->path_id( $id );

  $id = $edge->path_id;

An accessor method for the edge I<path id>.  This is a tag used to group
together multiple egdes into one path.  It is assumed to be a string.

=item origin

  $edge->origin( $name );

  $name = $edge->origin;

An accessor method for identifying the I<origin vertex>.  It is
assumed to be a string.

=item depart_time

  $edge->depart_time( $time );

  $time = $edge->depart_time;

An accessor method for specifying the I<depature time>, as a number.

The number value can be anything you need it to be: reals or integers,
Unix epoch time, the number of days since X day, shire years, seconds,
minutes, hours, days, weeks, whatever.  As long as all edges have time
values in the same units.

=item destination

An accessor method for identifying the I<destination vertex>.  It is
assumed to be a string.

=item arrive_time

An accessor method for specifying the I<arrival time>, as a number. It
is assumed to be greater than or equal to the depature time. (See
L</depart_time> for more information on the format.)

=item data

An accessor method for attaching additional data to the edge.  It is
assumed to be a scalar value (though it may be a reference to an
object).

=item travel_time

  $time = $edge->travel_time;

Returns the difference between the departure and arrival times.

=cut

sub travel_time {
  my $self = shift;
  return (($self->arrive_time) - ($self->depart_time));
}

=item clone

  $edge2 = $edge->clone;

Clones the edge object.

=back

=head1 AUTHOR

Robert Rothenberg <rrwo at cpan.org>

=head1 LICENSE

Copyright (c) 2004 Robert Rothenberg. All rights reserved.  This
program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

Algorithm::ScheduledPath

=cut

1;

__END__
