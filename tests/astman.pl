#!/usr/bin/perl

use lib './lib', '../lib';

use Asterisk::Astman;

use Data::Dumper;

my $astman = new Asterisk::Astman;

$astman->readconfig();

print "PORT: " . $astman->port() . "\n";

print Dumper $astman;
