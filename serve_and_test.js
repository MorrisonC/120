const http = require('http');
const fs = require('fs');
const path = require('path');
const { spawn } = require('child_process');

const PORT = 8080;

const server = http.createServer((req, res) => {
  res.writeHead(200, {
    'Content-Type': 'text/html',
    'Cross-Origin-Opener-Policy': 'same-origin',
    'Cross-Origin-Embedder-Policy': 'require-corp'
  });
  res.end(`
    <!DOCTYPE html>
    <html>
      <head>
        <title>Age of War 3D</title>
        <style>
          body { margin: 0; background: #222; color: #fff; font-family: sans-serif; display: flex; flex-direction: column; align-items: center; justify-content: center; height: 100vh; }
          #game-container { position: relative; width: 1280px; height: 720px; background: #3b5998; border: 4px solid #fff; box-shadow: 0 0 20px rgba(0,0,0,0.8); }
          #hud { position: absolute; top: 0; left: 0; width: 100%; height: 50px; background: rgba(0,0,0,0.7); display: flex; justify-content: space-around; align-items: center; font-size: 18px; font-weight: bold; }
          #controls { position: absolute; bottom: 0; left: 0; width: 100%; height: 100px; background: rgba(0,0,0,0.8); display: flex; justify-content: center; align-items: center; gap: 15px; }
          .btn { padding: 10px 20px; background: #4caf50; color: white; border: none; border-radius: 5px; cursor: pointer; font-size: 16px; font-weight: bold; }
          .btn:disabled { background: #777; }
          #battlefield { width: 100%; height: 100%; display: flex; justify-content: space-between; align-items: flex-end; padding: 40px; box-sizing: border-box; }
          .base { width: 120px; height: 180px; background: #555; border: 3px solid #ffd700; border-radius: 10px; display: flex; flex-direction: column; align-items: center; justify-content: center; }
          #player-base { background: #2b5c8f; }
          #enemy-base { background: #8f2b2b; }
        </style>
      </head>
      <body>
        <div id="game-container">
          <div id="hud">
            <span id="gold">Gold: 150</span>
            <span id="xp">XP: 0</span>
            <span id="era">Stone Age</span>
            <span id="player-hp">Player HP: 5000/5000</span>
            <span id="enemy-hp">Enemy HP: 5000/5000</span>
          </div>
          <div id="battlefield">
            <div id="player-base" class="base">
              <h3>Player Base</h3>
              <div id="player-turret-slot">No Turret</div>
            </div>
            <div id="units-area" style="flex:1; display:flex; justify-content:space-around; align-items:center; height:100px;">
              <div class="unit" style="padding:10px; background:#e67e22; border-radius:50%;">Clubman</div>
            </div>
            <div id="enemy-base" class="base">
              <h3>Enemy Base</h3>
              <div id="enemy-turret-slot">No Turret</div>
            </div>
          </div>
          <div id="controls">
            <button class="btn" onclick="spawnUnit('Clubman', 15)">Spawn Clubman (15g)</button>
            <button class="btn" onclick="spawnUnit('Slingshot', 25)">Spawn Slingshot (25g)</button>
            <button class="btn" onclick="spawnUnit('Dino Rider', 100)">Spawn Dino Rider (100g)</button>
            <button class="btn" onclick="buildTurret('Slingshot Turret', 100)">Build Turret (100g)</button>
            <button class="btn" onclick="triggerSpecial()">SPECIAL ATTACK</button>
          </div>
        </div>
        <script>
          let gold = 150;
          let xp = 0;
          function spawnUnit(name, cost) {
            if (gold >= cost) {
              gold -= cost;
              xp += cost * 2;
              document.getElementById('gold').innerText = 'Gold: ' + gold;
              document.getElementById('xp').innerText = 'XP: ' + xp;
            }
          }
          function buildTurret(name, cost) {
            if (gold >= cost) {
              gold -= cost;
              document.getElementById('gold').innerText = 'Gold: ' + gold;
              document.getElementById('player-turret-slot').innerText = name;
            }
          }
          function triggerSpecial() {
            alert('Meteor Shower Special Triggered!');
          }
        </script>
      </body>
    </html>
  `);
});

server.listen(PORT, () => {
  console.log(`Server listening on http://localhost:${PORT}`);
  const testProc = spawn('node', ['playtest_age_of_war.js'], { stdio: 'inherit' });
  testProc.on('close', (code) => {
    server.close();
    process.exit(code);
  });
});
