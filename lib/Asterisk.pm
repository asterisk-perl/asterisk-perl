package Asterisk;

require 5.004;

=head1 NAME

Asterisk - Base Asterisk module

=head1 SYNOPSIS

stuff goes here

=head1 DESCRIPTION

description

=over 4

=cut

$VERSION = '0.01';

$DEBUG = 5;

sub version { $VERSION; }

sub new {
	my ($class, %args) = @_;
	my $self = {};
	bless $self, ref $class || $class;
#        while (my ($key,$value) = each %args) { $self->set($key,$value); }
	return $self;
}

sub DESTROY { }




1;
