use Module::Build;

my $build = Module::Build->new
    (
     module_name => 'Algorithm::ScheduledPath',
     license => 'perl',
     requires => {
       'base'                       => 0,
       'perl'                       => '5.6.1',
       'Carp'                       => 0,
#        'Carp::Assert'               => 0,
       'Class::Accessor::Fast'      => 0,
     },
     recommends => {
     },
     build_requires => {
       'Test::More'                 => 0,
     },
     create_makefile_pl => 'traditional',
     dist_author        => 'Robert Rothenberg <rrwo at cpan.org>',
);

$build->create_build_script;
