import { test, expect } from '@playwright/test';

const API_URL = process.env.API_URL || process.env.BASE_URL || 'http://localhost:4000';

let authToken: string;

test.describe('Notes API E2E Tests', () => {
  // SC-001: Health check backend API
  test('SC-001: GET /api/health returns 200 with status ok', async ({ request }) => {
    const response = await request.get(`${API_URL}/api/health`);
    expect(response.status()).toBe(200);
    const body = await response.json();
    expect(body).toEqual({ status: 'ok' });
  });

  // SC-002: GET /api/notes without auth token returns 401
  test('SC-002: GET /api/notes without token returns 401', async ({ request }) => {
    const response = await request.get(`${API_URL}/api/notes`);
    expect(response.status()).toBe(401);
    const body = await response.json();
    expect(body).toHaveProperty('error', 'Unauthorized');
  });

  // SC-003: Get dev token and fetch notes list
  test('SC-003: POST /api/auth/dev-token and GET /api/notes with token', async ({ request }) => {
    // Step 1: Get dev token
    const tokenResponse = await request.post(`${API_URL}/api/auth/dev-token`);
    expect(tokenResponse.status()).toBe(200);
    const tokenBody = await tokenResponse.json();
    expect(tokenBody).toHaveProperty('token');
    expect(typeof tokenBody.token).toBe('string');
    expect(tokenBody.token.length).toBeGreaterThan(0);

    const token = tokenBody.token;

    // Step 2: Fetch notes with token
    const notesResponse = await request.get(`${API_URL}/api/notes`, {
      headers: { Authorization: `Bearer ${token}` },
    });
    expect(notesResponse.status()).toBe(200);
    const notes = await notesResponse.json();
    expect(Array.isArray(notes)).toBe(true);

    // Validate note structure if any notes exist
    if (notes.length > 0) {
      const note = notes[0];
      expect(note).toHaveProperty('id');
      expect(note).toHaveProperty('title');
      expect(note).toHaveProperty('content');
      expect(note).toHaveProperty('createdAt');
      expect(note).toHaveProperty('updatedAt');
    }
  });

  // SC-004: Create a note via POST /api/notes
  test('SC-004: POST /api/notes creates a note and returns 201', async ({ request }) => {
    // Get auth token
    const tokenResponse = await request.post(`${API_URL}/api/auth/dev-token`);
    const { token } = await tokenResponse.json();

    // Create note
    const response = await request.post(`${API_URL}/api/notes`, {
      headers: {
        Authorization: `Bearer ${token}`,
        'Content-Type': 'application/json',
      },
      data: {
        title: 'Тестовая заметка',
        content: 'Содержимое',
      },
    });
    expect(response.status()).toBe(201);
    const note = await response.json();
    expect(note).toHaveProperty('id');
    expect(note.title).toBe('Тестовая заметка');
    expect(note.content).toBe('Содержимое');
    expect(note).toHaveProperty('createdAt');
    expect(note).toHaveProperty('updatedAt');
  });

  // SC-005: Delete a note via DELETE /api/notes/:id
  test('SC-005: DELETE /api/notes/:id removes note and returns 204', async ({ request }) => {
    // Get auth token
    const tokenResponse = await request.post(`${API_URL}/api/auth/dev-token`);
    const { token } = await tokenResponse.json();
    const headers = { Authorization: `Bearer ${token}` };

    // Create a note to delete
    const createResponse = await request.post(`${API_URL}/api/notes`, {
      headers: { ...headers, 'Content-Type': 'application/json' },
      data: {
        title: 'Note to delete',
        content: 'This note will be deleted',
      },
    });
    expect(createResponse.status()).toBe(201);
    const createdNote = await createResponse.json();
    const noteId = createdNote.id;

    // Delete the note
    const deleteResponse = await request.delete(`${API_URL}/api/notes/${noteId}`, {
      headers,
    });
    expect(deleteResponse.status()).toBe(204);

    // Verify note is gone
    const getResponse = await request.get(`${API_URL}/api/notes/${noteId}`, {
      headers,
    });
    expect(getResponse.status()).toBe(404);
  });
});
