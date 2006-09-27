#Just do some simple tests to make sure the basic stuff works
use strict;
use Test;

use lib '../lib';
use lib 'lib';

BEGIN { plan tests => 2 }

use Asterisk::AGI;

my $AGI = new Asterisk::AGI;

my $fh;
open($fh, "<t/agi.head") || die;
my %vars = $AGI->ReadParse($fh);
close($fh);
ok(%vars);
open($fh, "<t/agi.goodresponse") || die;
my $response = $AGI->_readresponse($fh);
ok($response);
