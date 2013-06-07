use Acme::Syntax::Python;
from Data::Dumper import Dumper, DumperX;


def test:
    print "hello\n";
    def test2:
        print "hello2\n";
    if (@ARGV[0] eq "second"):
        test2();
    elif (@ARGV[0] eq "third"
      and @ARGV[1] eq "so"):
        print "I guess I'll be third....\n";
    else:
        print "I dun wana be second....\n";
    sub perltest2 {
        print "This is a perl sub in a Python sub\n";
    }
    perltest2();


sub perltest {
    print "Perl Subs still work too\n";
}

def param_test($var1, $var2):
    print "Var1: $var1\nVar2: $var2\n";

if (True == 1):
    print "Hoorah\n";

if(@ARGV[0] eq "perlif") {
    print "Normal Perl Ifs still work too\n";
}

test();
perltest();
param_test("Hello1", "Hello2");
