let waveHeight = 0;
let waveInSpeed = 10; // Speed for wave coming in
let waveOutSpeed; // Speed for wave retreating (calculated for 40 seconds)
let count = 0; // Count-up from 1 to 40
let state = "WAVE_IN"; // States: WAVE_IN, WAVE_OUT
let startTime = 0;

function setup() {
  createCanvas(1080, 1920); // 1080x1920 for vertical video
  // Set flipped gradient background (sand at bottom, ocean at top)
  for (let y = 0; y < height; y++) {
    let inter = map(y, height, 0, 0, 1); // Bottom (height) to top (0)
    let r = lerp(237, 135, inter); // Sand (237, 201, 175) to ocean (135, 206, 235)
    let g = lerp(201, 206, inter);
    let b = lerp(175, 235, inter);
    stroke(r, g, b);
    line(0, y, width, y);
  }
  // We'll set waveOutSpeed dynamically in draw() based on time
}

function draw() {
  // Redraw flipped gradient background
  for (let y = 0; y < height; y++) {
    let inter = map(y, height, 0, 0, 1);
    let r = lerp(237, 135, inter);
    let g = lerp(201, 206, inter);
    let b = lerp(175, 235, inter);
    stroke(r, g, b);
    line(0, y, width, y);
  }

  console.log("Frame Rate:", frameRate().toFixed(2), "FPS");

  if (state === "WAVE_IN") {
    console.log("WAVE_IN: waveHeight =", waveHeight.toFixed(2));
    drawWave(waveHeight);
    waveHeight += waveInSpeed;
    if (waveHeight >= height) {
      state = "WAVE_OUT";
      startTime = millis(); // Start timing for wave retreat and count-up
      console.log("Switching to WAVE_OUT at:", millis(), "ms");
      waveHeight = height; // Ensure starting point is exact
    }
  } else if (state === "WAVE_OUT") {
    let elapsed = (millis() - startTime) / 1000; // Time in seconds
    count = Math.floor(elapsed) + 1; // Count up from 1

    // Time-based retraction: waveHeight goes from 1920 to 0 over 40 seconds
    let progress = elapsed / 40; // Progress from 0 to 1 over 40 seconds
    if (progress > 1) progress = 1; // Cap at 1
    waveHeight = height * (1 - progress); // Linearly interpolate from height to 0

    console.log("WAVE_OUT: waveHeight =", waveHeight.toFixed(2));
    drawWave(waveHeight);

    if (count <= 40) {
      textAlign(CENTER, CENTER);
      textSize(150);
      textFont('Unbounded'); // Use Unbounded font from Google Fonts
      fill(255); // White text for contrast
      text(count, width / 2, height / 2);
      console.log("Elapsed:", elapsed.toFixed(2), "s, Count:", count, "waveHeight:", waveHeight.toFixed(2));
    }
  }
}

function drawWave(y) {
  // Gradient wave (white foam to light blue ocean)
  let gradientColors = [
    color(255, 255, 255), // White foam
    color(135, 206, 235), // Sky blue base
    color(0, 119, 190)    // Deeper ocean blue
  ];
  
  noStroke();
  beginShape();
  vertex(0, 0); // Top-left
  vertex(width, 0); // Top-right
  vertex(width, y); // Bottom-right of wave

  // Add wave curvature with gradient
  for (let x = width; x >= 0; x -= 10) {
    let waveY = y + sin(x * 0.01 + frameCount * 0.05) * 100; // Wavy effect
    let inter = map(waveY, 0, y, 0, 1); // Gradient based on wave height
    let c = lerpColor(gradientColors[0], gradientColors[2], inter);
    fill(c);
    vertex(x, waveY);
  }

  // Close the shape
  vertex(0, y); // Bottom-left of wave
  endShape(CLOSE);
}