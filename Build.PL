use Module::Build;

my $build = Module::Build->new
    (
     module_name => 'Algorithm::ScheduledPath',
     license => 'perl',
     requires => {
       'perl'                       => '5.6.1',
       'Carp'                       => 0,
       'Carp::Assert'               => 0,
       'Class::Meta'                => 0.44,
       'Clone'                      => 0.15,
     },
     recommends => {
     },
     build_requires => {
       'Test::More'                 => 0,
       'Test::Exception'            => 0,
       'Test::Warn'                 => 0,
     },
     create_makefile_pl => 'traditional',
     dist_author        => 'Robert Rothenberg <rrwo at cpan.org>',
);

$build->create_build_script;
