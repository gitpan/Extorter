# ABSTRACT: Import Routines By Any Means Necessary
package Extorter;

use 5.10.0;

use strict;
use warnings;

use Import::Into;

our $VERSION = '0.05'; # VERSION

sub import {
    my $class  = shift;
    my $target = caller;

    my @imports = @_ or return;
    $class->extort::into($target, $_) for @imports;

    return;
}

sub extort::into {
    my $class  = shift;
    my $target = shift;

    my @imports = @_ or return;

    @imports = map join('::', $imports[0], $_), @imports[1..$#imports]
        if @imports > 1;

    my %seen;
    for my $import (@imports) {
        my @captures = $import =~ /(.*)(?:\^|::)(.*)/;
           @captures = $import =~ /^\*(.*)/ unless @captures;

        my ($namespace, $argument) = @captures;
        next unless $namespace;

        unless ($argument) {
            $namespace->import::into($target);
            next;
        }

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

version 0.05

=head1 SYNOPSIS

    use Extorter qw(

        *utf8
        *strict
        *warnings

        feature^say
        feature^state

        Carp::croak
        Carp::confess

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

Extorter accepts a list of fully-qualified declarations. The verbosity of the
declarations are meant to promote explicit, clean, and reasonable import lists.
Extorter has the added bonus of extracting functionality from packages which may
not have originally been designed to be imported. Declarations are handled in
the order in which they're declared, which means, as far as the import and/or
extraction order goes, the last routine declared will be the one available to
your program and any C<redefine> warnings will be suppressed. This is a feature
not a bug. NOTE: Any declaration prefixed with an asterisk is assumed to be a
fully-qualified namespace of a package and is imported directly.

=head1 FUNCTIONS

=head2 extort::into

The C<into> function declared in the C<extort> package, used as a kind of global
method invokable by any package, is designed to load and import the specified
C<@declarations>, as showcased in the synopsis, into the C<$target> package.

    $package->extort::into($target, @declarations);

    e.g.

    $package->extort::into($package, 'Scalar::Util::refaddr');
    $package->extort::into($package, 'Scalar::Util::reftype');

    $package->extort::into($target, 'List::AllUtils::firstval');
    $package->extort::into($target, 'List::AllUtils::lastval');

Additionally, this function supports a 3-argument version, where the 3rd option
is a list of arguments that will be automatically concatenated with the
C<$target> package to provide the necessary declarations. The following is an
example:

    $package->extort::into($package, 'Scalar::Util', qw(refaddr reftype));
    $package->extort::into($target, 'List::AllUtils', qw(firstval lastval));

=head1 VERSIONS AND FEATURES

Declaring version requirements and version-specific features is handled a bit
differently. As mentioned in the description, any declaration prefixed with an
asterisk is assumed to be a fully-qualified namespace of a package and is
imported directly. This works for modules as well as pragmas like C<strict>,
C<warnings>, C<utf8>, and others. However, this does not work for declaring a
Perl version or version-specific features. Currently, there is no single
declaration which will allow you to configure Extorter to implement them but
the following approach is equivalent:

    use 5.18.0;

The Perl version requirement will be enforced whenever a scope issuing the
B<use VERSION> declaration is found, i.e. as long as you ensure that declaration
is seen, the version requirement will be enforced for your program. So now we
just need to figure out how to import features into the calling namespace using
Extorter. The following approach works towards that end:

    use 5.18.0;
    use Extorter qw(*strict *warnings feature^:5.18);

=head1 EXTORTER AND EXPORTER

You can use Extorter with the L<Exporter> module, to create a sophisticated
exporter which implements the Exporter interface. The following is an example:

    package MyApp::Imports;

    use Extorter;
    use base 'Exporter';

    our @EXPORT_OK = qw(
        greeting
    );

    our @IMPORTS = qw(
        List::AllUtils::firstval
        List::AllUtils::lastval
    );

    sub greeting {
        'Hello World'
    }

    sub import {
        my ($class, $target) = (shift, caller);
        $class->extort::into($target, $_) for @IMPORTS;
        return $class->export_to_level(2, $target);
    }

    1;

=head1 AUTHOR

Al Newkirk <anewkirk@ana.io>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Al Newkirk.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
