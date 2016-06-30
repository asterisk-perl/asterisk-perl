#Just do some simple tests to make sure the basic stuff works
use strict;
use Test::More;

use lib '../lib';
use lib 'lib';

my $module_name = 'Asterisk::Outgoing';

use_ok($module_name) or exit;

my $object = $module_name->new();

isa_ok($object, $module_name);

my @methods = qw(outdir outtime checkvariable setvariable create_outgoing);

can_ok( $module_name, @methods);

ok($object->outdir() eq "/var/spool/asterisk/outgoing", "Default outdir value");
ok($object->outdir("/var/outgoing") eq "/var/outgoing", "Custom outdir value");

done_testing();