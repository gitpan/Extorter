# ABSTRACT: Import Routines By Any Means Necessary
package Extorter;

use 5.10.0;

use strict;
use warnings;

use Import::Into;

our $VERSION = '0.02'; # VERSION

sub import {
    my $class  = shift;
    my $target = caller;

    my @declarations = @_ or return;

    my %seen;
    for my $declaration (@declarations) {
        my ($namespace, $argument) = (
            $declaration =~ /(.*)(?:\^|::)(.*)/
        );

        next unless $namespace;
        next unless $argument;

        $seen{$namespace}++
            || eval "require $namespace";

        if ($argument =~ /\W/) {
            $namespace->import::into($target, $argument);
            next;
        }

        no strict 'refs';
        my %EXPORT_TAGS = %{"${namespace}::EXPORT_TAGS"};
        if ($EXPORT_TAGS{$argument}) {
            $namespace->import::into($target, $argument);
            next;
        }

        if ($namespace->can($argument)) {
            no warnings 'redefine';
            *{"${target}::${argument}"} = \&{"${namespace}::${argument}"};
            next;
        }

        # fallback
        $namespace->import::into($target, $argument);
    }

    return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Extorter - Import Routines By Any Means Necessary

=head1 VERSION

version 0.02

=head1 SYNOPSIS

    use Extorter qw(
        feature^say
        feature^state

        Data::Dump::dump

        Digest::SHA1::sha1_hex
        Digest::SHA1::sha1_base64

        Encode::encode_utf8
        Encode::decode_utf8

        IO::All::io

        List::AllUtils::distinct
        List::AllUtils::firstval
        List::AllUtils::lastval
        List::AllUtils::pairs
        List::AllUtils::part
        List::AllUtils::uniq

        Memoize::memoize

        Scalar::Util::blessed
        Scalar::Util::refaddr
        Scalar::Util::reftype
        Scalar::Util::weaken
    );

=head1 DESCRIPTION

The Extorter module allows you to create import lists which extract routines
from the package(s) specified. It will import routines found in the package
variables C<@EXPORT>, C<@EXPORT_OK> and C<%EXPORT_TAGS>, or, extract routines
defined in the package which are not explicitly exported. Otherwise, as a last
resort, Extorter will try to load the package, using a parameterized C<use>
statement, in the event that the package has a custom or magical importer that
does not conform to the L<Exporter> interface.

Extorter accepts a list of fully-qualified declarations. Although the Extorter
syntax may seem strange (uncommon), it is designed to be useful in a variety of
circumstances, as well as promote clean and reasonable import lists. It has the
added bonus of extracting functionality from packages which may not have
originally been designed to be imported. Declarations are handled in the order
in which they're declared, which means, as far as the import and/or extraction
order goes, the last routine declared will be the one available to your program
and any C<redefine> warnings will be suppressed. This is a feature not a bug.

=head1 AUTHOR

Al Newkirk <anewkirk@ana.io>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Al Newkirk.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
