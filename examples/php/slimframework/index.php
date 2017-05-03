<?php
/*
	Run with:
	php composer.phar start
	# or
	php -S 0.0.0.0:8080 -t public public/index.php
*/
use \Psr\Http\Message\ServerRequestInterface as Request;
use \Psr\Http\Message\ResponseInterface as Response;

require __DIR__ . '/../vendor/autoload.php';

$app = new \Slim\App;


$app->post('/incoming_event', function (Request $request, Response $response) {
	$data = $request->getParsedBody();
	if ($data['event'] === 'IncomingCall') {
		$xml = '
		<Response>
		    <Forward music_on_hold="true" voicemail="false" voicemail_announcement="4711" voicemail_as_attachment="true" forward_announcement="7684">
		        <Target ringtime="60">
		            <Number>7777acbdef@fbpx.de</Number>
		        </Target>
		    </Forward>
		</Response>');
		$response->getBody()->write($xml);
	}
	return $response;
});

$app->run();
