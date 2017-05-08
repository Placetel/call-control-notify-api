# Placetel Call Control-/Notify-API

The following document describes the Call Control- and Notify-API by [Placetel](https://www.placetel.de).

⚠️ This is still in beta and might change in the near future.

### Table of contents

1. [Setup](#setup)
1. [Our POST request](#our-post-request)
    1. [Incoming call](#incoming-call)
    1. [Call accepted](#call-accepted)
    1. [Call hangup](#call-hangup)
1. [Your XML response](#your-xml-response)
    1. [Forward](#forward)
    1. [Reject](#reject)
    1. [Hangup](#hangup)
1. [Code examples](#code-examples)
1. [FAQ](#faq)
1. [Contributing](#contributing)

## Setup

This API is part of our [PROFI](https://www.placetel.de/telefonanlage/preise) product line and comes in two operating modes:

1. a simple notification API, which is enabled per number and notifies your API endpoint about an incoming call, when the call is accepted and when the call ended
2. an advanced call control mechanism, set up in the routing of each number, which asks your API endpoint how to handle an incoming call

To enable both APIs, go to *Settings* → *External APIs* in your PBX and provide the URL of your API endpoint.

### Setup Notify

To enable call notification for a number use the checkboxes at *Settings* → *Exsternal APIs* or the the Checkbox in the *Miscellaneous*-tab in the routing settings of each number.  

### Setup Call Control

Change the routing of your number to *External API*. The amount of retries to contact your API can be raised up to 10, we wait for 100ms after each retry.  

Select a backup routing plan, which will be used in case of an error and an announcement, which will be played before processing your response.

## Our POST request

We will send a `POST` request with an `application/x-www-form-urlencoded` payload to your API endpoint for every event.
Each event will have an call id to identify the call it belongs to. This call id will be a hex presentation of  a `SHA256` hash

Depending on the type of request it contains the following parameters:

### Incoming call

Parameter   | Description
----------- | -----------------------------------------------------------
`event`     | `"IncomingCall"`
`from`      | The calling number (e.g. `"022129191999"` or `"anonymous"`)
`to`        | The called number (e.g. `"022129191999"`)
`call_id`   | The ID of the call, `sha256` in hex presentation, e.g. `"f4591ba315d81671d7a06c2a3b4f963dafd119de39cb26edd8a6476676b2f447"`

### Call accepted

Parameter   | Description
----------- | -----------------------------------------------------------
`event`     | `"CallAccepted"`
`from`      | The calling number (e.g. `"022129191999"` or `"anonymous"`)
`to`        | The called number (e.g. `"022129191999"`)
`call_id`   | The ID of the call, `sha256` in hex presentation, e.g. `"f4591ba315d81671d7a06c2a3b4f963dafd119de39cb26edd8a6476676b2f447"`
`peer`      | The SIP peer which answered the call, e.g. `"7777abcdefg@fpbx.de"`

### Call hangup

Parameter   | Description
----------- | ----------------------------------------------------------------------------
`event`     | `"HungUp"`
`from`      | The calling number (e.g. `"022129191999"` or `"anonymous"`)
`to`        | The called number (e.g. `"022129191999"`)
`call_id`   | The ID of the call, `sha256` in hex presentation, e.g. `"f4591ba315d81671d7a06c2a3b4f963dafd119de39cb26edd8a6476676b2f447"`
`type`      | The cause of the hangup (see [table](#hangup-types) below)

#### Hangup types

Type        | Description
----------- | ---------------------------------------------------
`voicemail` | The call was sent to voicemail
`missed`    | Nobody picked up the call
`blocked`   | The call was blocked
`accepted`  | The call was accepted and ended by hangup

## Your XML response

Your XML response is used to determine what to do with the incoming call. 
We only process your response when the routing for your number is set to *External API*. 
Make sure your response's `Content-Type` header is set to `application/xml`.

Currently, we support the following responses for incoming calls:

Action              | Description
------------------- | --------------------------------------------------------------------------
[Forward](#forward) | Forward call to one or multiple destinations (SIP users, external numbers)
[Reject](#reject)   | Reject call or pretend to be busy
[Hangup](#hangup)   | A normal Hang up
[Queue](#queue)     | Coming soon

### Forward

Forward to one or multiple targets. Attributes for `Forward` are

Attribute | Description
--------------------------- | ----------------------------------------------------------------------
`music_on_hold`             | Play music on hold instead of standard ringtone? Default is `false`
`voicemail`                 | Send call to voicemail if no routing target answered? Default is `true`
`voicemail_announcement`    | Mailbox announcement, e.g. `1234`
`voicemail_as_attachment`   | Send voicemail as MP3 attachment? Default is `false`
`forward_announcement`      | Play selected announcement and transfer to targets, e.g. `1234`

Attributes for each `Target`.

Attribute   | Description
----------- | -----------------------------------------------
`ringtime`  | Ringtime in sections, optional, default is `60`

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

Attribute   | Description
----------- | -------------------------------------------------
`reason`    | The reject reason for the call, for now: `"busy"`

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

### Queue

Coming soon.

## Code examples

* [Ruby](examples/ruby)
* [Node.js](examples/node)
* [PHP](examples/php)
* [Python](examples/python)
* [Java](examples/java)

Want to add your example? Open a [pull request]!

## FAQ

#### How much does it cost?

The API itself is provided free of charge; the usual connection charges may apply.

## Contributing

For improvements, feature requests or bug reports, please use [GitHub Issues](../../issues) or send us a [pull request].

![Placetel](https://www.placetel.de/content/placetel_logo_260x54.png)

[pull request]: ../../pulls
