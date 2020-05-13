<?php
$uri = __DIR__ . $_SERVER['REQUEST_URI'];
if ($_SERVER['REQUEST_URI'] == '/') {
    $uri .= 'index.html';
}


$mime = custom_mime_content_type($uri);
$size = filesize($uri);

$delay = 0;

header(sprintf('Content-Type: %s', $mime));
header('Expires: 0');
header('Cache-Control: must-revalidate');
header('Pragma: public');
header(sprintf('Content-Length: %d', $size));
header(sprintf('X-TTFB-Delay: %d secs', $delay ) );

if ( $delay>0 ) {
    sleep($delay);
}

readfile($uri);


function custom_mime_content_type($filename)
{

    $mime_types = array(
        'htm' => 'text/html',
        'html' => 'text/html',
        'css' => 'text/css',
        'jpg' => 'image/jpeg',
        'ico' => 'image/vnd.microsoft.icon',

    );

    $array = explode('.', $filename);
    $ext = strtolower(array_pop($array));
    if (array_key_exists($ext, $mime_types)) {
        return $mime_types[$ext];
    } else {
        return 'application/octet-stream';
    }
}