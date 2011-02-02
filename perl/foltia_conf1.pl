# Anime recording system foltia
# http://www.dcc-jpl.com/soft/foltia/
#
# 初期設定ファイル1
#
# DCC-JPL Japan/foltia project
#
#


#config section
$toolpath = '/tv'; #「perl」ディレクトリがあるPATH
$recunits = 0;					#アナログキャプチャカード搭載エンコーダの数
$recfolderpath = '/tv/php/tv';		#録画ファイルを置くPATH
$uhfbandtype = 1; # CATVなら1 UHF帯なら0 : 0=ntsc-bcast-jp 1=ntsc-cable-jp
$rapidfiledelete =  0;#1なら削除ファイルは「mita」ディレクトリに移動。0なら即時削除
$tunerinputnum = 0; #IO-DATA DV-MVP/RX,RX2,RX2W
$svideoinputnum = 1;#IO-DATA DV-MVP/RX,RX2,RX2W
$comvideoinputnum= 2;#IO-DATA DV-MVP/RX,RX2,RX2W
$haveirdaunit = 1;#Tira-2<http://www.home-electro.com/tira2.php>をつないでいるときに1,なければ0
$mp4filenamestyle = 1 ;#0:PSP ファームウェアver.2.80より前と互換性を持つファイル名 1;よりわかりやすいファイル名
$trconqty = 3;
#0:PSP/iPod XviD MPEG4(旧式):faacとMPEG4IPを使って変換(古い設定)
#1:iPod Xvid MPEG4 標準画質 15fps 300kbps / デジタル  360x202 24.00fps 300kbps
#2:iPod H.264 中画質 24fps 300kbps / デジタル 480x272  29.97fps 400kbps
#3:iPod H.264 高画質 30fps 300kbps / デジタル  640x352 29.97fps 600kbps
$phptoolpath = $toolpath ;#php版の初期設定の位置。デフォルトではperlと同じ位置

#以下はデフォルトでインストールしてればいじらなくてもいい

## for postgresql
#$main::DSN="dbi:Pg:dbname=foltia;host=localhost;port=5432";
#require 'db/Pg.pl';

## for sqlite
$main::DSN="dbi:SQLite:dbname=/tv/foltia.sqlite";
require 'db/SQLite.pl';

$main::DBUser="foltia";
$main::DBPass="";

#デバッグログを「~/debug.txt」に残すかどうか
$debugmode = 1;#write debug log





1;

