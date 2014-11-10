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
	$response->setMaxAge(30);
	$response->setPublic();
	$response->headers->set('Content-Length', strlen($response->getContent()));
	$response->headers->set('Vary', 'X-OS');
});

$app->get('/', function(Application $app) {
	return $app['twig']->render('cached.twig', ['timestamp' => date('r')]);
});

$app->get('/health', function (Request $request, Response $response) {
	return "OK";
});
