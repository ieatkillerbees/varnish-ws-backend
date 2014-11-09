<?php

use Silex\Application;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\HttpFoundation\Response;

$app = new Application();
var_dump($app); die;
require __DIR__ . '/config/conf_' . $_SERVER['SERVER_PORT'] . '.php';

$app->after(
	/**
	 * @param Request $request
	 * @param Response $response
	 */
	function (Request $request, Response $response) {
		$response->headers->set('X-Backend-Port', $_SERVER['SERVER_PORT']);
	}
);

$app->get('/', function () {
	return 'The current server time is: ' . date('r');
});