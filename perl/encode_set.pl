#!/usr/bin/perl
#
# encode_set.pl
# encodeパラメータを上書きするためのスクリプト
#
#
use DBI;
#use DBD::Pg;
use DBD::SQLite;
use Jcode;

$path = $0;
$path =~ s/encode_set.pl$//i;
if ($path ne "./"){
	push( @INC, "$path");
}
require "foltialib.pl";

$dbh=DBI->connect($DSN, $DBUser, $DBPass)||die $DBI::error;
$sth=$dbh->prepare('select m2pfilename from foltia_subtitle where filestatus=999');
$sth->execute();

while(my $ref = $sth->fetch ){
	&encode_set($ref);
}

sub encode_set{
	$sth=$dbh->prepare('update foltia_subtitle set filestatus=? WHERE foltia_subtitle.m2pfilename = ?');
	$sth->execute(70,$_[0]);
}

