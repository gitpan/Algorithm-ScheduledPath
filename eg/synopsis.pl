#!/usr/bin/perl

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

  # Outputs the following:
  #  A 2 C 7
  #  A 1 C 9

  foreach my $path (@$paths) {
    print join(" ", map { $path->$_ } (qw(
      origin depart_time destination arrive_time ))), "\n";
  }
