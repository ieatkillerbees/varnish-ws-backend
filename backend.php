<?php
require __DIR__ . '/vendor/autoload.php';

use Silex\Application;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\HttpFoundation\Response;

$app = new Application();
$app['debug'] = true;
$app['healthy'] = true;
//require __DIR__ . '/config/conf_' . $_SERVER['SERVER_PORT'] . '.php';
$app->register(new Silex\Provider\TwigServiceProvider(), ['twig.path' => __DIR__ . '/views']);

$app->before(function (Request $request, Application $app) {
	if (!$app['healthy']) {
		$app->abort(500);
	}
});

$app->after(function (Request $request, Response $response) {
	$response->setMaxAge(300);
	$response->setSharedMaxAge(300);
	$response->setVary('X-OS');
	$response->setPublic();
	$response->headers->set('Content-Length', strlen($response->getContent()));
});

$app->get('/', function(Application $app) {
	return "<html><head><title>Cached Content</title></head><body>The current timestamp is: ".date('r')."</body></html>";
	return new \Symfony\Component\HttpFoundation\JsonResponse([
		'timestamp' => date('r')
	]);
});

$app->get('/health', function (Application $app) {
	return "OK";
});
