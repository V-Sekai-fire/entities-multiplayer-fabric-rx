# Presence: the client's end of the zone relay

`addons/vsk_presence/presence_client.gd` (`VskPresenceClient`) is one person's end of the zone relay of RFD66606-2493 (`transport-zone-relay`, whose AsyncAPI 3.1 document is `service/zone-relay.asyncapi.yaml`). It moves bytes and reads none of them: the caller supplies the frames and decodes the ones it receives.

## The contract it keeps

- A person sends two frames at a send, each at most 1,472 bytes (a full frame is 12 Packets of 100 bytes). The first goes to the relay's `PORT` and the second to `PORT + 1`, from one socket, so the relay knows the person by one address.
- The relay hands a taken frame on byte for byte, from the socket of the same half, to the other people of the zone and never to the sender. The client tells the halves apart by the source port of a datagram, not by its content.
- The relay takes one frame per half in five of its 64 Hz ticks, so a caller sends at most once every six ticks. A frame sent before the other person is known has no one to go to.

## The test

`tests/presence/presence_client_test.gd` sends a frame to each half from two clients through the real relay, `zone_serve` of `transport-zone-relay`, and each client must receive the other's two frames, byte for byte, and none of its own. Import the project first, then run:

    godot --headless --path . --script tests/presence/presence_client_test.gd -- --relay=PATH [--control=half] [--port=N]

- **The relay.** `tests/presence/relay_process.gd` runs it as a child process on `127.0.0.1`, `PORT` and `PORT + 1`, for 640 ticks. The test refuses ports that are already taken. The relay is ready only while its own process is alive and holds both ports, and the test fails at once if it never becomes ready.
- **The control.** `--control=half` expects a relay built with `-DZN_PLANT_HALF`, which sends each frame from the other half's socket. The test must find that defect.
- **Waiting.** The test waits in frames, never in time. Frames reach only people the relay already knows, so the first send carries other bytes and waits for any frame at all: only the person the relay learned of first receives frames then, and which one varies. Its late frames are ignored. The second send is measured: each person must receive two frames, or `FRAMES_MAX` (6000) frames pass.
- **On Windows,** the relay runs in WSL with mirrored networking, started through a one-line `.cmd` wrapper (`wsl.exe -e zone_serve %*`).

## What is next

The frames of the real body (the packets guest and the muscle skeleton) in place of the test bytes, then four bodies through the relay (the sight gate). Nothing here is wired into the game scenes.
