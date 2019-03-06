<?php
/**
 * Created by PhpStorm.
 * User: muntashir
 * Date: 27/12/18
 * Time: 16:28
 */

require_once __DIR__ . '/CurlHTML.php';
if($argc > 1) $repo = $argv[1];
else $repo = 'acidanthera/Lilu';
$latest_binary_url = "https://api.github.com/repos/$repo/releases/latest";
$binary_info = (new CurlHTML($latest_binary_url))->get_json();
var_dump($latest_binary_url);
$config = [];
$config['version'] = $binary_info['tag_name'];
$config['time'] = str_replace('Z', '', str_replace('T', ' ', $binary_info['created_at']));
$config['changes'] = $binary_info['body'];
foreach ($binary_info['assets'] as $asset){
    if(stripos($asset['name'], 'debug') !== false){
        $config['bin']['dev']['url'] = $asset['browser_download_url'];
    }
    if(stripos($asset['name'], 'release') !== false){
        $config['bin']['rel']['url'] = $asset['browser_download_url'];
    }
}
echo json_encode($config, JSON_PRETTY_PRINT);
