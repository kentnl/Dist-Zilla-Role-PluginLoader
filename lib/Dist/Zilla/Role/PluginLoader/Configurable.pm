use 5.010;    # _Pulp__5010_qr_m_propagate_properly
use strict;
use warnings;
use utf8;

package Dist::Zilla::Role::PluginLoader::Configurable;

our $VERSION = '0.001002';

# ABSTRACT: A role for plugins that load user defined and configured plugins

# AUTHORITY

use Moose::Role qw( has around with );
use Dist::Zilla::Util;
use Dist::Zilla::Util::ConfigDumper qw( config_dumper );
with 'Dist::Zilla::Role::PrereqSource', 'Dist::Zilla::Role::PluginLoader';

has dz_plugin => ( is => ro =>, required => 1 );

has dz_plugin_name => ( is => ro =>, lazy => 1, lazy_build => 1 );
sub _build_dz_plugin_name { my ($self) = @_; return $self->dz_plugin; }

has dz_plugin_minversion => ( is => ro =>, lazy => 1, lazy_build => 1 );
sub _build_dz_plugin_minversion { return 0 }

has dz_plugin_arguments => ( is => ro =>, lazy => 1, lazy_build => 1 );
sub _build_dz_plugin_arguments { return [] }

has prereq_to => ( is => ro =>, lazy => 1, lazy_build => 1 );
sub _build_prereq_to { return ['develop.requires'] }

sub mvp_aliases {
  return {
    q{>}                  => 'dz_plugin_arguments',
    q[dz_plugin_argument] => 'dz_plugin_arguments',
  };
}

sub mvp_multivalue_args {
  return qw( dz_plugin_arguments prereq_to );
}

sub load_plugins {
  my ( $self, $loader ) = @_;
  $loader->load_ini( $self->dz_plugin, $self->dz_plugin_name, $self->dz_plugin_arguments );
  return;
}

my $re_phases   = qr/configure|build|test|runtime|develop/msx;
my $re_relation = qr/requires|recommends|suggests|conflicts/msx;
my $re_prereq   = qr/\A($re_phases)[.]($re_relation)\z/msx;

sub register_prereqs {
  my ($self) = @_;
  my $prereqs = $self->zilla->prereqs;

  my @targets;

  for my $prereq ( @{ $self->prereq_to } ) {
    next if 'none' eq $prereq;
    if ( my ( $phase, $relation ) = $prereq =~ $re_prereq ) {
      push @targets, $prereqs->requirements_for( $phase, $relation );
    }
  }
  for my $target (@targets) {
    $target->add_string_requirement( Dist::Zilla::Util->expand_config_package_name( $self->dz_plugin ),
      $self->dz_plugin_minversion );
  }
  return;
}

no Moose::Role;

1;

=attr C<dz_plugin>

B<REQUIRED>

The C<plugin> identifier.

For instance, C<[GatherDir / Foo]> and C<[GatherDir]> approximation would both set this field to

  dz_plugin => 'GatherDir'

=attr C<dz_plugin_name>

The "Name" for the C<plugin>.

For instance, C<[GatherDir / Foo]> would set this value as

  dz_plugin_name => "Foo"

and C<[GatherDir]> approximation would both set this field to

  dz_plugin_name => "Foo"

In C<Dist::Zilla>, C<[GatherDir]> is equivalent to C<[GatherDir / GatherDir]>.

Likewise, if you do not specify C<dz_plugin_name>, the value of C<dz_plugin> will be used.

=attr C<dz_plugin_minversion>

The minimum version of C<dz_plugin> to use.

At present, this B<ONLY> affects C<prereq> generation.

=attr C<dz_plugin_arguments>

A C<mvp_multivalue_arg> attribute that creates an array of arguments
to pass on to the created plugin.

For convenience, this attribute has an alias of '>' ( mnemonic "Forward" ), so that the following example:

  [GatherDir]
  include_dotfiles = 1
  exclude_file = bad
  exclude_file = bad2

Would be written

  [YourPlugin]
  dz_plugin = GatherDir
  >= include_dotfiles = 1
  >= exclude_file = bad
  >= exclude_file = bad2

Or in crazy long form

  [YourPlugin]
  dz_plugin = GatherDir
  dz_plugin_argument = include_dotfiles = 1
  dz_plugin_argument = exclude_file = bad
  dz_plugin_argument = exclude_file = bad2

=attr C<prereq_to>

This determines where dependencies get injected.

Default is:

  develop.requires

And a special value

  none

Prevents dependency injection.

This attribute may be specified multiple times.

=method C<mvp_aliases>

=over 4

=item * C<dz_plugin_arguments=> can be written as C<< >= >> or C<< dz_plugin_argument= >>

=back

=method C<mvp_multivalue_args>

All of the following support multiple declaration:

=over 4

=item * C<dz_plugin_arguments>

=item * C<prereq_to>

=back

=method C<load_plugins>

This is where by default the child plugin itself is loaded.

If you want to make the loading of a child plugin conditional, wrapping
this method is recommended as follows:

  around load_plugins => sub {
    my ( $orig, $self, $loader ) = @_;
    # conditional code here
    return if $dont_load_them;
    return $self->$orig($loader);
  };

You can also do more fancy things with C<$loader>, but it is not advised.

=method C<register_prereqs>

By default, registers L</dz_plugin_package> version L</dz_plugin_minimumversion>
as C<develop.requires> ( as per L</prereq_to> ).


