<?php
	if(!isset($_SERVER['HTTP_USER_AGENT'])) exit;
	$db=@new \mysqli('localhost','l4d2','123456',null,3306);
	if($db->connect_errno) exit;
	$db->set_charset('utf8');
	$db->select_db('l4d2');
	$res=$db->query('SELECT * FROM `banned_users`;');
	if($res){
		print('<table border="1"><tr><th>ID</th><th>SteamID</th><th>Reason</th><th>Time</th></tr>');
		foreach($res->fetch_all() as $v){
			print('<tr>');
			foreach($v as $vv) print('<td>'.$vv.'</td>');
			print('</tr>');
		}
		print('</table>');
		$res->free();
	}
	$db->close();
	exit;
?>