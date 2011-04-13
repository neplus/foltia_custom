#!/usr/bin/perl
#usage ipodtranscode.pl 
#
# Anime recording system foltia
# http://www.dcc-jpl.com/soft/foltia/
#
# iPod MPEG4/H.264トラコン
# ffmpegを呼び出して変換
#
# DCC-JPL Japan/foltia project
#

use DBI;
use DBD::Pg;
use DBD::SQLite;
use Jcode;

$path = $0;
$path =~ s/ipodtranscode.pl$//i;
if ($path ne "./"){
	push( @INC, "$path");
}
require "foltialib.pl";


# 二重起動の確認!
$processes =  &processfind("ipodtranscode.pl");
#$processes = $processes +  &processfind("ffmpeg");

if ($processes > 1 ){
	&writelog("ipodtranscode processes exist. exit:");
	exit;
}else{
#&writelog("ipodtranscode.pl  Normal launch.");
}

#DB初期化
$dbh = DBI->connect($DSN,$DBUser,$DBPass) ||die $DBI::error;;

# タイトル取得
#トラコンフラグがたっていてステータス50以上150未満のファイルを古い順にひとつ探す
# 数数える
#$DBQuery =  "SELECT count(*) FROM foltia_subtitle, foltia_program, foltia_m2pfiles 
#WHERE filestatus >= $FILESTATUSRECEND AND filestatus < $FILESTATUSTRANSCODECOMPLETE  AND foltia_program.tid = foltia_subtitle.TID AND foltia_program.PSP = 1  AND foltia_m2pfiles.m2pfilename = foltia_subtitle.m2pfilename  ";
#$sth = $dbh->prepare($DBQuery);
#$sth->execute();
#@titlecount= $sth->fetchrow_array;
&writelog("ipodtranscode starting up.");

$counttranscodefiles = &counttranscodefiles();
if ($counttranscodefiles == 0){
	&writelog("ipodtranscode No MPEG2 files to transcode.");
	exit;
}
sleep 30;

while ($counttranscodefiles >= 1){
	$sth = $dbh->prepare($stmt{'ipodtranscode.1'});
	$sth->execute($FILESTATUSRECEND, $FILESTATUSTRANSCODECOMPLETE, );
	@dbparam = $sth->fetchrow_array;
#print "$dbparam[0],$dbparam[1],$dbparam[2],$dbparam[3],$dbparam[4],$dbparam[5]\n";
#&writelog("ipodtranscode DEBUG $DBQuery");
	&writelog("ipodtranscode DEBUG $dbparam[0],$dbparam[1],$dbparam[2],$dbparam[3],$dbparam[4],$dbparam[5]");
	$pid = $dbparam[0];
	$tid = $dbparam[1];
	$inputmpeg2 = $recfolderpath."/".$dbparam[2]; # path付き
	$mpeg2filename = $dbparam[2]; # pathなし
	$filestatus = $dbparam[3];
	$aspect = $dbparam[4];# 16,1 (超額縁),4,3
	$countno = $dbparam[5];
	$mp4filenamestring = &mp4filenamestringbuild($pid);

	if (-e $inputmpeg2){#MPEG2ファイルが存在していれば

		&writelog("ipodtranscode DEBUG mp4filenamestring $mp4filenamestring");
#展開ディレクトリ作成
		$pspdirname = &makemp4dir($tid);
		$mp4outdir = $pspdirname ;
# 実際のトラコン
# タイトル取得
		if ($pid ne ""){
			$sth = $dbh->prepare($stmt{'ipodtranscode.2'});
			$sth->execute($pid);
			@programtitle = $sth->fetchrow_array;
			$programtitle[0] =~ s/\"/\\"/gi;
			$programtitle[2] =~ s/\"/\\"/gi;

			if ($pid > 0){
				if ($programtitle[1] ne ""){
					$movietitle = " -title \"$programtitle[0] 第$programtitle[1]話 $programtitle[2]\" ";
					$movietitleeuc = " -t \"$programtitle[0] 第$programtitle[1]話 $programtitle[2]\" ";
				}else{
					$movietitle = " -title \"$programtitle[0] $programtitle[2]\" ";
					$movietitleeuc = " -t \"$programtitle[0] $programtitle[2]\" ";
				}
			}elsif($pid < 0){
				#EPG
				$movietitle = " -title \"$programtitle[2]\" ";
				$movietitleeuc = " -t \"$programtitle[2]\" ";
			}else{# 0
				#空白
				$movietitle = "";
				$movietitleeuc = "";
			}
#Jcode::convert(\$movietitle,'utf8');# Title入れるとiTunes7.0.2がクラッシュする
			$movietitle = "";
			$movietitleeuc = "";
		}

		if ($filestatus <= $FILESTATUSRECEND){
		}

		if ($filestatus <= $FILESTATUSWAITINGCAPTURE){
#なにもしない
		}

		if ($filestatus <= $FILESTATUSCAPTURE){
# Starlight breaker向けキャプチャ画像作成
			if (-e "$toolpath/perl/captureimagemaker.pl"){
				&writelog("ipodtranscode Call captureimagemaker $mpeg2filename");
				&changefilestatus($pid,$FILESTATUSCAPTURE);
				system ("$toolpath/perl/captureimagemaker.pl $mpeg2filename");
				&changefilestatus($pid,$FILESTATUSCAPEND);
			}
		}

		if ($filestatus <= $FILESTATUSCAPEND){
# サムネイル作る
			$filenamebody = $inputmpeg2 ;
			$filenamebody =~ s/.m2t$|.ts$|.m2p$|.mpg$|.aac$//gi;

			&makethumbnail();
			&changefilestatus($pid,$FILESTATUSTHMCREATE);
		}

		if ($filestatus <= $FILESTATUSWAITINGTRANSCODE){
		}

		$filenamebody = $inputmpeg2 ;
		$filenamebody =~ s/.m2t$|.ts$|.m2p$|.mpg$|.aac$//gi;

#デジタルかアナログか
		if ($inputmpeg2 =~ /m2t$|ts$|aac$/i){

			if ($filestatus <= $FILESTATUSTRANSCODETSSPLITTING){
			}
			if ($filestatus <= $FILESTATUSTRANSCODEFFMPEG){
				unlink("$filenamebody.264");
				# H.264出力
				$trcnmpegfile = $inputmpeg2 ;
				# アスペクト比
				if ($aspect == 1){#超額縁
					$cropopt = " -croptop 150 -cropbottom 150 -cropleft 200 -cropright 200 ";
				}elsif($aspect == 4){#SD 
					$cropopt = " -croptop 6 -cropbottom 6 -cropleft 8 -cropright 8 ";
				}else{#16:9
					$cropopt = " -croptop 6 -cropbottom 6 -cropleft 8 -cropright 8 ";
				}
				# クオリティごとに
				if (($trconqty eq "")||($trconqty == 1)){
					$ffmpegencopt = " -threads 0 -s 360x202 -deinterlace -r 24.00 -vcodec libx264 -g 300 -b 330000 -level 13 -loop 1 -sc_threshold 60 -partp4x4 1 -rc_eq 'blurCplx^(1-qComp)' -refs 3 -maxrate 700000 -async 50 -f h264 $filenamebody.264";
				}elsif($trconqty == 2){
#	$ffmpegencopt = " -s 480x272 -deinterlace -r 29.97 -vcodec libx264 -g 300 -b 400000 -level 13 -loop 1 -sc_threshold 60 -partp4x4 1 -rc_eq 'blurCplx^(1-qComp)' -refs 3 -maxrate 700000 -async 50 -f h264 $filenamebody.264";
# for ffmpeg 0.5 or later
					$ffmpegencopt = " -threads 0  -s 480x272 -deinterlace -r 29.97 -vcodec libx264 -vpre default   -g 300 -b 400000 -level 13 -sc_threshold 60 -rc_eq 'blurCplx^(1-qComp)' -refs 3 -maxrate 700000 -async 50 -f h264 $filenamebody.264";
				}elsif($trconqty == 3){#640x360
#	$ffmpegencopt = " -s 640x352 -deinterlace -r 29.97 -vcodec libx264 -g 100 -b 600000 -level 13 -loop 1 -sc_threshold 60 -partp4x4 1 -rc_eq 'blurCplx^(1-qComp)' -refs 3 -maxrate 700000 -async 50 -f h264 $filenamebody.264";
# for ffmpeg 0.5 or later
					$ffmpegencopt = " -threads 0  -s 640x360 -deinterlace -r 29.97 -vcodec libx264 -fpre default -g 100 -b 600000 -level 13 -sc_threshold 60 -rc_eq 'blurCplx^(1-qComp)' -refs 3 -maxrate 700000 -async 50 -f h264 $filenamebody.264";
				}elsif($trconqty == 4){#1280x720p
					$ffmpegencopt = "-f h264 -vcodec libx264 -fpre $toolpath/perl/tool/libx264-hq-ts.ffpreset -r 30000/1001 -aspect 16:9 -s 1280x720 -bufsize 20000k -b 1000000 -maxrate 2500000 $filenamebody.264";
				}

				&changefilestatus($pid,$FILESTATUSTRANSCODEFFMPEG);
#まずTsSplitする →ワンセグをソースにしてしまわないように
				if (! -e "$filenamebody.264"){
					&changefilestatus($pid,$FILESTATUSTRANSCODETSSPLITTING);
					$trcnmpegfile = $inputmpeg2 ;
					$trcnmpegfile = &validationsplitfile($inputmpeg2,$trcnmpegfile);


					#再ffmpeg
					&changefilestatus($pid,$FILESTATUSTRANSCODEFFMPEG);
					&writelog("ipodtranscode ffmpeg $filenamebody.264");
					&writelog("ffmpeg -y -i $trcnmpegfile $cropopt $ffmpegencopt");
					system ("ffmpeg -y -i $trcnmpegfile $cropopt $ffmpegencopt");
				}
#もしエラーになったらcropやめる
				if (! -e "$filenamebody.264"){
#再ffmpeg
					&changefilestatus($pid,$FILESTATUSTRANSCODEFFMPEG);
					&writelog("ipodtranscode ffmpeg retry no crop $filenamebody.264");
					&writelog("ffmpeg -y -i $trcnmpegfile $ffmpegencopt");
					system ("ffmpeg -y -i $trcnmpegfile $ffmpegencopt");
				}
			}
			if ($filestatus <= $FILESTATUSTRANSCODEWAVE){
				# WAVE出力
				unlink("${filenamebody}.wav");
				&changefilestatus($pid,$FILESTATUSTRANSCODEWAVE);
				&writelog("ipodtranscode mplayer $filenamebody.wav");
				system ("mplayer $trcnmpegfile -vc null -vo null -ao pcm:file=$filenamebody.wav:fast");

			}
			if ($filestatus <= $FILESTATUSTRANSCODEAAC){
				# AAC変換
				unlink("${filenamebody}.aac");
				&changefilestatus($pid,$FILESTATUSTRANSCODEAAC);
				if (-e "$toolpath/perl/tool/neroAacEnc"){
					if (-e "$filenamebody.wav"){
						&writelog("ipodtranscode neroAacEnc $filenamebody.wav");
						system ("$toolpath/perl/tool/neroAacEnc -br 128000  -if $filenamebody.wav  -of $filenamebody.aac");
					}else{
						&writelog("ipodtranscode ERR Not Found $filenamebody.wav");
					}
				}else{
#print "DEBUG $toolpath/perl/tool/neroAacEnc\n\n";
					&writelog("ipodtranscode faac $filenamebody.wav");
					system ("faac -b 128  -o $filenamebody.aac $filenamebody.wav ");
				}

			}
			if ($filestatus <= $FILESTATUSTRANSCODEMP4BOX){

#unlink("${filenamebody}.base.mp4");

#デジタルラジオなら
#if ($inputmpeg2 =~ /aac$/i){
#	if (-e "$toolpath/perl/tool/MP4Box"){
#		&writelog("ipodtranscode MP4Box $filenamebody");
#		system ("cd $recfolderpath ;$toolpath/perl/tool/MP4Box -add $filenamebody.aac  -new $filenamebody.base.mp4");
#	$exit_value = $? >> 8;
#	$signal_num = $? & 127;
#	$dumped_core = $? & 128;
#	&writelog("ipodtranscode DEBUG MP4Box -add $filenamebody.aac  -new $filenamebody.base.mp4:$exit_value:$signal_num:$dumped_core");
#	}else{
#		&writelog("ipodtranscode WARN; Pls. install $toolpath/perl/tool/MP4Box");
#	}
#}else{
#	# MP4ビルド
				if (-e "$toolpath/perl/tool/MP4Box"){
					&changefilestatus($pid,$FILESTATUSTRANSCODEMP4BOX);
					&writelog("ipodtranscode MP4Box $filenamebody");
					system ("cd $recfolderpath ;$toolpath/perl/tool/MP4Box -fps 29.97 -add $filenamebody.264 -new $filenamebody.base.mp4");
					$exit_value = $? >> 8;
					$signal_num = $? & 127;
					$dumped_core = $? & 128;
					&writelog("ipodtranscode DEBUG MP4Box -fps 29.97 -add $filenamebody.264 -new $filenamebody.base.mp4:$exit_value:$signal_num:$dumped_core");
					if (-e "$filenamebody.base.mp4"){
						system ("cd $recfolderpath ;$toolpath/perl/tool/MP4Box -add $filenamebody.aac $filenamebody.base.mp4");
						$exit_value = $? >> 8;
						$signal_num = $? & 127;
						$dumped_core = $? & 128; 
						&writelog("ipodtranscode DEBUG MP4Box -add $filenamebody.aac:$exit_value:$signal_num:$dumped_core");
					}else{
						$filelist = `ls -lhtr $recfolderpath/${filenamebody}*`;
						$debugenv = `env`;
						&writelog("ipodtranscode ERR File not exist. $filelist ;$filenamebody.base.mp4;$filelist;cd $recfolderpath ;$toolpath/perl/tool/MP4Box -fps 29.97 -add $filenamebody.264 -new $filenamebody.base.mp4");
					}
				}else{
					&writelog("ipodtranscode WARN; Pls. install $toolpath/perl/tool/MP4Box");
				}
#unlink("$filenamebody.aac");
#}#endif #デジタルラジオなら

#}

#if ($filestatus <= $FILESTATUSTRANSCODEATOM){
				if (-e "$toolpath/perl/tool/MP4Box"){
# iPodヘッダ付加
#		&changefilestatus($pid,$FILESTATUSTRANSCODEATOM);
					&writelog("ipodtranscode ATOM $filenamebody");
#system ("/usr/local/bin/ffmpeg -y -i $filenamebody.base.mp4 -vcodec copy -acodec copy -f ipod ${mp4outdir}MAQ${mp4filenamestring}.MP4");
#		system ("cd $recfolderpath ; MP4Box -ipod $filenamebody.base.mp4");
					system ("cd $recfolderpath ; $toolpath/perl/tool/MP4Box -ipod $filenamebody.base.mp4");
					$exit_value = $? >> 8;
					$signal_num = $? & 127;
					$dumped_core = $? & 128;
					&writelog("ipodtranscode DEBUG MP4Box -ipod $filenamebody.base.mp4:$exit_value:$signal_num:$dumped_core");
					if (-e "$filenamebody.base.mp4"){
#unlink("${mp4outdir}MAQ${mp4filenamestring}.MP4");
						system("mv $filenamebody.base.mp4 ${mp4outdir}MAQ${mp4filenamestring}.MP4");
						&writelog("ipodtranscode mv $filenamebody.base.mp4 ${mp4outdir}MAQ${mp4filenamestring}.MP4");
					}else{
						&writelog("ipodtranscode ERR $filenamebody.base.mp4 Not found.");
					}
# ipodtranscode mv /home/foltia/php/tv/1329-21-20080829-0017.base.mp4 /home/foltia/php/tv/1329.localized/mp4/MAQ-/home/foltia/php/tv/1329-21-20080829-0017.MP4
				}else{
					&writelog("ipodtranscode WARN; Pls. install $toolpath/perl/tool/MP4Box");
				}
			}
			if ($filestatus <= $FILESTATUSTRANSCODECOMPLETE){
				if (-e "${mp4outdir}MAQ${mp4filenamestring}.MP4"){
# 中間ファイル消す
					unlink("$filenamebody.264");
					unlink("$filenamebody.wav");
					unlink("$filenamebody.aac");
					unlink("$filenamebody.base.mp4");
					&changefilestatus($pid,$FILESTATUSTRANSCODECOMPLETE);
					&updatemp4file();
				}else{
					&writelog("ipodtranscode ERR ; Fail.Giving up!  MAQ${mp4filenamestring}.MP4");
					&changefilestatus($pid,999);
				}
			}

		}

		$counttranscodefiles = &counttranscodefiles();
############################
#一回で終らせるように
#exit;


	}else{#ファイルがなければ
		&writelog("ipodtranscode NO $inputmpeg2 file.Skip.");
	}#end if

}# end while
#残りファイルがゼロなら
&writelog("ipodtranscode ALL COMPLETE");
exit;


#-----------------------------------------------------------------------
#mp4ファイル名決定
sub mp4filenamestringbuild(){
#1329-19-20080814-2337.m2t
	my @mpegfilename = split(/\./,$dbparam[2]) ;
	my $pspfilname = "-".$mpegfilename[0] ;
	return("$pspfilname");
}#end sub mp4filenamestringbuild



#サムネール
sub makethumbnail(){
	my $outputfilename = $inputmpeg2 ;#フルパス
	my $thmfilename = "MAQ${mp4filenamestring}.THM";
	&writelog("ipodtranscode DEBUG thmfilename $thmfilename");

	if($outputfilename =~ /.m2t$/){
#ハイビジョンTS
#TODO mplayerがうまくサムネイルを作成しないので修正する
	}
	$outputfilename =~ s/.m2t$|.ts$|.m2p$|.mpg$|.aac$//gi;
	
	system("cp $toolpath/php/$pid.localized/img/$filenamebody/00000003.jpg $pspdirname/$thmfilename")
	&writelog("ipodtranscode DEBUG cp $toolpath/php/$pid.localized/img/$filenamebody/00000003.jpg $pspdirname/$thmfilename")
}#endsub makethumbnail


sub updatemp4file(){
	my $mp4filename = "MAQ${mp4filenamestring}.MP4";

	if (-e "${mp4outdir}MAQ${mp4filenamestring}.MP4"){
# MP4ファイル名をPIDレコードに書き込み
		$sth = $dbh->prepare($stmt{'ipodtranscode.updatemp4file.1'});
		$sth->execute($mp4filename, $pid);
		&writelog("ipodtranscode UPDATEsubtitleDB $stmt{'ipodtranscode.updatemp4file.1'}");

# MP4ファイル名をfoltia_mp4files挿入
		$sth = $dbh->prepare($stmt{'ipodtranscode.updatemp4file.2'});
		$sth->execute($tid, $mp4filename);
		&writelog("ipodtranscode UPDATEmp4DB $stmt{'ipodtranscode.updatemp4file.2'}");

		&changefilestatus($pid,$FILESTATUSALLCOMPLETE);
	}else{
		&writelog("ipodtranscode ERR MP4 NOT EXIST $pid/$mp4filename");
	}
}#updatemp4file


sub counttranscodefiles(){
	$sth = $dbh->prepare($stmt{'ipodtranscode.counttranscodefiles.1'});
	$sth->execute($FILESTATUSRECEND, $FILESTATUSTRANSCODECOMPLETE);
	my @titlecount= $sth->fetchrow_array;

	return ($titlecount[0]);
}#end sub counttranscodefiles


sub validationsplitfile{
	my $inputmpeg2 = $_[0];
	my $trcnmpegfile = $_[1];

#Split結果確認
	my $filesizeoriginal = -s $inputmpeg2 ;
	my $filesizesplit = -s $trcnmpegfile;
	my $validation = 0;
	if ($filesizesplit  > 0){
		$validation = $filesizeoriginal / $filesizesplit   ;
		if ($validation > 2 ){
#print "Fail split may be fail.\n";
			&writelog("ipodtranscode ERR File split may be fail: $filesizeoriginal:$filesizesplit");
			$trcnmpegfile = $inputmpeg2 ;
			return ($trcnmpegfile);
		}else{
#print "Fail split may be good.\n";
			return ($trcnmpegfile);
		}
	}else{
#Fail
		&writelog("ipodtranscode ERR File split may be fail: $filesizeoriginal:$filesizesplit");
		$trcnmpegfile = $inputmpeg2 ;
		return ($trcnmpegfile);
	}
}#end sub validationsplitfile

