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

#use lib "/tv/perl";
require "foltialib.pl";

$dbh=DBI->connect($DSN, $DBUser, $DBPass)||die $DBI::error;
$sth=$dbh->prepare('select m2pfilename from foltia_subtitle where filestatus=999');
$sth->execute();

while(my $ref = $sth->fetch ){
	&encode_set(@_)
}


sub encode_set{
	($filename) = @_;
	$dbh=DBI->connect($DSN,$DBUser,$DBPass)||die $DBI::error;
	$sth=$dbh->prepare('update foltia_subtitle set filestatus=? WHERE foltia_subtitle.m2pfilename = ?');
	$sth->execute($filename);
}

