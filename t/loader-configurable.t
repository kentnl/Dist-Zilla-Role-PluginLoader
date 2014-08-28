
use strict;
use warnings;

use Test::More;
use Test::DZil qw( simple_ini );
use Dist::Zilla::Util::Test::KENTNL qw( dztest );
use Dist::Zilla::Util::ConfigDumper qw( dump_plugin );
use Test::Differences;

# ABSTRACT: Test Role::PluginLoader directly
{
  package    #
    Dist::Zilla::Plugin::Injected;
  use Moose;
  with 'Dist::Zilla::Role::Plugin';
  use Dist::Zilla::Util::ConfigDumper qw( dump_plugin config_dumper );

  has payload => ( is => ro => );
  has section => ( is => ro => );

  around dump_config => config_dumper( __PACKAGE__, { attrs => [qw( payload section )] } );

  sub plugin_from_config {
    my ( $class, $name, $arg, $section ) = @_;

    return $class->new(
      {
        %{$arg},
        plugin_name => $name,
        zilla       => $section->sequence->assembler->zilla,
        payload     => $arg,
      }
    );
  }
}
{
  package    #
    Dist::Zilla::Plugin::Example;
  use Moose;
  with 'Dist::Zilla::Role::PluginLoader::Configurable';

}

sub getinj {
  my ($test) = @_;
  return grep { $_->isa('Dist::Zilla::Plugin::Injected') } @{ $test->builder->plugins };
}
subtest 'basic, noargs' => sub {
  my $test = dztest();
  $test->add_file(
    'dist.ini',
    simple_ini(
      [
        'Example' => {
          dz_plugin => 'Injected'
        }
      ]
    )
  );
  $test->build_ok;
  is( scalar getinj($test), 1, "One plugin loads another 1" );
  eq_or_diff(
    [ map { dump_plugin($_)->{config} } getinj($test) ],
    [ { 'Dist::Zilla::Plugin::Injected' => { payload => {} } } ],
    'Init state ok'
  );
};

subtest 'basic, named' => sub {
  my $test = dztest();
  $test->add_file(
    'dist.ini',
    simple_ini(
      [
        'Example' => {
          dz_plugin      => 'Injected',
          dz_plugin_name => 'MyName',
        }
      ]
    )
  );
  $test->build_ok;
  is( scalar getinj($test), 1, "One plugin loads another 1" );
  eq_or_diff( [ map { dump_plugin($_)->{name} } getinj($test) ], ['MyName'], 'Init state ok' );
};

subtest 'basic, minversion' => sub {
  my $test = dztest();
  $test->add_file(
    'dist.ini',
    simple_ini(
      [
        'Example' => {
          dz_plugin            => 'Injected',
          dz_plugin_minversion => '5',
        }
      ]
    )
  );
  $test->build_ok;
  is( scalar getinj($test), 1, "One plugin loads another 1" );
  $test->prereqs_deeply(
    {

      develop => { requires => { 'Dist::Zilla::Plugin::Injected' => '5' } }
    },
  );
};
subtest 'basic, minversion phasechange' => sub {
  my $test = dztest();
  $test->add_file(
    'dist.ini',
    simple_ini(
      [
        'Example' => {
          dz_plugin            => 'Injected',
          dz_plugin_minversion => '5',
          prereq_to            => 'runtime.requires'
        }
      ]
    )
  );
  $test->build_ok;
  is( scalar getinj($test), 1, "One plugin loads another 1" );
  $test->prereqs_deeply(
    {

      runtime => { requires => { 'Dist::Zilla::Plugin::Injected' => '5' } }
    },
  );
};
subtest 'basic, minversion hide' => sub {
  my $test = dztest();
  $test->add_file(
    'dist.ini',
    simple_ini(
      [
        'Example' => {
          dz_plugin            => 'Injected',
          dz_plugin_minversion => '5',
          prereq_to            => 'none'
        }
      ]
    )
  );
  $test->build_ok;
  is( scalar getinj($test), 1, "One plugin loads another 1" );
  $test->prereqs_deeply(
    {

    },
  );
};

subtest 'basic, arg passthrough' => sub {
  my $test = dztest();
  $test->add_file(
    'dist.ini',
    simple_ini(
      [
        'Example' => {
          dz_plugin            => 'Injected',
          dz_plugin_minversion => '5',
          dz_plugin_arguments  => [ 'key1 = value1', 'key2 = value2', ]
        }
      ]
    )
  );
  $test->build_ok;
  is( scalar getinj($test), 1, "One plugin loads another 1" );
  eq_or_diff(
    [ map { dump_plugin($_)->{config} } getinj($test) ],
    [ { 'Dist::Zilla::Plugin::Injected' => { payload => { key1 => 'value1', key2 => 'value2' } } } ],
    'Value pass ok'
  );
};

done_testing;
