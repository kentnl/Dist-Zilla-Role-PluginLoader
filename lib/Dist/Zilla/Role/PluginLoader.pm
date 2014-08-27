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

=head1 SYNOPSIS

  use Moose;
  with 'Dist::Zilla::Role::Plugin', 'Dist::Zilla::Role::PluginLoader';

  sub load_plugins {
    my ( $self, $loader ) = @_;
    # Load raw config
    $loader->load    ( 'GatherDir', 'GatherDir-for-FooPlugin',  [ include_dotfiles => 1, key => value,   ... ]);
    # Load using ini style input
    $loader->load_ini( 'GatherDir', 'GatherDir2-for-FooPlugin', [ 'include_dotfiles = 1', 'key = value', ... ]);
  }

=head1 WARNINGS

=head2 STOP

You probably don't want to use this module. You either want a C<@PluginBundle>, or L<<
C<PluginLoader::Configurable>
|Dist::Zilla::Role::PluginLoader::Configurable
>>

=head2 WHEN YOU WANT THIS MODULE

=over 4

=item * You don't want a plugin bundle

=item * You want something harder to understand for people who use your plugin.

=item * You B<I<EXPRESSLY>> wish to hide the loaded modules from things like L<< C<Dist::Zilla::App::Command::bakeini>|Dist::Zilla::App::Command::bakeini >>

=item * You are loading a single, or handful of modules, all of which are I<BLATANLY> obvious I<DIRECTLY> in C<dist.ini>, except with some special loading semantis.

=back

=head2 ADVICE

=over 4

=item * Do make consuming plugins have to declare the loaded plugin somehow

=item * Do make consuming plugins able to directly configure the loaded plugin somehow

=item * If at all possible, load at most, one plugin.

=item * If at all possible, and you are loading only one plugin, use L<< C<PluginLoader::Configurable>|Dist::Zilla::Role::PluginLoader::Configurable >>

=item * If you have read this far, and you still are considering using this Role, please contact me, C<kentnl> on C<#distzilla@irc.perl.org>, and let me convince you not to.

=back

=head1 AUTHOR

Kent Fredric <kentfredric@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
