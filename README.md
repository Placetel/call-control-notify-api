# Placetel Call Control-/Notify-API

The following document describes the Call Control- and Notify-API by [Placetel](https://www.placetel.de).

### Table of contents

1. [Setup](#setup)
1. [Our POST request](#our-post-request)
    1. [Incoming call](#incoming-call)
    1. [Outgoing call](#outgoing-call)
    1. [Call accepted](#call-accepted)
    1. [Call hangup](#call-hangup)
1. [Your XML response](#your-xml-response)
    1. [Forward](#forward)
    1. [Reject](#reject)
    1. [Hangup](#hangup)
    1. [Prompt](#prompt)
    1. [Group](#group)
    1. [RoutingPlan](#routing-plan)
    1. [Queue](#queue)
1. [Code examples](#code-examples)
1. [Security](#security)
1. [FAQ](#faq)
1. [Contributing](#contributing)

## Setup

This API is part of our [PROFI](https://www.placetel.de/telefonanlage/preise) product line and comes in two operating modes:

1. a simple notification API, which notifies your API endpoint about new incoming and outgoing calls, when calls are accepted (only for incoming calls) and when a call ends
2. an advanced call control mechanism, set up in the routing of each number, which asks your API endpoint how to handle an incoming call

To enable both APIs, go to *Settings* → *External APIs* in the Placetel Webportal and provide the URL of your API endpoint.

### Setup Notify

Call notifications are activated per phone number. Use the checkboxes on *Settings* → *Exsternal APIs* or the the Checkbox in the *Miscellaneous*-tab in the routing settings of each number.

Outgoing calls are only notified if the caller ID of the used SIP user is set and the number is enabled for notifications.

### Setup Call Control

Change the routing of your number to *External API*. The amount of retries to contact your API can be raised up to 10, we wait for 100ms after each retry.  

Select a backup routing plan, which will be used in case of an error and an announcement, which will be played before processing your response.

## Our POST request

We will send a `POST` request with an `application/x-www-form-urlencoded` payload to your API endpoint for every event.
Each event will have an call id to identify the call it belongs to. This call id will be a hex presentation of a `SHA256` hash.

In order to verify the authenticity of our request on your side, we're using an HMAC with SHA256.
You can configure the shared secret [in your external api settings](https://web.placetel.de/settings/external_api). After that, every request will have the HTTP Header `X-PLACETEL-SIGNATURE`.  
You can calculate the signature and compare it to our signature in `X-PLACETEL-SIGNATURE`:
```ruby
require 'openssl'
secret = 'THE_SECRET'
payload = 'POSTED_PAYLOAD'

digest = OpenSSL::Digest.new('sha256')
signature = OpenSSL::HMAC.hexdigest(digest, secret, payload)
```

For example a secret `12345` with a given payload `call_id=4a4cbb39578170aed9a2761a7bec8c7e704a541f52291ef603d6f5f152980c3c&event=CallAccepted&from=0123456789&to=0987654321` will result in:
```
2.5.1 :005 > digest = OpenSSL::Digest.new('sha256')
 => #<OpenSSL::Digest: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855>
2.5.1 :006 > signature = OpenSSL::HMAC.hexdigest(digest, secret, payload)
 => "c4f823c5b8806432fe2b83b1fc2ee714422e0cdfb4b5129152a7d0bbcd7792d0"
```

In order to restrict access to your API endpoint, you may use a simple basic-auth in the URL defined [in your external api settings](https://web.placetel.de/settings/external_api): `https://admin:password@your.end.point/callback`.

Depending on the type of request our payload contains the following parameters:

### Incoming call

Parameter   | Description
----------- | -----------------------------------------------------------
`event`     | `"IncomingCall"`
`from`      | The calling number (e.g. `"022129191999"` or `"anonymous"`)
`to`        | The called number (e.g. `"022129191999"`)
`call_id`   | The ID of the call, `sha256` in hex presentation, e.g. `"f4591ba315d81671d7a06c2a3b4f963dafd119de39cb26edd8a6476676b2f447"`
`direction` | `"in"`

### Outgoing call

Parameter   | Description
----------- | -----------------------------------------------------------
`event`     | `"OutgoingCall"`
`from`      | The caller id of the calling party (anonymous calls are not notified)
`to`        | The called number (e.g. `"022129191999"`, or `"23"`)
`peer`      | The calling SIP user (e.g. `"7777abcdefg@fpbx.de"`)
`call_id`   | The ID of the call, `sha256` in hex presentation, e.g. `"f4591ba315d81671d7a06c2a3b4f963dafd119de39cb26edd8a6476676b2f447"`
`direction` | `"out"`

### Call accepted

Only for incoming calls.

Parameter   | Description
----------- | -----------------------------------------------------------
`event`     | `"CallAccepted"`
`from`      | The calling number (e.g. `"022129191999"` or `"anonymous"`)
`to`        | The called number (e.g. `"022129191999"`)
`call_id`   | The ID of the call, `sha256` in hex presentation, e.g. `"f4591ba315d81671d7a06c2a3b4f963dafd119de39cb26edd8a6476676b2f447"`
`peer`      | The SIP peer which answered the call, e.g. `"7777abcdefg@fpbx.de"`
`direction` | `"in"`

### Call hangup

Parameter   | Description
----------- | ----------------------------------------------------------------------------
`event`     | `"HungUp"`
`from`      | The calling number (e.g. `"022129191999"` or `"anonymous"`)
`to`        | The called number (e.g. `"022129191999"`)
`call_id`   | The ID of the call, `sha256` in hex presentation, e.g. `"f4591ba315d81671d7a06c2a3b4f963dafd119de39cb26edd8a6476676b2f447"`
`type`      | The cause of the hangup (see [table](#hangup-types) below)
`duration`  | Duration of *accepted* call in seconds, `0` for not accepted calls
`direction` | `"in"` or `"out"`

`from` and `to` for outgoing internal calls are the SIP IDs of caller and callee.

#### Hangup types

Type          | Description
------------- | ---------------------------------------------------
`voicemail`   | The call was sent to voicemail
`missed`      | Nobody picked up the call
`blocked`     | The call was blocked
`accepted`    | The call was accepted and ended by hangup
`busy`        | The called number was busy
`canceled`    | The call was canceled by the caller
`unavailable` | Destination is offline / unavailable
`congestion`  | There was a problem

`busy`, `canceled`, `unavailable` and `congestion` are limited to outbound calls.

## Your XML response

Your XML response is used to determine what to do with the **incoming call**.
We only process your response when the routing for your number is set to *External API*. 
Make sure your response's `Content-Type` header is set to `application/xml`.

Currently, we support the following responses for incoming calls:

Action                          | Description
------------------------------- | --------------------------------------------------------------------------
[Forward](#forward)             | Forward call to one or multiple destinations (SIP users, external numbers)
[Reject](#reject)               | Reject call or pretend to be busy
[Hangup](#hangup)               | A normal Hang up
[Prompt](#prompt)               | Play a prompt and hang up
[Group](#group)                 | Redirect call to a group
[RoutingPlan](#routing-plan)    | Redirect call to a routing plan
[Queue](#queue)                 | Send call to a [Contact Center] Queue<sup>*</sup>

<sup>*</sup> Only available with [Contact Center] option booked.

### Forward

Forward to one or multiple targets. Attributes for `Forward` are

Attribute                   | Required  | Default   | Description
--------------------------- | --------- | --------- | --------------------------------------------------------------------------------
`music_on_hold`             | no        | `false`   | Play music on hold instead of standard ringtone?
`voicemail`                 | no        | `true`    | Send call to voicemail if no routing target answered?
`voicemail_announcement`    | no        |           | ID of mailbox announcement / prompt, e.g. `1234`
`voicemail_as_attachment`   | no        | `false`   | Send voicemail as MP3 attachment?
`forward_announcement`      | no        |           | Play selected announcement and transfer to targets, see `voicemail_announcement`

Attributes for each `Target`.

Attribute   | Required  | Default   | Description
----------- | --------- | --------- | -------------------
`ringtime`  | no        | `60`      | Ringtime in seconds

#### Example 1: Forward call to one external number
```xml
<?xml version="1.0" encoding="UTF-8"?>
<Response>
    <Forward>
        <Target>
            <Number>022129191999</Number>
        </Target>
    </Forward>
</Response>
```

#### Example 2: Forward call to one VoIP destination
```xml
<?xml version="1.0" encoding="UTF-8"?>
<Response>
    <Forward>
        <Target>
            <Number>7777abcdefg@fpbx.de</Number>
        </Target>
    </Forward>
</Response>
```

Find the SIP username and server on the settings page of your SIP destination.

#### Example 3a: Forward call to multiple destinations

*Ringing the same time.*

```xml
<?xml version="1.0" encoding="UTF-8"?>
<Response>
    <Forward>
        <Target>
            <Number>7777abcdefg@fpbx.de</Number>
            <Number>022129191999</Number>
        </Target>
    </Forward>
</Response>
```

#### Example 3b: Forward call to multiple destinations

*Ringing 30 sec on the first two destinations and 45 sec on the second three destinations.*

```xml
<?xml version="1.0" encoding="UTF-8"?>
<Response>
    <Forward>
        <Target ringtime="30">
            <Number>7777abcdefg@fpbx.de</Number>
            <Number>022129191999</Number>
        </Target>
        <Target ringtime="45">
            <Number>7777xyzabcd@fpbx.de</Number>
            <Number>7777aabbccd@fpbx.de</Number>
            <Number>022199998560</Number>
        </Target>
    </Forward>
</Response>
```

#### Example 4: Play music on hold and announcement before forwarding to VoIP destination
```xml
<?xml version="1.0" encoding="UTF-8"?>
<Response>
    <Forward music_on_hold="true" forward_announcement="7684">
        <Target>
            <Number>7777abcdefg@fpbx.de</Number>
        </Target>
    </Forward>
</Response>
```

#### Example 5: Forward to voicemail and set a custom announcement
```xml
<?xml version="1.0" encoding="UTF-8"?>
<Response>
    <Forward voicemail="true" voicemail_announcement="4"/>
</Response>
```

### Reject

Reject an unwanted call or pretend to be busy.

Attribute   | Required  | Description
----------- | --------- | -------------------------------------------------
`reason`    | no        | The reject reason for the call, for now: `"busy"`

#### Example 1: Reject call
```xml
<?xml version="1.0" encoding="UTF-8"?>
<Response>
    <Reject />
</Response>
```

#### Example 2: Reject call and pretend to be busy
```xml
<?xml version="1.0" encoding="UTF-8"?>
<Response>
    <Reject reason="busy" />
</Response>
```

### Hangup

A simple hangup.

#### Example: Hang up call
```xml
<?xml version="1.0" encoding="UTF-8"?>
<Response>
    <Hangup />
</Response>
```

### Prompt

Play a prompt and hang up.

Attribute   | Required | Description
----------- | ---------| ------------------------------------------
`id`        | yes      | The ID of the prompt, required, e.g. `123`

#### Example: play prompt by ID and hang up
```xml
<?xml version="1.0" encoding="UTF-8"?>
<Response>
    <Prompt id="123" />
</Response>
```

### Group

Send call to a group.

Attribute                   | Required  | Default       | Description
--------------------------- | --------- | ------------- |---------------------------------------------------------------------------
`id`                        | yes       |               | ID of the group, required, e.g. `123`
`ringtime`                  | no        | `40`          | Ring time before handling backup, `10` to `60` seconds
`backup_behaviour`          | no        | `"mailbox"`   | `"mailbox"` or `"routing_object"`
`backup_routing_object`     | no        |               | ID of the routing object for backup handling
`voicemail_announcement`    | no        |               | ID of the voicemail announcement / prompt, e.g. `123`
`voicemail_as_attachment`   | no        | `false`       | Send voicemail as MP3 attachment?
`forward_announcement`      | no        |               | ID of the announcement / prompt before forwarding to the group, e.g. `123`
`music_on_hold`             | no        | `false`       | Play music on hold instead of standard ringtone?

#### Example: Send to group
```xml
<?xml version="1.0" encoding="UTF-8"?>
<Response>
    <Group id="123" />
</Response>
```

### Routing Plan

Send call to a routing plan which will be evaluated as usual. If no routing
object is active, the call will be ended. If you want a fallback for this case
provide a forward fallback.

Attribute | Required  | Description
--------- | --------- | ----------------------------------
`id`      | yes       | ID of the routing plan, e.g. `123`

Fallback is explained in [Forward](#forward).

#### Example 1: Send to routing plan

```xml
<Response>
  <RoutingPlan id="123" />
</Response>
```

#### Example 2: Send to routing plan with fallback

```xml
<Response>
  <RoutingPlan id="123">
    <Forward>
        <Target>
            <Number>7777abcdefg@fpbx.de</Number>
            <Number>022129191999</Number>
        </Target>
    </Forward>
  </RoutingPlan>
</Response>
```

### Queue

Send call to a [Contact Center] Queue.

Attribute   | Required  | Description
----------- | --------- | -------------------------------
`id`        | yes       | The ID of the queue, e.g. `123`

#### Example: Send to queue
```xml
<?xml version="1.0" encoding="UTF-8"?>
<Response>
    <Queue id="123" />
</Response>
```

## Code examples

* [Ruby](examples/ruby)
* [Node.js](examples/node)
* [PHP](examples/php)
* [Python](examples/python)
* [Java](examples/java)

Want to add your example? Open a [pull request]!

## Security

### Authentication

For HTTP Basic Authentication include your username and passwort within your API URL. For example: `https://username:password@example.com`.

## FAQ

#### Where to find the ID of my announcement prompt / queue / group / SIP destination?

You will find the ID in the edit form of each record in the Placetel Webportal. In addition, you can use the new [Placetel API](https://api.placetel.de/v2/docs/).

#### How much does it cost?

The API itself is provided free of charge; the usual connection fees may apply.

## Contributing

For improvements, feature requests or bug reports, please use [GitHub Issues](../../issues) or send us a [pull request].

![Placetel](https://www.placetel.de/content/placetel_logo_260x54.png)

[pull request]: ../../pulls
[Contact Center]: https://www.placetel.de/telefonanlage/funktionen/contact-center
