#!/usr/bin/perl
#
# Example script to show how to use Asterisk::Manager
#
# Written by: James Golovich <james@gnuinter.net>
#
#

use lib './lib', '../lib';
use Asterisk::Manager;

$|++;

my $astmon = new Asterisk::Manager;

$astmon->user('test');
$astmon->secret('test');
$astmon->host('localhost');

$astmon->connect || die "Could not connect to " . $astmon->host() . "!\n";

$astmon->setcallback('Hangup', \&hangup_callback);
$astmon->setcallback('DEFAULT', \&default_callback);


#print STDERR $astmon->command('zap show channels');

print STDERR $astmon->sendcommand( Action => 'IAXPeers');

#print STDERR $astmon->sendcommand( Action => 'Originate',
#					Channel => 'Zap/7',
#					Exten => '500',
#					Context => 'default',
#					Priority => '1' );


$astmon->eventloop;

$astmon->disconnect;

sub hangup_callback {
	print STDERR "hangup callback\n";
}

sub default_callback {
	my (%stuff) = @_;
	foreach (keys %stuff) {
		print STDERR "$_: ". $stuff{$_} . "\n";
	}
	print STDERR "\n";
}
