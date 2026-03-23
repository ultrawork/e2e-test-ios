import { defineConfig } from '@playwright/test';

export default defineConfig({
  testDir: './e2e',
  timeout: 30000,
  retries: 2,
  use: {
    baseURL: process.env.BASE_URL || 'http://localhost:4000',
  },
  reporter: [['junit', { outputFile: 'test-results/results.xml' }]],
});
