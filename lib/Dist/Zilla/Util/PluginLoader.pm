use 5.008;    # utf8
use strict;
use warnings;
use utf8;

package Dist::Zilla::Util::PluginLoader;

our $VERSION = '0.001003';

# ABSTRACT: Inflate a Legal Dist::Zilla Plugin from basic parts

# AUTHORITY

use Carp qw( croak );
use Moose qw( has );
use Dist::Zilla::Util;

has sequence      => ( is => ro =>, required   => 1 );
has assembler     => ( is => ro =>, lazy_build => 1 );
has section_class => ( is => ro =>, lazy_build => 1 );

no Moose;
__PACKAGE__->meta->make_immutable;

sub _build_assembler {
  my ($self) = @_;
  return $self->sequence->assembler;
}

sub _build_section_class {
  my ($self) = @_;
  return $self->assembler->section_class;
}

sub _split_ini_token {
  my ( undef, $token ) = @_;
  my ( $key,  $value ) = $token =~ /\A\s*([^=]+?)\s*=\s*(.+?)\s*\z/msx;
  return ( $key, $value );
}

sub _check_array {
  my ( undef, $array ) = @_;
  croak 'Attributes must be an arrayref' unless 'ARRAY' eq ref $array;
  for ( @{$array} ) {
    croak 'Attributes ArrayRef must contain no refs' if ref;
  }
  return $array;
}

sub _auto_attrs {
  my $nargs = ( my ( $self, $package, $name, $attrs ) = @_ );

  croak 'Not enough arguments to load()' if $nargs < 2;

  croak 'Argument <package> may not be a ref' if ref $package;

  if ( 2 == $nargs ) {
    return ( $package, $package, [] );
  }
  if ( 3 == $nargs ) {
    if ( 'ARRAY' eq ref $name ) {
      return ( $package, $package, $self->_check_array($name) );
    }
    return ( $package, $name, [] );
  }
  if ( 4 == $nargs ) {
    if ( not defined $name ) {
      return ( $package, $package, $self->_check_array($attrs) );
    }
    if ( ref $name ) {
      croak "Illegal value $name for <name>";
    }
    return ( $package, $name, $self->_check_array($attrs) );
  }
  croak 'Too many arguments to load()';
}

sub load {
  my ( $self, @args ) = @_;
  my ( $package, $name, $attrs ) = $self->_auto_attrs(@args);

  croak 'Not an even number of attribute values, should be a key => value sequence.' if ( scalar @{$attrs} % 2 ) != 0;

  my $child_section = $self->section_class->new(
    name    => $name,
    package => Dist::Zilla::Util->expand_config_package_name($package),
  );
  my @xattrs = @{$attrs};
  while (@xattrs) {
    my ( $key, $value ) = splice @xattrs, 0, 2, ();
    $child_section->add_value( $key, $value );
  }
  $self->sequence->add_section($child_section);
  $child_section->finalize unless $child_section->is_finalized;
  return;
}

sub load_ini {
  my ( $self, @args ) = @_;
  my ( $package, $name, $attrs ) = $self->_auto_attrs(@args);
  return $self->load( $package, $name, [ map { $self->_split_ini_token($_) } @{$attrs} ] );
}


1;

=head1 SYNOPSIS

  use Dist::Zilla::Util::PluginLoader;

  my $loader = Dist::Zilla::Util::PluginLoader->new( sequence => $sequence );
  $loader->load( $plugin, $name, [ key => value , key => value ]);
  $loader->load_ini( $plugin, $name, [ 'key = value', 'key = value' ] );

=attr C<sequence>

A C<Config::MVP::Sequence> object.

The easiest way to get one of those is:

  around plugin_from_config {
    my ($orig,$self,$name,$arg, $section ) = @_;
                                ^^^^^^^^
  }

=attr C<assembler>

A C<Config::MVP::Assembler>

Defaults to C<< sequence->assembler >>

=attr C<section_class>

Defaults to C<< assembler->section_class >>

=method C<load>

Load a Dist::Zilla plugin meeting specification.

Signatures:

  void load( $self, $plugin )
  void load( $self, $plugin, \@args );
  void load( $self, $plugin, $name  );
  void load( $self, $plugin, $name, \@args );

  $plugin is Str ( Dist::Zilla Plugin )
  $name   is Str ( Dist::Zilla Section Name )
  @args   is ArrayRef
              num items == even
              key => value pairs of scalars.

Constructs an instance of C<$plugin>, using C<$name> where possible,
and uses C<@args> to populate the C<MVP> properties for that C<$plugin>,
and then injects it to the C<< ->sequence >> passed earlier.

=method C<load_ini>

Load a Dist::Zilla plugin meeting specification with unparsed
C<INI> C<key = value> strings.

Signatures:

  void load( $self, $plugin )
  void load( $self, $plugin, \@args );
  void load( $self, $plugin, $name  );
  void load( $self, $plugin, $name, \@args );

  $plugin is Str ( Dist::Zilla Plugin )
  $name   is Str ( Dist::Zilla Section Name )
  @args   is ArrayRef of Str
            each Str is 'key = value'

Constructs an instance of C<$plugin>, using C<$name> where possible,
and parses and uses C<@args> to populate the C<MVP> properties for that C<$plugin>,
and then injects it to the C<< ->sequence >> passed earlier.

=cut
