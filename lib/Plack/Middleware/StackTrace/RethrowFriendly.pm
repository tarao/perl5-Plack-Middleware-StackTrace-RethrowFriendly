package Plack::Middleware::StackTrace::RethrowFriendly;
use strict;
use warnings;

# core
use Scalar::Util 'refaddr';

# cpan
use parent qw(Plack::Middleware::StackTrace);
use Try::Tiny;

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
