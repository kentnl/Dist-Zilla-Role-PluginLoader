use 5.008;    # utf8
use strict;
use warnings;
use utf8;

package Dist::Zilla::Role::PluginLoader;

our $VERSION = '0.001000';

# ABSTRACT: A Plugin that loads another

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY

use Moose::Role qw( has around with requires );
use Dist::Zilla::Util::ConfigDumper qw( config_dumper );

with 'Dist::Zilla::Role::PrereqSource';













has dz_plugin => ( is => ro =>, required => 1 );



















has dz_plugin_name => ( is => ro =>, lazy => 1, lazy_build => 1 );
sub _build_dz_plugin_name { my ($self) = @_; return $self->dz_plugin; }









has dz_plugin_minversion => ( is => ro =>, lazy => 1, lazy_build => 1 );
sub _build_dz_plugin_minversion { return 0 }

































has dz_plugin_arguments => ( is => ro =>, lazy => 1, lazy_build => 1 );
sub _build_dz_plugin_arguments { [] }









has dz_plugin_package => ( is => ro =>, lazy => 1, lazy_build => 1 );

sub _build_dz_plugin_package {
  my ($self) = @_;
  return Dist::Zilla::Util->expand_config_package_name( $self->dz_plugin );
}

around 'dump_config' => config_dumper( __PACKAGE__,
  qw( dz_plugin dz_plugin_name dz_plugin_package dz_plugin_minversion dz_plugin_arguments prereq_to ) );











sub mvp_aliases {
  return {
    q{>}                  => 'dz_plugin_arguments',
    q[dz_plugin_argument] => 'dz_plugin_arguments',
  };
}















sub mvp_multivalue_args {
  return qw( dz_plugin_arguments prereq_to );
}

sub _split_ini_token {
  my ( undef, $token ) = @_;
  my ( $key,  $value ) = $token =~ /\A\s*([^=]+?)\s*=\s*(.+?)\s*\z/msx;
  return ( $key, $value );
}

sub load_dz_plugin {
  my ( $self, $parent_section ) = @_;

  # Here is where we construct the conditional plugin
  my $assembler     = $parent_section->sequence->assembler;
  my $child_section = $assembler->section_class->new(
    name     => $self->dz_plugin_name,
    package  => $self->dz_plugin_package,
    sequence => $self->sequence,
  );

  # Here is us, adding the arguments to that plugin
  for my $argument ( @{ $self->dz_plugin_arguments } ) {
    $child_section->add_value( $self->_split_ini_token($argument) );
  }
  ## And this is where the assembler injects into $zilla->plugins!
  $child_section->finalize();
  return;
}

sub plugin_loader {
  my ( $self, $parent_section ) = @_;
  $self->load_dz_plugin($parent_section);
  return;
}

around plugin_from_config => sub {
  my ( $orig, $plugin_class, $name, $arg, $own_section ) = @_;
  my $own_object = $plugin_class->$orig( $name, $arg, $own_section );
  $own_object->pluginloader($own_section);
  return $own_object;
};







my $re_phases = qr/configure|build|test|runtime|develop/msx;
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
    $target->add_string_requirement( $self->dz_plugin_package, $self->dz_plugin_minversion );
  }
  return;
}
no Moose::Role;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Role::PluginLoader - A Plugin that loads another

=head1 VERSION

version 0.001000

=head1 METHODS

=head2 C<mvp_aliases>

=over 4

=item * C<dz_plugin_arguments=> can be written as C<< >= >> or C<< dz_plugin_argument= >>

=back

=head2 C<mvp_multivalue_args>

All of the following support multiple declaration:

=over 4

=item * C<dz_plugin_arguments>

=item * C<prereq_to>

=back

=head2 C<register_prereqs>

By default, registers L</dz_plugin_package> version L</dz_plugin_minimumversion>
as C<develop.requires> ( as per L</prereq_to> ).

=head1 ATTRIBUTES

=head2 C<dz_plugin>

B<REQUIRED>

The C<plugin> identifier.

For instance, C<[GatherDir / Foo]> and C<[GatherDir]> approximation would both set this field to

  dz_plugin => 'GatherDir'

=head2 C<dz_plugin_name>

The "Name" for the C<plugin>.

For instance, C<[GatherDir / Foo]> would set this value as

  dz_plugin_name => "Foo"

and C<[GatherDir]> approximation would both set this field to

  dz_plugin_name => "Foo"

In C<Dist::Zilla>, C<[GatherDir]> is equivalent to C<[GatherDir / GatherDir]>.

Likewise, if you do not specify C<dz_plugin_name>, the value of C<dz_plugin> will be used.

=head2 C<dz_plugin_minversion>

The minimum version of C<dz_plugin> to use.

At present, this B<ONLY> affects C<prereq> generation.

=head2 C<dz_plugin_arguments>

A C<mvp_multivalue_arg> attribute that creates an array of arguments
to pass on to the created plugin.

For convenience, this attribute has an alias of '>' ( mnemonic "Forward" ), so that the following example:

  [GatherDir]
  include_dotfiles = 1
  exclude_file = bad
  exclude_file = bad2

Would be written

  [if]
  dz_plugin = GatherDir
  ?= $ENV{dogatherdir}
  >= include_dotfiles = 1
  >= exclude_file = bad
  >= exclude_file = bad2

Or in crazy long form

  [if]
  dz_plugin = GatherDir
  condtion = $ENV{dogatherdir}
  dz_plugin_argument = include_dotfiles = 1
  dz_plugin_argument = exclude_file = bad
  dz_plugin_argument = exclude_file = bad2

=head2 C<dz_plugin_package>

This is an implementation detail which returns the expanded name of C<dz_plugin>

You could probably find some evil use for this, but I doubt it.

=head1 AUTHOR

Kent Fredric <kentfredric@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
