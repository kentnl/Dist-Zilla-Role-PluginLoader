use 5.008;    # utf8
use strict;
use warnings;
use utf8;

package Dist::Zilla::Util::PluginLoader;

# ABSTRACT: Inflate a Legal DZil Plugin from basic parts

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY

use Carp qw( croak );
use Moose qw( has );

has sequence      => ( is => ro =>, required   => 1 );
has assembler     => ( is => ro =>, lazy_build => 1 );
has section_class => ( is => ro =>, lazy_build => 1 );

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
  croak "Attributes must be an arrayref" unless "ARRAY" eq ref $array;
  if ( grep { ref $_ } @{$array} ) {
    croak "Attributes ArrayRef must contain no refs";
  }
  return $array;
}

sub _auto_attrs {
  my $nargs = ( my ( $self, $package, $name, $attrs ) = @_ );

  croak "Argument <package> may not be a ref" if ref $package;

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
  croak "Too many arguments to load()";
}

sub load {
  my ( $self, @args ) = @_;
  my ( $package, $name, $attrs ) = $self->_auto_attrs( @args );

  if ( scalar @{$attrs} % 2 & 1 ) {
    croak "Not an even number of attribute values, should be a key => value sequence.";
  }
  my $child_section = $self->section_class->new(
    name     => $name, 
    package  => $package,
    sequence => $self->sequence,
  );
  my @xattrs  = @{$attrs};
  while( @xattrs ) {
    my ( $key, $value ) = splice @xattrs, 0, 2, ();
    $child_section->add_value( $key, $value );
  }
  $child_section->finalize;
  return;
}
sub load_ini {
  my ( $self, @args ) = @_;
  my ( $package, $name, $attrs ) = $self->_auto_attrs( @args );
  return $self->load( $package, $name, [ map { $self->_split_ini( $_ ) } @{ $attrs } ]);
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Util::PluginLoader - Inflate a Legal DZil Plugin from basic parts

=head1 VERSION

version 0.001000

=head1 SYNOPSIS

  use Dist::Zilla::Util::PluginLoader;

  my $loader = Dist::Zilla::Util::PluginLoader->new( sequence => $sequence );
  $loader->load( $plugin, $name, [ key => value , key => value ]);
  $loader->load_ini( $plugin, $name, [ 'key = value', 'key = value' ] );

=head1 AUTHOR

Kent Fredric <kentfredric@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
