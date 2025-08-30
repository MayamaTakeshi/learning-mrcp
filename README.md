# learning-mrcp

## Overview

This is a tutorial on the MRCP protocol.

We will only deal with MRCP version 2 which uses SIP as session establishment protocol.

We will not reference RFCs or other documents and will focus in practical exercises so that we can see how things works by actually using MRCP apps and tools.

You should already be familiar with SIP, SDP and RTP.

## Introduction to MRCP

Basically, MRCP is a client/server protocol where a client can establish a session with a server and request media services like TextToSpeech (TTS) or SpeechToText (ASR) translation.

The MRCP communication is initiated using a SIP INVITE transaction which negotiates the audio stream (RTP) to be used to send or receive audio to/from the server and also obtains an MRCP channel-identifier to open a TCP connection to the server to exchange MRCP messages. 

Here sample messages exchanges between a client and a server app:


The client sends and INVITE like this to the server:
```
INVITE sip:127.0.0.1:8060 SIP/2.0
To:  <sip:127.0.0.1:8060>
From:  <sip:mrcp_client@127.0.0.1:5060>;tag=195067
Call-ID: ef3640ef-6e74-496b-8823-653f3a1e6dc2
CSeq: 36896 INVITE
Content-Type: application/sdp
Contact:  <sip:mrcp_client@127.0.0.1:5060>
Via: SIP/2.0/UDP 127.0.0.1:5060;branch=z9hG4bK137627;rport
Content-Length: 273

v=0
o=mrcp_client 5772550679930491611 4608916746797952899 IN IP4 127.0.0.1
s=-
c=IN IP4 127.0.0.1
t=0 0
m=application 9 TCP/MRCPv2 1
a=setup:active
a=connection:new
a=resource:speechsynth
a=cmid:1
m=audio 44348 RTP/AVP 0
a=rtpmap:0 PCMU/8000
a=recvonly
a=mid:1

```
Notice that in the SDP, in addition to negotiating audio:
```
m=audio 44348 RTP/AVP 0
```
the client is also asking for MRCP communication:
```
m=application 9 TCP/MRCPv2 1
```
and it informs the type of resource it wants to use:
```
a=resource:speechsynth
```
Then the server replies with something like:
```
SIP/2.0 200 OK
Via: SIP/2.0/UDP 127.0.0.1:5060;branch=z9hG4bK137627;rport=5060
From: <sip:mrcp_client@127.0.0.1:5060>;tag=195067
To: <sip:127.0.0.1:8060>;tag=BUSB8jg6ZpHNK
Call-ID: ef3640ef-6e74-496b-8823-653f3a1e6dc2
CSeq: 36896 INVITE
Contact: <sip:127.0.0.1:8060>
User-Agent: UniMRCP SofiaSIP 1.8.0
Accept: application/sdp
Allow: INVITE, ACK, BYE, CANCEL, OPTIONS, PRACK, MESSAGE, SUBSCRIBE, NOTIFY, REFER, UPDATE
Supported: timer, 100rel
Session-Expires: 600;refresher=uas
Min-SE: 120
Content-Type: application/sdp
Content-Disposition: session
Content-Length: 300

v=0
o=UniMRCPServer 3742252434251997309 8094223898936178427 IN IP4 192.168.0.113
s=-
c=IN IP4 127.0.0.1
t=0 0
m=application 1544 TCP/MRCPv2 1
a=setup:passive
a=connection:new
a=channel:f2fc9efc74564012@speechsynth
a=cmid:1
m=audio 5000 RTP/AVP 0
a=mid:1nly PCMU/8000
```

Notice that the server specifies a port (1544) that the client should use to connect to the server using TCP:
```
m=application 1544 TCP/MRCPv2 1
```
and also provides a channel identifier:
```
a=channel:f2fc9efc74564012@speechsynth
```

Then the client ACKs the '200 OK' and opens a socket to TCP port 1544 and starts sendind MRCP messages (each message will include the channel-identifier as provided by the server in thet '200 OK' for the INVITE).

Here is the client asking the server to generate speech using the SPEAK command:
```
MRCP/2.0 155 SPEAK 1
channel-identifier: f2fc9efc74564012@speechsynth
speech-language: en-US
content-type: text/plain
content-length: 11

Hello World
```

The server accepts the request:
```

MRCP/2.0 83 1 200 IN-PROGRESS
Channel-Identifier: f2fc9efc74564012@speechsynth
```

and starts generating speech and transmitting it using the audio stream (RTP) negotiated in the SIP INVITE transation:

When the speech generation completes, the server informs this with this event:
```
MRCP/2.0 122 SPEAK-COMPLETE 1 COMPLETE
Channel-Identifier: f2fc9efc74564012@speechsynth
Completion-Cause: 000 normal
```

At this point, the client would disconnect the SIP call with a BYE request.

### sngrep2

[sngrep](https://github.com/irontec/sngrep) is a command-line tool that permits to visualize SIP messages flows.

However, it doesn't support MRCP, so we prepared a fork [sngrep2](https://github.com/MayamaTakeshi/sngrep/tree/mrcp_support) that supports it.

This will help follow SIP/MRCP messages while doing tests.

To install it, run:
```
sudo ./install_sngrep2.sh
```

Then start like like this:
```
sudo sngrep2 -d any
```
and keep it running in a shell in your desktop PC.


### Testing using mrcp_server and mrcp_client

We have [mrcp_server](https://github.com/MayamaTakeshi/mrcp_server)

and [mrcp_client](https://github.com/MayamaTakeshi/mrcp_client)

which are node.js apps that we can use to make MRCP tests and visualize their message flow.

If you are interested in details you can follow their documentation. But for our tests this is enough:

For mrcp_server, open a shell and do:
```
git clone https://github.com/MayamaTakeshi/mrcp_server
cd mrcp_server
npm install

# if you have a google credentials file with support for SpeechSynth and/or SpeechRecog export:
export GOOGLE_APPLICATION_CREDENTIALS=/path/to/your/credentials_file.json
# if you don't have it, it is OK. You can still test it by using language='dtmf' or language='morse'

cp config/default.js.sample config/default.js
node index.js
```
With the above, mrcp_server should be running waiting for connections.

Now for the mrcp_client, open another shell and do:
```
sudo apt install -y sox libasound2-dev
git clone https://github.com/MayamaTakeshi/mrcp_client
cd mrcp_client
npm install
cp config/default.js.sample config/default.js
```

Then you can make test calls like this:

If you have GOOGLE_APPLICATION_CREDENTIALS:
```
node speechsynth_client.js 127.0.0.1 8070 en-US en-US-Wavenet-E "Hello World."
```
or
```
node speechrecog_client.js 127.0.0.1 8070 ja-JP artifacts/ohayou_gozaimasu.wav builtin:speech/transcribe
```

If you don't have GOOGLE_APPLICATION_CREDENTIALS you can use DTMF as language:
```
node speechsynth_client.js 127.0.0.1 8070 dtmf dtmf 1234567890abcd*#
```
or
```
node speechrecog_client.js 127.0.0.1 8070 dtmf artifacts/dtmf.0123456789ABCDEF.16000hz.wav builtin:speech/transcribe
```

After making such test calls, check sngrep2 to see the SIP and MRCP messages exchanged by mrcp_server and mrcp_client.

Check [mrcp_client](https://github.com/MayamaTakeshi/mrcp_client) for more tests that can be done.

### unimrcp

Now, the TTS and ASR service providers like google, amazon, azure etc, don't typically provide access to their services using MRCP and instead, they are acceseed using non-standardized API calls via HTTP.

So to talk with such services we use [unimrcp](https://github.com/unispeech/unimrcp) which is an open source library and client/server application project for the MRCP protocol.

For each service like google TTS or google ASR, a plugin is provided to permit access to it (this requires a paid license per channel).

So the final step in this tutorial is to go to [unimrcp_experiments](https://github.com/MayamaTakeshi/unimrcp_experiments) to learn about it. Good luck.


