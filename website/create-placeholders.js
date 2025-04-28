// Create placeholder images for the website
const fs = require('fs');
const { createCanvas } = require('canvas');

// Function to create a placeholder image
function createPlaceholderImage(width, height, text, filename) {
  const canvas = createCanvas(width, height);
  const ctx = canvas.getContext('2d');
  
  // Background gradient
  const gradient = ctx.createLinearGradient(0, 0, width, height);
  gradient.addColorStop(0, '#4a6da7');
  gradient.addColorStop(1, '#5d9cec');
  ctx.fillStyle = gradient;
  ctx.fillRect(0, 0, width, height);
  
  // Add some design elements
  ctx.fillStyle = 'rgba(255, 255, 255, 0.1)';
  ctx.beginPath();
  ctx.arc(width * 0.8, height * 0.2, width * 0.3, 0, Math.PI * 2);
  ctx.fill();
  
  ctx.beginPath();
  ctx.arc(width * 0.2, height * 0.8, width * 0.25, 0, Math.PI * 2);
  ctx.fill();
  
  // Add text
  ctx.font = 'bold 24px Arial';
  ctx.textAlign = 'center';
  ctx.textBaseline = 'middle';
  ctx.fillStyle = 'white';
  ctx.fillText(text, width / 2, height / 2);
  
  // Save the image
  const buffer = canvas.toBuffer('image/png');
  fs.writeFileSync(filename, buffer);
  
  console.log(`Created ${filename}`);
}

// Create placeholder images for the app screenshots
createPlaceholderImage(800, 500, 'Invoice Creation Screen', 'images/invoice-creation.png');
createPlaceholderImage(800, 500, 'Client Management Screen', 'images/client-management.png');
createPlaceholderImage(800, 500, 'PDF Generation Feature', 'images/pdf-generation.png');

// Create placeholder images for testimonials
createPlaceholderImage(100, 100, 'T1', 'images/testimonial-1.jpg');
createPlaceholderImage(100, 100, 'T2', 'images/testimonial-2.jpg');
createPlaceholderImage(100, 100, 'T3', 'images/testimonial-3.jpg');

console.log('All placeholder images created successfully!');
