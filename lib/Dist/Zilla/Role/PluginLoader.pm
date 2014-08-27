use 5.008;    # utf8
use strict;
use warnings;
use utf8;

package Dist::Zilla::Role::PluginLoader;

our $VERSION = '0.001000';

# ABSTRACT: A Plugin that can load others.

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY

use Moose::Role qw( has around with requires );
use Dist::Zilla::Util::PluginLoader;

requires 'load_plugins';

around plugin_from_config => sub {
  my ( $orig, $plugin_class, $name, $arg, $own_section ) = @_;
  my $own_object = $plugin_class->$orig( $name, $arg, $own_section );
  my $loader = Dist::Zilla::Util::PluginLoader->new( sequence => $own_section->sequence );
  $own_object->load_plugins($loader);
  return $own_object;
};

no Moose::Role;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Role::PluginLoader - A Plugin that can load others.

=head1 VERSION

version 0.001000

=head1 AUTHOR

Kent Fredric <kentfredric@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
