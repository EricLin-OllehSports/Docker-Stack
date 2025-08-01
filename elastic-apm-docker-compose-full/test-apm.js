#!/usr/bin/env node

/**
 * APM Test Script - Node.js
 * Tests APM integration with sample transactions and errors
 */

// Initialize APM agent
const apm = require('elastic-apm-node').start({
  serviceName: 'test-app',
  secretToken: '',
  serverUrl: 'http://localhost:8200',
  environment: 'test',
  active: true,
  captureBody: 'errors',
  captureHeaders: true,
  logLevel: 'info'
});

console.log('🚀 Starting APM Test Application...');

// Simulate a successful transaction
async function successfulTransaction() {
  const transaction = apm.startTransaction('test-success', 'custom');
  
  console.log('✅ Running successful transaction...');
  
  // Create a span
  const span = apm.startSpan('database-query', 'db', 'postgresql', 'query');
  
  // Simulate some work
  await new Promise(resolve => setTimeout(resolve, 100));
  
  if (span) span.end();
  
  transaction.result = 'success';
  transaction.end();
  
  console.log('   Transaction completed successfully');
}

// Simulate an error transaction
async function errorTransaction() {
  const transaction = apm.startTransaction('test-error', 'custom');
  
  console.log('❌ Running error transaction...');
  
  try {
    // Simulate an error
    throw new Error('Test error for APM monitoring');
  } catch (error) {
    apm.captureError(error);
    console.log('   Error captured:', error.message);
  }
  
  transaction.result = 'error';
  transaction.end();
}

// Simulate HTTP requests
async function httpTransaction() {
  const transaction = apm.startTransaction('http-request', 'request');
  
  console.log('🌐 Running HTTP simulation...');
  
  // Simulate HTTP spans
  const httpSpan = apm.startSpan('external-http', 'external', 'http');
  await new Promise(resolve => setTimeout(resolve, 200));
  if (httpSpan) httpSpan.end();
  
  transaction.result = 'HTTP/2.0 200 OK';
  transaction.end();
  
  console.log('   HTTP transaction completed');
}

// Add custom metrics
function sendCustomMetrics() {
  console.log('📊 Sending custom metrics...');
  
  apm.setCustomContext({
    user: {
      id: 'test-user-123',
      username: 'testuser',
      email: 'test@example.com'
    },
    custom: {
      environment: 'test',
      version: '1.0.0',
      feature_flags: ['flag_a', 'flag_b']
    }
  });
  
  // Add labels
  apm.addLabels({
    service_tier: 'premium',
    region: 'us-west-1',
    test_run: Date.now()
  });
  
  console.log('   Custom metrics sent');
}

// Main test execution
async function runTests() {
  try {
    console.log('\n📋 APM Test Suite Starting...\n');
    
    // Test 1: Successful transaction
    await successfulTransaction();
    await new Promise(resolve => setTimeout(resolve, 500));
    
    // Test 2: Error transaction
    await errorTransaction(); 
    await new Promise(resolve => setTimeout(resolve, 500));
    
    // Test 3: HTTP simulation
    await httpTransaction();
    await new Promise(resolve => setTimeout(resolve, 500));
    
    // Test 4: Custom metrics
    sendCustomMetrics();
    await new Promise(resolve => setTimeout(resolve, 500));
    
    console.log('\n✨ All tests completed!');
    console.log('📊 Check APM data at: http://localhost:5601/app/apm');
    console.log('🔍 Service: test-app');
    console.log('⏱️  Data should appear within 30-60 seconds\n');
    
  } catch (error) {
    console.error('❌ Test execution failed:', error);
    apm.captureError(error);
  }
  
  // Keep the process alive briefly to ensure data is sent
  setTimeout(() => {
    console.log('🏁 Test completed. Exiting...');
    process.exit(0);
  }, 2000);
}

// Handle process termination
process.on('SIGINT', () => {
  console.log('\n⚠️  Received SIGINT, shutting down gracefully...');
  apm.flush(() => {
    process.exit(0);
  });
});

// Run the tests
runTests().catch(console.error);