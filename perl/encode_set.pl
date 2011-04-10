#!/usr/bin/perl
#
# encode_set.pl
# encode$B%Q%i%a!<%?$r>e=q$-$9$k$?$a$N%9%/%j%W%H(B
#
#
use DBI;
use DBD::Pg;
use DBD::SQLite;
use Jcode;

use lib "/tv/perl";
require "foltialib.pl";

sub encode_set{
	($status, $filename) = @_;
	$dbh=DBI->connect($DSN,$DBUser,$DBPass)||die $DBI::error;
	$sth=$dbh->prepare('update foltia_subtitle set filestatus=? WHERE foltia_subtitle.m2pfilename = ?');
	$sth->execute($status, $filename);
}

