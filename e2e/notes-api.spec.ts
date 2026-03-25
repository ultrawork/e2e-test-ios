import { test, expect } from '@playwright/test';

const API_URL = process.env.API_URL || process.env.BASE_URL || 'http://localhost:4000';

async function getDevToken(baseUrl: string): Promise<string> {
  const response = await fetch(`${baseUrl}/api/auth/dev-token`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
  });
  expect(response.status).toBe(200);
  const body = await response.json();
  expect(body.token).toBeTruthy();
  return body.token;
}

// SC-1: Получение dev-токена через /api/auth/dev-token
test('SC-1: POST /api/auth/dev-token returns a valid JWT token', async () => {
  const response = await fetch(`${API_URL}/api/auth/dev-token`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
  });

  expect(response.status).toBe(200);
  const body = await response.json();
  expect(body).toHaveProperty('token');
  expect(typeof body.token).toBe('string');
  expect(body.token.length).toBeGreaterThan(0);
});

// SC-2: Получение списка заметок с Bearer-токеном
test('SC-2: GET /api/notes with Bearer token returns notes array', async () => {
  const token = await getDevToken(API_URL);

  const response = await fetch(`${API_URL}/api/notes`, {
    method: 'GET',
    headers: { Authorization: `Bearer ${token}` },
  });

  expect(response.status).toBe(200);
  const body = await response.json();
  expect(Array.isArray(body)).toBe(true);

  if (body.length > 0) {
    const note = body[0];
    expect(note).toHaveProperty('id');
    expect(note).toHaveProperty('title');
    expect(note).toHaveProperty('content');
    // Check for either snake_case or camelCase date fields
    const hasCreatedAt = 'created_at' in note || 'createdAt' in note;
    const hasUpdatedAt = 'updated_at' in note || 'updatedAt' in note;
    expect(hasCreatedAt).toBe(true);
    expect(hasUpdatedAt).toBe(true);
  }
});

// SC-3: Создание заметки через POST /api/notes
test('SC-3: POST /api/notes creates a note and returns it', async () => {
  const token = await getDevToken(API_URL);

  const response = await fetch(`${API_URL}/api/notes`, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${token}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ title: 'Test Note', content: '' }),
  });

  expect(response.status).toBe(201);
  const note = await response.json();
  expect(note).toHaveProperty('id');
  expect(typeof note.id).toBe('string');
  expect(note.id.length).toBeGreaterThan(0);
  expect(note.title).toBe('Test Note');
  expect(note).toHaveProperty('content');
  const hasCreatedAt = 'created_at' in note || 'createdAt' in note;
  const hasUpdatedAt = 'updated_at' in note || 'updatedAt' in note;
  expect(hasCreatedAt).toBe(true);
  expect(hasUpdatedAt).toBe(true);
});

// SC-4: Удаление заметки через DELETE /api/notes/:id
test('SC-4: DELETE /api/notes/:id removes the note', async () => {
  const token = await getDevToken(API_URL);

  // Create a note to delete
  const createResponse = await fetch(`${API_URL}/api/notes`, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${token}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ title: 'To Delete', content: '' }),
  });
  expect(createResponse.status).toBe(201);
  const created = await createResponse.json();
  const noteId = created.id;

  // Delete the note
  const deleteResponse = await fetch(`${API_URL}/api/notes/${noteId}`, {
    method: 'DELETE',
    headers: { Authorization: `Bearer ${token}` },
  });
  expect(deleteResponse.status).toBe(204);

  // Verify note is gone
  const listResponse = await fetch(`${API_URL}/api/notes`, {
    method: 'GET',
    headers: { Authorization: `Bearer ${token}` },
  });
  expect(listResponse.status).toBe(200);
  const notes = await listResponse.json();
  const found = notes.find((n: { id: string }) => n.id === noteId);
  expect(found).toBeUndefined();
});

// SC-5: Запрос без токена возвращает 401
test('SC-5: GET /api/notes without Authorization returns 401', async () => {
  const response = await fetch(`${API_URL}/api/notes`, {
    method: 'GET',
  });

  expect(response.status).toBe(401);
  const body = await response.json();
  expect(body).toHaveProperty('error');
});
