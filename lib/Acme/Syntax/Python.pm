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
        /^(\s*)/;
        my $depth = length ( $1 );
        if($depth < (4 * $self->{_block_depth})) {
            if($self->{_lambda_block}->{$self->{_block_depth}}) {
                $self->{_lambda_block}->{$self->{_block_depth}} = 0;
                s/^/\};\n/;
            } elsif ($self->{_class_block}->{$self->{_block_depth}}){
                $self->{_class_block}->{$self->{_block_depth}} = 0;
                s/^/return bless \$self, \$class;\n\}\n/;
            } else {
                s/^/\}\n/;
            }
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

    s{True}{1}gmx;
    s{False}{0}gmx;

    if(/class (.+):/) {
        s{class (.+):}{\{\npackage $1;\n}gmx;
        $self->{_in_block} = 1;
        ++ $self->{_block_depth};
    }

    #Handle def with Params
    if(/lambda\((.+)\):/) {
        s{lambda\((.+)\):}{sub \{ my($1) = \@_;}gmx;
        $self->{_in_block} = 1;
        ++ $self->{_block_depth};
        $self->{_lambda_block}->{$self->{_block_depth}} = 1;
    }

    #Handle def with no Params
    if(/lambda:/) {
        s{lambda:}{sub \{};
        $self->{_in_block} = 1;
        ++ $self->{_block_depth};
        $self->{_lambda_block}->{$self->{_block_depth}} = 1;
    }

    #Handle def with Params
    if(/def (.+)\((.+)\):/) {
        if($1 eq "__init__") {
            s{def (.+)\((.+)\):}{sub $1 \{ my(\$class, $2) = \@_;\nmy \$self = \{\};}gmx;
            $self->{_class_block}->{($self->{_block_depth} + 1)} = 1;
        } else {
            s{def (.+)\((.+)\):}{sub $1 \{ my($2) = \@_;}gmx;
        }
        $self->{_in_block} = 1;
        ++ $self->{_block_depth};
    }
    
    #Handle def with no Params
    if(/def (.+):/) {
        if($1 eq "__init__") {
            s{def (.+):}{sub $1 \{ my (\$class) = shift; my \$self = \{\};}gmx;
            $self->{_class_block}->{($self->{_block_depth} + 1)} = 1;	
        } else {
            s{def (.+):}{sub $1 \{}gmx;
        }
        $self->{_in_block} = 1;
        ++ $self->{_block_depth};
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
        $self->{_in_block} = 1;
        ++ $self->{_block_depth};
    }
    if(/else:/) {
        s{:$}{\{}gmx;
        $self->{_in_block} = 1;
        ++ $self->{_block_depth};
    }


#    print "$_";
    return $status;
}

1;
