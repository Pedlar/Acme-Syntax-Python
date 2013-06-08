use Test::More;
{
    package  Test::Class;
    use Test::More;
    sub  new { 
        my $class = shift; 
        my $self = {};
        $self->{test} = 1;
        return bless $self, $class;
     }
     sub  method1 { 
         my($self) = @_;
         use Data::Dumper;
         print Dumper($self->{test});
         ok($self->{test}, "Methods work!");
     }
}

my $tc = Test::Class->new();
$tc->method1();
