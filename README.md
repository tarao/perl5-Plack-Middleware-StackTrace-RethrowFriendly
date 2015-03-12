[![Build Status](https://travis-ci.org/tarao/perl5-Plack-Middleware-StackTrace-RethrowFriendly.svg?branch=master)](https://travis-ci.org/tarao/perl5-Plack-Middleware-StackTrace-RethrowFriendly)
# NAME

Plack::Middleware::StackTrace::RethrowFriendly - Display the original stack trace for rethrown errors

# SYNOPSIS

    use Plack::Builder;
    builder {
        enable "StackTrace::RethrowFriendly";
        $app;
    };

# DESCRIPTION

This middleware is the same as [Plack::Middleware::StackTrace](https://metacpan.org/pod/Plack::Middleware::StackTrace) except
that if you catch (`eval` or `try`-`catch` for example) an error
and rethrow (`die` or `croak` for example) it, the original stack
trace not the rethrown one is displayed.

When the response is displayed as an HTML, all the errors including
rethrown ones are visible through the throwing point selector at the
top of the HTML.

# SEE ALSO

[Plack::Middleware::StackTrace](https://metacpan.org/pod/Plack::Middleware::StackTrace)

# ACKNOWLEDGMENT

This implementation is a fork from a patch to
[Plack::Middleware::StackTrace](https://github.com/plack/Plack/compare/original-stacktrace) by Jesse Luehrs.

# LICENSE

Copyright (C) TOYAMA Nao and INA Lintaro

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

TOYAMA Nao <nanto@moon.email.ne.jp>

INA Lintaro <tarao.gnn@gmail.com>
