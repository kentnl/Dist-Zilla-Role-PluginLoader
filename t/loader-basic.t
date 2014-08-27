
use strict;
use warnings;

use Test::More;
use Test::DZil qw( simple_ini );
use Dist::Zilla::Util::Test::KENTNL qw( dztest );
use Dist::Zilla::Util::ConfigDumper qw( dump_plugin );

# ABSTRACT: Test Role::PluginLoader directly

{
  package    #
    Dist::Zilla::Plugin::Example;
  use Moose;
  with 'Dist::Zilla::Role::Plugin', 'Dist::Zilla::Role::PluginLoader';

  my $levels = 0;

  sub load_plugins {
    my ( $self, $loader ) = @_;
    return if $levels > 5;
    $levels++;
    $loader->load( 'Example', 'LoaderExample' . $levels );
  }
}

my $test = dztest();
$test->add_file( 'dist.ini', simple_ini('Example') );
$test->build_ok;
is(

  ( scalar grep { $_->isa('Dist::Zilla::Plugin::Example') } @{ $test->builder->plugins } ), 
  7, "One plugin recursively loads 7"
);
for my $plugin ( @{ $test->builder->plugins } ) {
  note explain dump_plugin($plugin);  
}
done_testing;
