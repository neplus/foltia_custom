<?php
/*
 Anime recording system foltia
 http://www.dcc-jpl.com/soft/foltia/

foltia_config2.php

目的
初期設定ファイルの2つめです。


 DCC-JPL Japan/foltia project

*/

        $toolpath = "/tv" ; //「php」ディレクトリがあるパス
		$recfolderpath = '/tv/php/tv';	//録画ファイルの保存先のパス。
		$httpmediamappath = '/foltia/tv'; //ブラウザから見える録画ファイルのある位置。
		$recunits = 0;					//搭載アナログキャプチャカードチャンネル数

		$protectmode = 0; //未使用:(ブラウザからの予約削除を禁止するなどの保護モードで動作します)
		$demomode = 0; //未使用:(ユーザインターフェイスだけ動作するデモモードで動作します)
		$useenvironmentpolicy = 0 ;//環境ポリシーを使うかどうか
		$environmentpolicytoken = "";//環境ポリシーのパスワードに連結されるセキュリティコード
		$perltoolpath = $toolpath ;//perl版の初期設定の位置。デフォルトではphpと同じ位置
		$usedigital = 1;//Friioなどでデジタル録画をするか 1:する 0:しない

// データベース接続設定
// define("DSN", "pgsql:host=localhost dbname=foltia user=foltia password= ");
define("DSN", "sqlite:/tv/foltia.sqlite");

//        $mylocalip = "192.168.0.177" ; //動いている機械のIPアドレス

?>
