#!/usr/bin/perl
#
# encode_clear.pl
# $B%(%s%3!<%I@_Dj$r%/%j%"$9$k%U%!%$%k(B
#
use DBI;
use DBD::Pg;
use DBD::SQLite;
use Jcode;

use lib "/tv/perl";
require "foltialib.pl";

$dbh=DBI->connect($DSN,$DBUser,$DBPass)||die $DBI::error;
$sth=$dbh->prepare('update foltia_subtitle set filestatus=0 WHERE foltia_subtitle.m2pfilename = ?');
$sth->execute($ARGV[0]);


