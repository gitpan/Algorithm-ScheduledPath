#!/usr/bin/perl

# bus.pl v0.41.5

# Robert Rothenberg <rrwo@cpan.org> Copyright (C) 2004-2005.  All
# Rights Reserved.  This program is free software; you can
# redistribute it and/or modify it under the same terms as Perl
# itself.

# This is a demonstration of how to use the Algorithm::ScheduledPath
# module.  It builds a directed graph out of bus route information
# (from the __DATA__ block at the end of the code) and displays a list
# of bus routes between two destinations.

# TO-DO:
# * command line arguments to turn this into a generic script
# * bus schedule data from separate file or web site

use strict;
use warnings;

use Carp;

use Algorithm::ScheduledPath 0.41;
use Algorithm::ScheduledPath::Edge;
use Algorithm::ScheduledPath::Path;

my %PathIds = ( );

my $Graph  = parse_data();


my $Routes = $Graph->find_paths(
  'KRKCDY',                            # origin
  'STANDR',                            # destination
  {
   alternates => 1,                    # only show one alternate route
   earliest   => parse_time('07:00'),  # earliest time to leave
   latest     => parse_time('11:00'),  # latest time to arrive
   max_time   => parse_time('02:00'),  # maximum travel time

   callback   => sub {                 # custom filter routine
     my ($path, $options, $index) = @_;

     return 1 unless ($index > 0);

     my $xfer_count = 0;               # count number of transfers
     my $xfer_min   = 99999;           # track minimum transfer time
     my $xfer_max   = -1;              # track maximum transfer time

     # Note: we could run the following route on $path->compressed
     # (indeed, $xfer_count == $path->compressed->size) but it is not
     # more efficient, since this callback is called for each edge in
     # a recursive routine. So compressing the edge will slow this
     # down that much more.

     my $last = $path->get_edges->[$index-1];
     my $edge = $path->get_edges->[$index];
     if ( (defined $last) && ($last->path_id ne $edge->path_id) ) {
       $xfer_count++;
       if (($edge->depart_time - $last->arrive_time) < $xfer_min) {
	 $xfer_min = ($edge->depart_time - $last->arrive_time);
       }
       if (($edge->depart_time - $last->arrive_time) > $xfer_max) {
	 $xfer_max = ($edge->depart_time - $last->arrive_time);
       }
     }

     return
       ( (!defined $options->{max_transfer_time}) ||
	 ($xfer_max <= $options->{max_transfer_time}) ) &&
       ( (!defined $options->{min_transfer_time}) ||
	 ($xfer_min >= $options->{min_transfer_time}) )  &&
        ( (!defined $options->{max_transfers}) ||
 	 ($xfer_count <= $options->{max_transfers}) )  # &&
#        ( (!defined $options->{pass_through}) || ($index == 0) ||
# 	 ( $path->has_vertex($options->{pass_through}) ) );
   },
#    pass_through      => undef,
   max_transfers     =>  1,     # we don't want to transfer too much
   min_transfer_time =>  5,     # we want at least 5 min between xfers
   max_transfer_time => 15,     # we don't want to wait more than 15 min
  }
);

print "-"x40, "\n";

if (@$Routes) {
  foreach my $route (sort by_arrival @$Routes) {

    if ($route->has_cycle) {
      croak "Route should not have cycles";
    }

    # We compress the route so that we only see edges with different paths

    my $trip = $route->compressed;

    foreach my $leg (@{$trip->get_edges}) {
      print join("\t", $PathIds{$leg->path_id},
		 $leg->origin, unparse_time($leg->depart_time),
		 $leg->destination, unparse_time($leg->arrive_time)
      ), "\n";

    }
    print "\nTravel Time", "\t"x3, unparse_time($route->travel_time), "\n";
    print "-"x40, "\n";
  }
}

sub by_depart {
  $a->depart_time <=> $b->depart_time;
}

sub by_arrival {
  $a->arrive_time <=> $b->arrive_time;
}

sub unparse_time {
  my $time = shift;
  my $hour = int($time / 60);
  my $min  = $time % 60;
  return sprintf('%02d:%02d', $hour, $min);
}


sub parse_time {
  my $time = shift;
  $time =~ s/(\d\d)\:(\d\d)/$1$2/;
  my $hour = 0+substr($time,0,2);
  my $min  = 0+substr($time,2,2);
  return $min+(60*$hour);
}

sub parse_data {

  my $graph = new Algorithm::ScheduledPath;

  my $path_id = 1;

  while (my $line=<DATA>) {
    chomp($line);
    if ($line) {
      $line =~ s/\x23.+$//g;
      my ($bus_no, @stops) = split /\s+/, $line;

      $PathIds{$path_id} = $bus_no;

      my ($orig, $depart);
      while (@stops) {
	my $dest = shift @stops;
	my ($arrive, $depart2) = split /\//, shift @stops;
	$depart2 ||= $arrive;

	if (defined $orig) {
	  my $e = new Algorithm::ScheduledPath::Edge(
            path_id     => $path_id,
            origin      => $orig,
            depart_time => parse_time($depart),
            destination => $dest,
            arrive_time => parse_time($arrive), 
          );
	  $graph->add_edge($e);
	}

	($orig, $depart) = ($dest, $depart2);
      }
      $path_id++;      
    }
  }
  return $graph;
}


__DATA__

# Below is sample data based on bus schedules in Fife, Scotland.
# These are not complete, nor are they accurate.

X1	KRKCDY	0725	GLNRTH	0752
X1	KRKCDY	0805	GLNRTH	0832
X1	KRKCDY	0835	GLNRTH	0902
X1	KRKCDY	0905	GLNRTH	1032
X1	KRKCDY	0935	GLNRTH	1002
X1	KRKCDY	1005	GLNRTH	1132
X1	KRKCDY	1035	GLNRTH	1102

X1	GLNRTH	1951	KRKCDY	2016
X1	GLNRTH	2051	KRKCDY	2116
X1	GLNRTH	2151	KRKCDY	2216
X1	GLNRTH	2251	KRKCDY	2316

6	KRKCDY	0737	LEVEN	0827
6A	KRKCDY	0837	LEVEN	0915
6	KRKCDY	0907	LEVEN	0945
6A	KRKCDY	0937	LEVEN	1015
6	KRKCDY	1007	LEVEN	1045

6	LEVEN	1650	KRKCDY	1721
6	LEVEN	1720	KRKCDY	1751

7	KRKCDY	0610	LEVEN	0648
7	KRKCDY	0652	LEVEN	0730
7A	KRKCDY	0712	LEVEN	0755
7	KRKCDY	0758	LEVEN	0836
7	KRKCDY	0820	LEVEN	0858
7	KRKCDY	0857	LEVEN	0935
7	KRKCDY	0927	LEVEN	1005
7A	KRKCDY	0947	LEVEN	1025
7	KRKCDY	0957	LEVEN	1035
7A	KRKCDY	1017	LEVEN	1055
7	KRKCDY	1027	LEVEN	1105
7A	KRKCDY	1047	LEVEN	1125

7	KRKCDY	0620	DNFMLN	0740
7	KRKCDY	0732	DNFMLN	0853
7	KRKCDY	0822	DNFMLN	0935
7	KRKCDY	0852	DNFMLN	1005
7	KRKCDY	0922	DNFMLN	1035

7	LEVEN	1845	KRKCDY	1921	DNFMLN	2030
7	LEVEN	1945	KRKCDY	2021	DNFMLN	2130
7	LEVEN	2045	KRKCDY	2121	DNFMLN	2230
7	LEVEN	2145	KRKCDY	2221	DNFMLN	2330
7	LEVEN	2245	KRKCDY	2321

138	KRKCDY	0835	LEVEN	0913
13	KRKCDY	0915	LEVEN	1012
13	KRKCDY	1015	LEVEN	1112

13	LEVEN	1715	KRKCDY	1805
13	LEVEN	1815	KRKCDY	1912
13	LEVEN	1915	KRKCDY	2012
13	LEVEN	2015	KRKCDY	2112
13	LEVEN	2115	KRKCDY	2212
13	LEVEN	2215	KRKCDY	2312

14	DNFMLN	0545	STRLNG	0655
14	DNFMLN	0610	STRLNG	0725
14A	DNFMLN	0711	STRLNG	0831
14	DNFMLN	0746	STRLNG	0909
14	DNFMLN	0851	STRLNG	1008
14A	DNFMLN	0951	STRLNG	1108

23	STRLNG	0700	CUPAR	0837	STANDR	0855
23	STRLNG	0705	CUPAR	0840	STANDR	0858
23	STRLNG	0910	CUPAR	1043	STANDR	1103

23	STANDR	0604	CUPAR	0622
23	STANDR	0659	CUPAR	0717
23	STANDR	0709	CUPAR	0727
23	STANDR	0710	CUPAR	0730	STRLNG	0905
23	STANDR	0800	CUPAR	0829
23	STANDR	0850	CUPAR	0908
23	STANDR	0910	CUPAR	0928	STRLNG	1104

23	STANDR	1735	CUPAR	1753	STRLNG	1929
23	STANDR	2355	CUPAR	2429

X24	DNFMLN	0600	GLNRTH	0633	CUPAR	0656	STANDR	0717
X24	GLNRTH	0653	CUPAR	0716	STANDR	0737
X24	DNFMLN	0700	GLNRTH	0733	CUPAR	0756	STANDR	0817
X24	DNFMLN	0730	GLNRTH	0803	CUPAR	0826	STANDR	0847
X24	DNFMLN	0755	GLNRTH	0838
X24	DNFMLN	0835	GLNRTH	0908	CUPAR	0931	STANDR	0952
X24	DNFMLN	0930	GLNRTH	1003	CUPAR	1026	STANDR	1047

X24	GLNRTH	0632	DNFMLN	0702
X24	GLNRTH	0815	DNFMLN	0845
X24	GLNRTH	0845	DNFMLN	0915
X24	GLNRTH	0915	DNFMLN	0945
X24	GLNRTH	1015	DNFMLN	1045

X24	STANDR	1825	CUPAR	1846	GLNRTH	1915	DNFMLN	1945
X24	STANDR	1905	CUPAR	1926	GLNRTH	1955	DNFMLN	2025
X24	STANDR	1935	CUPAR	1956	GLNRTH	2025	DNFMLN	2055

24	STANDR	1950	CUPAR	2009	GLNRTH	2040
24	STANDR	2050	CUPAR	2109	GLNRTH	2140
24	STANDR	2150	CUPAR	2209	GLNRTH	2240
24	STANDR	2250	CUPAR	2309	GLNRTH	2340

X26	LEVEN	0640	STANDR	0754
X26	DNFMLN	0620	KRKCDY	0655	LEVEN	0721	STANDR	0833

X26	STANDR	1715	LEVEN	1835	KRKCDY	1902	DNFMLN	1935
X26	LEVEN	1915	KRKCDY	1945	DNFMLN	2017
X26	STANDR	1805	LEVEN	1925	KRKCDY	1955	DNFMLN	2027
X26	LEVEN	2015	KRKCDY	2045	DNFMLN	2117

32	KRKCDY	0740	GLNRTH	0841
32	KRKCDY	0930	GLNRTH	1026
32	KRKCDY	1030	GLNRTH	1126

32	GLNRTH	1910	KRKCDY	2006
32	GLNRTH	2110	KRKCDY	2206

37	KRKCDY	0600	GLNRTH	0635
37	KRKCDY	0700	GLNRTH	0747
37	KRKCDY	0730	GLNRTH	0805
37	KRKCDY	0750	GLNRTH	0825
37	KRKCDY	0810	GLNRTH	0845
37	KRKCDY	0830	GLNRTH	0905
37	KRKCDY	0850	GLNRTH	0925

39	KRKCDY	0740	GLNRTH	0814
39	KRKCDY	0800	GLNRTH	0834
39	KRKCDY	0820	GLNRTH	0854
39	KRKCDY	0840	GLNRTH	0914
39	KRKCDY	0900	GLNRTH	0934

39	GLNRTH	2125	KRKCDY	2158
39	GLNRTH	2225	KRKCDY	2258


40	KRKCDY	0812	GLNRTH	0853
40	KRKCDY	0912	GLNRTH	0953
40	KRKCDY	1012	GLNRTH	1053
40	KRKCDY	1112	GLNRTH	1153

40	GLNRTH	1657	KRKCDY	1809

41	KRKCDY	1015	CUPAR	1108
41	KRKCDY	1215	CUPAR	1308

41	CUPAR	1550	KRKCDY	1643
41	CUPAR	1740	KRKCDY	1846
41	CUPAR	1905	KRKCDY	1954
41	CUPAR	2105	KRKCDY	2154
41	CUPAR	2303	LEVEN	2342

43A	LEVEN	0615	GLNRTH	0646
44A	LEVEN	0635	GLNRTH	0714
43	LEVEN	0655	GLNRTH	0723
44A	LEVEN	0715	GLNRTH	0754
43	LEVEN	0725	GLNRTH	0753
44A	LEVEN	0800	GLNRTH	0839
43	LEVEN	0805	GLNRTH	0833
43	LEVEN	0903	GLNRTH	0931
44	LEVEN	0933	GLNRTH	1003
43	LEVEN	1003	GLNRTH	1031

43	LEVEN	1703	GLNRTH	1731
43	LEVEN	1718	GLNRTH	1746
44	LEVEN	1733	GLNRTH	1803

44	GLNRTH	0731	LEVEN	0801
44	GLNRTH	0821	LEVEN	0851
43	GLNRTH	0901	LEVEN	0929
44	GLNRTH	0929	LEVEN	0959
43	GLNRTH	1001	LEVEN	1029

44	GLNRTH	1829	LEVEN	1859
43	GLNRTH	1801	LEVEN	1829
44	GLNRTH	1729	LEVEN	1804

46	LEVEN	1605	GLNRTH	1646
46	LEVEN	1705	GLNRTH	1746
46	LEVEN	1805	GLNRTH	1837
46	LEVEN	1905	GLNRTH	1937
46	LEVEN	2005	GLNRTH	2037
46	LEVEN	2105	GLNRTH	2137
46	LEVEN	2205	GLNRTH	2237
46	LEVEN	2305	GLNRTH	2335

X54	GLNRTH	0606	DNFMLN	0709
X54	GLNRTH	0647	DNFMLN	0729
X54	GLNRTH	0839	DNFMLN	0909
X54	GLNRTH	0909	DNFMLN	0939
X54	GLNRTH	0939	DNFMLN	1009
X54	GLNRTH	1039	DNFMLN	1109

X54	GLNRTH	1539	DNFMLN	1609
X54	GLNRTH	1639	DNFMLN	1709
X54	GLNRTH	1739	DNFMLN	1809

X54	DNFMLN	1605	GLNRTH	1635
X54	DNFMLN	1723	GLNRTH	1753
X54	DNFMLN	1828	GLNRTH	1858
X54	DNFMLN	1905	GLNRTH	1935
X54	DNFMLN	2001	GLNRTH	2031

X60	LEVEN	0555	STANDR	0630
X59	GLNRTH	0635	CUPAR	0656
X60	LEVEN	0641	STANDR	0715
X60	LEVEN	0716	STANDR	0751
X59	GLNRTH	0727	CUPAR	0748
X59	KRKCDY	0809/0814	GLNRTH	0830/0835	CUPAR	0856
X60	LEVEN	0806	STANDR	0841
X59	KRKCDY	0909	GLNRTH	0925/0930	CUPAR	0951
X60	LEVEN	0916	STANDR	0951
X60	KRKCDY	0948	LEVEN	1016	STANDR	1051
X59	KRKCDY	1008	GLNRTH	1029	CUPAR	1050
X60	KRKCDY	1048	LEVEN	1116	STANDR	1151
X59	KRKCDY	1108	GLNRTH	1129	CUPAR	1150

X60	STANDR	1700	LEVEN	1736	KRKCDY	1803
X59	CUPAR	1711	GLNRTH	1732
X60	STANDR	1735	LEVEN	1811
X60	STANDR	1800	LEVEN	1836	KRKCDY	1903
X59	CUPAR	1821	GLNRTH	1842
X59	CUPAR	1921	GLNRTH	1947	KRKCDY	2011
X60	STANDR	1930	LEVEN	2005
X59	GLNRTH	2047	KRKCDY	2111
X60	STANDR	2030	LEVEN	2105
X59	GLNRTH	2147	KRKCDY	2211
X60	STANDR	2330	LEVEN	2405

64	CUPAR	0730	STANDR	0813
64	CUPAR	0850	STANDR	0933
64B	CUPAR	0925	STANDR	1013
64	CUPAR	1028	STANDR	1113

64	STANDR	1715	CUPAR	1758
64A	STANDR	1915	CUPAR	1956
64A	STANDR	2115	CUPAR	2156
64A	STANDR	2315	CUPAR	2356

66	GLNRTH	0628	CUPAR	0728
67	GLNRTH	0645	CUPAR	0720
267	GLNRTH	0755	CUPAR	0838
66	GLNRTH	0755	CUPAR	0856
67	GLNRTH	1000	CUPAR	1055

66	CUPAR	1810	GLNRTH	1908
66	CUPAR	1920	GLNRTH	2018
66	CUPAR	2120	GLNRTH	2218
66	CUPAR	2320	GLNRTH	2418

95	LEVEN	0545	STANDR	0705
95	LEVEN	0640	STANDR	0750
95	LEVEN	0705	STANDR	0840
95	LEVEN	0835	STANDR	0957
95	LEVEN	0935	STANDR	1057

95	STANDR	1815	LEVEN	1936
95	STANDR	1900	LEVEN	2021
95	STANDR	1945	LEVEN	2105
95	STANDR	2045	LEVEN	2205
95	STANDR	2145	LEVEN	2305
95	STANDR	2245	LEVEN	2405

97	LEVEN	0740	STANDR	0845
97	LEVEN	1440	STDANR	1523
