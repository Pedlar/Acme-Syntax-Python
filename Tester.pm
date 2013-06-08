use lib './lib';
use Acme::Syntax::Python debug => 1;
class Tester inherits File::Find:
    def test:
        return "Test\n";
1;
