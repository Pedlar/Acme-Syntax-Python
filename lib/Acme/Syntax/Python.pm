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
        _block_depth => 0,
        _lambda_block => {},
        _class_block => {}
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
        if($self->{_in_block}) {
            $_ = "}\n";
            ++ $status;
            $self->{_in_block} = 0;
        }
        return $status;
    }

    if($self->{_in_block}) {
        _handle_block($self, $_);
    }

    s{^\s*import (.+);$}
     {use $1;}gmx;
    s{^\s*from (.+) import (.+);$}
     {use $1 ($2);}gmx;

    s{True}{1}gmx;
    s{False}{0}gmx;

    if(/class (.+):/) {
        s{class (.+):}{\{\npackage $1;\n}gmx;
        _start_block($self);
    }

    #Handle def with Params
    if(/lambda\((.+)\):/) {
        s{lambda\((.+)\):}{sub \{ my($1) = \@_;}gmx;
        _start_block($self, "_lambda_block");
    }

    #Handle def with no Params
    if(/lambda:/) {
        s{lambda:}{sub \{};
        _start_block($self, "_lambda_block");
    }

    #Handle def with Params
    if(/def (.+)\((.+)\):/) {
        if($1 eq "__init__") {
            s{def (.+)\((.+)\):}{sub $1 \{ my(\$class, $2) = \@_; my \$self = \{\};}gmx;
            $self->{_class_block}->{($self->{_block_depth} + 1)} = 1;
        } else {
            s{def (.+)\((.+)\):}{sub $1 \{ my($2) = \@_;}gmx;
        }
        _start_block($self);
    }
    
    #Handle def with no Params
    if(/def (.+):/) {
        if($1 eq "__init__") {
            s{def (.+):}{sub $1 \{ my (\$class) = shift; my \$self = \{\};}gmx;
            $self->{_class_block}->{($self->{_block_depth} + 1)} = 1;	
        } else {
            s{def (.+):}{sub $1 \{}gmx;
        }
        _start_block($self);
    }
    
    s{__init__}{new}gmx;

    if(/elif (.+)/) {
	s{elif (.+)}{elsif $1}gmx;
    }
    elsif(/if (.*)/) {
        s{if (.*)}{if $1}gmx;
    }
    if(/\):$/) {
        s{:$}{ \{}gmx;
        _start_block($self);
    }
    if(/else:/) {
        s{:$}{\{}gmx;
        _start_block($self);
    }


    print "$_";
    return $status;
}

sub _handle_spacing {
    my $depth = shift;
    my $modifier = shift // 1;
    return (' ') x (4 * ($depth - $modifier));
}

sub _start_block {
    my ($self, $type) = @_;
    $self->{_in_block} = 1;
    ++ $self->{_block_depth};
    if(defined($type)) {
        $self->{$type}->{$self->{_block_depth}} = 1;
    }
}

sub _handle_block {
        my ($self) = @_;
        /^(\s*)/;
        my $depth = length ( $1 );
        if($depth < (4 * $self->{_block_depth})) {
            my $spaces = _handle_spacing($self->{_block_depth});
            if($self->{_lambda_block}->{$self->{_block_depth}}) {
                $self->{_lambda_block}->{$self->{_block_depth}} = 0;
                s/^/$spaces\};\n/;
            } elsif ($self->{_class_block}->{$self->{_block_depth}}){
                my $spaces_front = _handle_spacing($self->{_block_depth}, 0);
                $self->{_class_block}->{$self->{_block_depth}} = 0;
                s/^/$spaces_front return bless \$self, \$class;\n$spaces\}\n/;
            } else {
                s/^/$spaces\}\n/;
            }
            -- $self->{_block_depth};
	}
        if($self->{_block_depth} == 0) {
            $self->{_in_block} = 0;
        }
}

1;
