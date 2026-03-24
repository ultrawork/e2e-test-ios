import { test, expect } from '@playwright/test';

const apiUrl = process.env.API_URL || process.env.BASE_URL || 'http://localhost:4000';

test.describe('API: Authorization and token contract', () => {
  // SC-1: GET /api/notes with Authorization header returns 200
  test('SC-1: GET /api/notes with Authorization header returns 200', async ({ request }) => {
    const response = await request.get(`${apiUrl}/api/notes`, {
      headers: {
        Authorization: 'Bearer test-token-123',
      },
    });

    expect(response.status()).toBe(200);
    expect(response.headers()['content-type']).toContain('application/json');

    const body = await response.json();
    expect(Array.isArray(body)).toBe(true);
  });

  // SC-2: GET /api/notes without Authorization header
  test('SC-2: GET /api/notes without Authorization header returns 200', async ({ request }) => {
    const response = await request.get(`${apiUrl}/api/notes`);

    expect(response.status()).toBe(200);
    expect(response.headers()['content-type']).toContain('application/json');

    const body = await response.json();
    expect(Array.isArray(body)).toBe(true);
  });

  // SC-3: Response format matches iOS client contract
  test('SC-3: GET /api/notes response format matches iOS client contract', async ({ request }) => {
    // Create a note first
    const createResponse = await request.post(`${apiUrl}/api/notes`, {
      headers: {
        Authorization: 'Bearer test-token',
        'Content-Type': 'application/json',
      },
      data: {
        title: 'Test Note',
        content: 'Test content',
      },
    });
    expect(createResponse.status()).toBe(201);

    // Fetch notes
    const response = await request.get(`${apiUrl}/api/notes`, {
      headers: {
        Authorization: 'Bearer test-token',
      },
    });

    expect(response.status()).toBe(200);

    const body = await response.json();
    expect(Array.isArray(body)).toBe(true);
    expect(body.length).toBeGreaterThan(0);

    const note = body[0];
    expect(typeof note.id).toBe('string');
    expect(typeof note.title).toBe('string');
    expect(typeof note.content).toBe('string');
  });
});
