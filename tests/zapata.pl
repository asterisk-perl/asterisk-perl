#!/usr/bin/perl

use lib './lib', '../lib';

use Asterisk::Config::Zapata;

use Data::Dumper;

my $zt = new Asterisk::Config::Zapata;
$zt->options();
$zt->configfile('/etc/asterisk/zapata.conf');
$zt->readconfig();
print Dumper $zt;
#$zt->writeconfig();
