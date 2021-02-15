package Slim::Plugin::DisplayTest::Plugin;

# (C) 2020 Johannes Franke IT Services
# Version: 0.1
# Date:    2020-06-10
# all of the following was largely stolen from the Tetris game plugin
# This plugin's purpose is to completely illuminate the VFDs (vacuum fluorescent displays) in older Squeezebox models:
#   * v1 (280x16 pixels)
#   * v2 (320x32 pixels)
#   * v3 a.k.a. Classic (320x32 pixels)
#   * Boom (160x32 pixels)
#   * Transporter (two displays each featuring 320x32 pixels)
# The "all-pixels on" mode rendered by this plugin gives a good impression of how burnt-out parts of the display may be,
# and whether it may be time to replace it / them

# Logitech Media Server Copyright 2001-2020 Logitech.
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License, 
# version 2.

use strict;
use base qw(Slim::Plugin::Base);
use Slim::Utils::Log;

our $VERSION = substr(q$Revision: 0.1 $,10);

my $log = Slim::Utils::Log->addLogCategory( {
	category     => 'plugin.displaytest',
	defaultLevel => 'INFO',
	description  => 'DISPLAYTEST',
} );

# constants
my $height = 4;
my $customchar = 1;
my $widthDivisor = 8;

# flag to avoid loading custom chars multiple times
my $loadedcustomchar = 0;

#
# state variables
# intentionally not per-client for multi-player goodness
#
my @grid = ();

# button functions for top-level home directory
sub defaultHandler {
	my $client = shift;

	resetView($client);
	$client->lines(\&lines);
	$client->update();
	return 0;
}

sub resetView {
	my $client = shift;
	my $width = $client->displayWidth() / $widthDivisor - 1;
	for (my $x = 0; $x < $width+2; $x++) {
		for (my $y = 0; $y < $height+2; $y++) {
				$grid[$x][$y] = 0;
		}
	}
}

sub getDisplayName
{
    return "Display Test";
}

sub playerMenu { 'SETTINGS' }

sub setMode {
	my $class  = shift;
	my $client = shift;

	if ($customchar) {
		loadCustomChars($client);
	}

	$client->modeParam('modeUpdateInterval', 1);

	$client->modeParam('knobFlags', Slim::Player::Client::KNOB_NOACCELERATION());
	$client->modeParam('knobWidth', 4);
	$client->modeParam('knobHeight', 25);
	$client->modeParam('listIndex', 1000);
	$client->modeParam('listLen', 0);
	
	# ensure we own the right-side display on Transporters (it will otherwise just flicker once per second and then fall back to whatever it usually displays)
	# stolen from the Snow screensaver :p
	$client->modeParam('screen2', 'DisplayTest');
	
	if ( main::DEBUGLOG && $log->is_debug ) 
	{
		$log->debug("Display type is");
		$log->debug($client);
		$log->debug($client->display);
	}
	
	$client->lines(\&lines);
}

my @bitmaps = (
	"\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff",
	"\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff",
	"\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff",
	"\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff",
);

my @bitmaps2 = (
	"\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff",
	"\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff",
	"\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff",
	"\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff",
);

my @bitmaps3 = (
	"\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff",
	"\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff",
	"\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff",
	"\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff",
);
#
# figure out the lines to be put up to display the directory
#
sub lines {
	my $client = shift;
	my ($line1, $line2);

	my $parts;

	my $width = $client->displayWidth() / $widthDivisor + 2;
	my @dispgrid = map [@$_], @grid;
	
	if ($client->isa("Slim::Player::Transporter")) {
		my $bits = '';
		for (my $x = 1; $x < $width+2; $x++)
			{	
				my $column = ($bitmaps2[$dispgrid[$x][1]] | $bitmaps2[$dispgrid[$x][2]*2]) . "\x00\x00";
				$column |= "\x00\x00" . ($bitmaps2[$dispgrid[$x][3]] | $bitmaps2[$dispgrid[$x][4]*2]);
				$bits .= $column;
			}
		$parts->{screen1}->{line} = $parts->{line};
		$parts->{screen1}->{overlay} = $parts->{overlay};
		$parts->{screen1}->{bits} = $bits;
		$parts->{screen2}->{bits} = $bits;

		#$parts->{screen1}->{bits} = $bits;
		#$parts->{screen2}->{bits} = $bits;
	} elsif ($client->display->isa( "Slim::Display::Squeezebox2")) {
		my $bits = '';
		for (my $x = 1; $x < $width+2; $x++)
			{	
				my $column = ($bitmaps2[$dispgrid[$x][1]] | $bitmaps2[$dispgrid[$x][2]*2]) . "\x00\x00";
				$column |= "\x00\x00" . ($bitmaps2[$dispgrid[$x][3]] | $bitmaps2[$dispgrid[$x][4]*2]);
				$bits .= $column;
			}
		$parts->{bits} = $bits;
	} elsif ($client->display->isa( "Slim::Display::SqueezeboxG")) {
		my $bits = '';
		for (my $x = 1; $x < $width+2; $x++)
			{	
				my $column = ($bitmaps2[$dispgrid[$x][1]] | $bitmaps2[$dispgrid[$x][2]*2]) . "\x00\x00";
				$column |= "\x00\x00" . ($bitmaps2[$dispgrid[$x][3]] | $bitmaps2[$dispgrid[$x][4]*2]);
				$bits .= $column;
			}
		$parts->{bits} = $bits;
	} else {
		
		my ($line1, $line2);
		for (my $x = 0; $x < 40; $x++)
			{
				$line1 .= grid2char($client);
				$line2 .= grid2char($client);
			}
		$parts = {
		    'line1' => $line1,
		    'line2' => $line2,
		};
	}
	return $parts;
}	

#
# convert numbers into characters.  should use custom characters.
#
sub grid2char {
	my $client = shift;

	if ($customchar) {
		return $client->symbols('block');
	} else {
		return "M";
	}
}

sub loadCustomChars {
	my $client = shift;

	return unless $client->display->isa('Slim::Display::Text');

	return if $loadedcustomchar;
	
	Slim::Display::Text::setCustomChar( 'block', ( 
		0b11111111, 0b11111111, 0b11111111, 0b11111111, 
		0b11111111, 0b11111111, 0b11111111, 0b11111111
		));
		
	$loadedcustomchar = 1;
}

1;

__END__
