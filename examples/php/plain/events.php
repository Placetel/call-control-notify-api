<?php

/*
 *  Run with:
 *  php -S localhost:8080
 */

if (isset($_POST['event'])) {
  if ($_POST['event'] === 'AcceptedCall') {
    // do s.th.
  }
  elseif ($_POST['event'] === 'HungUp') {
    // do s.th.
  }
  elseif ($_POST['event'] === 'IncomingCall') {
    exit('
      <Response>
        <Forward music_on_hold="true" voicemail="false" voicemail_announcement="4711" voicemail_as_attachment="true" forward_announcement="7684">
          <Target ringtime="60">
            <Number>7777acbdef@fbpx.de</Number>
          </Target>
        </Forward>
      </Response>
    ');
  }
}
