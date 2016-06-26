#Just do some simple tests to make sure the basic stuff works
use strict;
use Test::More;

use lib '../lib';
use lib 'lib';

BEGIN { plan tests => 3}

my $module_name = 'Asterisk::Voicemail';

use_ok($module_name) or exit;

my $object = $module_name->new();

isa_ok($object, $module_name);

my @methods = qw( spooldirectory sounddirectory serveremail format vmbox getfolders
configfile readconfig appendsoundfile validmailbox msgcount msgcountstr
createdefaultmailbox messages);

can_ok( $module_name, @methods);