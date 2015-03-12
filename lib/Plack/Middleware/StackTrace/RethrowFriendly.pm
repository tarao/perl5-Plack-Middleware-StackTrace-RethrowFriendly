package Plack::Middleware::StackTrace::RethrowFriendly;
use strict;
use warnings;

# core
use Scalar::Util 'refaddr';

# cpan
use parent qw(Plack::Middleware::StackTrace);
use Try::Tiny;

our $VERSION = "0.01";

sub call {
    my($self, $env) = @_;

    my $trace;
    my $last_key = '';
    local $SIG{__DIE__} = sub {
        my $key = _make_key($_[0]);
        # If we get the same keys, the exception may be rethrown and
        # we keep the original stacktrace.
        if ($key ne $last_key) {
            $trace = $Plack::Middleware::StackTrace::StackTraceClass->new(
                indent => 1,
                message => munge_error($_[0], [ caller ]),
                ignore_package => __PACKAGE__,
            );
            $last_key = $key;
        }
        die @_;
    };

    my $caught;
    my $res = try {
        $self->app->($env);
    } catch {
        $caught = $_;
        _error('text/plain', $caught, 'no_trace');
    };

    if ($trace && $self->should_show_trace($caught, $last_key, $res)) {
        my $text = $trace->as_string;
        my $html = $trace->as_html;
        $env->{'plack.stacktrace.text'} = $text;
        $env->{'plack.stacktrace.html'} = $html;
        $env->{'psgi.errors'}->print($text) unless $self->no_print_errors;
        $res = ($env->{HTTP_ACCEPT} || '*/*') =~ /html/
            ? _error('text/html', $html)
            : _error('text/plain', $text);
    }
    # break $trace here since $SIG{__DIE__} holds the ref to it, and
    # $trace has refs to Standalone.pm's args ($conn etc.) and
    # prevents garbage collection to be happening.
    undef $trace;

    return $res;
}

sub should_show_trace {
    my ($self, $err, $key, $res) = @_;
    if ($err) {
        return _make_key($err) eq $key;
    } else {
        return $self->force && ref $res eq 'ARRAY' && $res->[0] == 500;
    }
}

sub no_trace_error { Plack::Middleware::StackTrace::no_trace_error(@_) }
sub munge_error { Plack::Middleware::StackTrace::munge_error(@_) }
sub utf8_safe { Plack::Middleware::StackTrace::utf8_safe(@_) }

sub _make_key {
    my ($val) = @_;
    if (!defined($val)) {
        return 'undef';
    } elsif (ref($val)) {
        return 'ref:' . refaddr($val);
    } else {
        return "str:$val";
    }
}

sub _error {
    my ($type, $content, $no_trace) = @_;
    $content = utf8_safe($content);
    $content = no_trace_error($content) if $no_trace;
    return [ 500, [ 'Content-Type' => "$type; charset=utf-8" ], [ $content ] ];
}

1;
__END__

=head1 NAME

Plack::Middleware::StackTrace::RethrowFriendly - Display the original stack trace for rethrown errors

=head1 SYNOPSIS

  use Plack::Builder;
  builder {
      enable "StackTrace::RethrowFriendly";
      $app;
  };

=head1 DESCRIPTION

This middleware is the same as L<Plack::Middleware::StackTrace> except
that if you catch (C<eval> or C<try>-C<catch> for example) an error
and rethrow (C<die> or C<croak> for example) it, the original stack
trace not the rethrown one is displayed.

=head1 SEE ALSO

L<Plack::Middleware::StackTrace>

=head1 ACKNOWLEDGMENT

This implementation is a fork from a patch to
L<Plack::Middleware::StackTrace|https://github.com/plack/Plack/compare/original-stacktrace> by Jesse Luehrs.

=head1 LICENSE

Copyright (C) TOYAMA Nao and INA Lintaro

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

TOYAMA Nao E<lt>nanto@moon.email.ne.jpE<gt>

INA Lintaro E<lt>tarao.gnn@gmail.comE<gt>

=cut
