use strict;
use warnings;
package Acme::Syntax::Python;
use Filter::Util::Call;
use vars qw($VERSION);

$VERSION = "0.01";

#ABSTRACT: 

sub import {
    my ($type) = @_;
    my (%context) = (
        _filename => (caller)[1],
        _line_no => 0,
        _last_begin => 0,
        _in_block => 0,
        _block_depth => 0
    );
    filter_add(bless \%context);
}

sub error {
    my ($self) = shift;
    my ($message) = shift;
    my ($line_no) = shift || $self->{last_begin};
    die "Error: $message at $self->{_filename} line $line_no.\n"
}

sub warning {
    my ($self) = shift;
    my ($message) = shift;
    my ($line_no) = shift || $self->{last_begin};
    warn "Warning: $message at $self->{_filename} line $line_no.\n"
}

sub filter {
    my ($self) = @_;
    my ($status);
    $status = filter_read();
    ++ $self->{line_no};
    if ($status <= 0) {
       return $status;
    }

    if($self->{_in_block}) {
        /^(\s*)/;
        my $depth = length ( $1 );
        if($depth <= (4 * $self->{_block_depth})) {
            s/^/\}/;
            -- $self->{_block_depth};
	}
        if($self->{_block_depth} == 0) {
            $self->{_in_block} = 0;
        }
    }

    s{^\s*import (.+);$}
     {use $1;}gmx;
    s{^\s*from (.+) import (.+);$}
     {use $1 ($2);}gmx;

    if(/def (.+):/) {
        s{def (.+):}{sub $1 \{};
        $self->{_in_block} = 1;
        ++ $self->{_block_depth};
    }

    if(/if \((.*)\):/) {
        s{:$}{\{}gmx;
        $self->{_in_block} = 1;
        ++ $self->{_block_depth};
    }

    return $status;
}

1;
