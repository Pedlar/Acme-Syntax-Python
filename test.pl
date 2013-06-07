use Acme::Syntax::Python;
from Data::Dumper import Dumper, DumperX;


def test:
    print "hello\n";
    def test2:
        print "hello2\n";
    if (@ARGV[0] eq "second"):
        test2();

sub perltest {
    print "Perl Subs still work too\n";
}
test();
perltest();
