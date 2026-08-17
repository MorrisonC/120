const WebSocket = require('ws');
const { spawn } = require('child_process');
const path = require('path');

const PORT = 8080;
let godotProcess = null;

async function runHarness() {
    console.log("Starting Godot headless server for test harness...");
    godotProcess = spawn('godot4', ['--headless', '--path', path.join(__dirname, 'game')], {
        stdio: 'ignore'
    });

    // Give Godot time to initialize and start the WS Server
    await new Promise(r => setTimeout(r, 2000));

    console.log(`Connecting to WebSocket on ws://localhost:${PORT}...`);
    const ws = new WebSocket(`ws://localhost:${PORT}`);

    let stateSnapshots = [];
    let stateCount = 0;

    ws.on('open', function open() {
        console.log("WebSocket connected. Listening for state snapshots...");
        // Send a mock input just to test bidirectional
        ws.send(JSON.stringify({type: 'input', action: 'move_right'}));
    });

    ws.on('message', function message(data) {
        const payload = JSON.parse(data.toString());
        if (payload.type === 'state') {
            stateSnapshots.push(payload);
            stateCount++;

            if (stateCount >= 5) {
                console.log(`Received 5 snapshots. Disconnecting and verifying determinism...`);
                ws.close();
            }
        }
    });

    ws.on('close', function close() {
        console.log("WebSocket connection closed.");

        let valid = true;
        for (let i = 1; i < stateSnapshots.length; i++) {
            let curr = stateSnapshots[i];
            let prev = stateSnapshots[i-1];

            if (curr.tick <= prev.tick) {
                console.error(`Determinism Failure: Tick ${curr.tick} did not increment from ${prev.tick}`);
                valid = false;
            }
            if (curr.time_remaining >= prev.time_remaining) {
                console.error(`Determinism Failure: Time ${curr.time_remaining} did not decrease from ${prev.time_remaining}`);
                valid = false;
            }
        }

        if (valid) {
            console.log("SUCCESS: Tick determinism verified across WebSocket snapshots.");
        }

        // Cleanup Godot process
        if (godotProcess) {
            godotProcess.kill();
        }
        process.exit(valid ? 0 : 1);
    });

    ws.on('error', function error(err) {
        console.error("WebSocket Error:", err);
        if (godotProcess) {
            godotProcess.kill();
        }
        process.exit(1);
    });

    // Timeout catchall
    setTimeout(() => {
        console.error("Timeout waiting for enough snapshots.");
        if (godotProcess) {
            godotProcess.kill();
        }
        process.exit(1);
    }, 10000);
}

runHarness();
