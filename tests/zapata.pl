#!/usr/bin/perl

use lib './lib', '../lib';

use Asterisk::Zapata;

use Data::Dumper;

my $zt = new Asterisk::Zapata;

$zt->readconfig();

print Dumper $zt;
