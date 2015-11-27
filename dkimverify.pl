#!/usr/bin/perl -I../lib
#
# Copyright (c) 2005-2006 Messiah College. This program is free software.
# You can redistribute it and/or modify it under the terms of the
# GNU Public License as found at http://www.fsf.org/copyleft/gpl.html.
#
# Written by Jason Long, jlong@messiah.edu.

use strict;
use warnings;

use Mail::DKIM::Verifier;

sub printwrap {
	my ($hdr, $len, $indent, $wraptxt) = @_;
	my @words = split(/\s+/,$hdr);
	my $firstword = shift(@words);
	print $firstword;
	my $sofar = length($firstword);
	foreach my $word (@words) {
		if (($sofar + length($word) + 1) < $len) {
			print " $word";
			$sofar += length($word) + 1;
		} else {
			print $wraptxt . "$indent$word";
			$sofar = length($indent) + length($word);
		}
	}
	print $wraptxt;
}

my $dkim = new Mail::DKIM::Verifier();
while (<STDIN>)
{
	chomp;
	s/\015$//;
	$dkim->PRINT("$_\015\012");
}
$dkim->CLOSE;

printwrap("X-DKIM-Originator: ".$dkim->message_originator->address, 72, "  ", "\r\n");
my $pol_det_str = "";
foreach my $policy ($dkim->policies) {
	if (ref($policy) eq "Mail::DKIM::DkPolicy") {
		$pol_det_str .= "dk_";
	} else {
		$pol_det_str .= "dkim_";
	}
	$pol_det_str .= $policy->name . "=" . $policy->apply($dkim) . "; ";
}
$pol_det_str =~ s/;\s+$//;
printwrap("X-DKIM-Policy-Detail: $pol_det_str", 72, "  ", "\r\n");

## In order to uncomment the following, you must define a valid
## $host_identifier

#my $host_identifier="example.com"
#my $ar_str = "";
#my $dksigs = 0;
#my $dkimsigs = 0;
#foreach my $signature ($dkim->signatures) {
#	if (ref($signature) eq "Mail::DKIM::DkSignature") {
#		$ar_str .= "  domainkeys=" . $signature->result_detail . " ";
#		$dksigs++;
#	} else {
#		$ar_str .= "  dkim=";
#		if ($signature->result eq "fail") {
#			my @policies = $dkim->policies;
#			my $marked = 0;
#			foreach my $policy (@policies) {
#				my $result = $policy->apply($dkim);
#				if ($result eq "reject") {
#					$ar_str .= $signature->result_detail . " ";
#					$marked = 1;
#					last;
#				} elsif ($result eq "neutral") {
#					$ar_str .= "policy (failure is neutral according to " . $policy->name . ") ";
#					$marked = 1;
#					last;
#				}
#			}
#			if ($marked == 0) {
#				$ar_str .= "pass (failure is fine according to sender and author) ";
#			}
#		} else {
#			$ar_str .= $signature->result_detail . " ";
#		}
#		$dkimsigs++;
#	}
#	$ar_str .= "header.i=".$signature->identity . ";";
#}
#if ($dksigs == 0) {
#	$ar_str .= "  domainkeys=none;";
#}
#if ($dkimsigs == 0) {
#	$ar_str .= "  dkim=none;";
#}
#if (exists $ENV{RELAYCLIENT} && exists $ENV{TCPREMOTEINFO}) {
#	# We assume it's smtp-auth
#	$ar_str .= "  auth=pass smtp.auth=".$ENV{TCPREMOTEINFO}.";";
#} else {
#	$ar_str .= "  auth=none;";
#}
#
#$ar_str =~ s/;\s*$//;
#printwrap("Authentication-Results: $host_identifier; $ar_str\r\n", 72, "  ", "\r\n");
