import { test, expect } from '@playwright/test';

const apiUrl = process.env.API_URL || process.env.BASE_URL || 'http://localhost:4000';

async function getDevToken(request: any): Promise<string> {
  const response = await request.post(`${apiUrl}/api/auth/dev-token`);
  expect(response.status()).toBe(200);
  const body = await response.json();
  expect(body.token).toBeTruthy();
  return body.token;
}

// SC-1: Получение dev-токена через /api/auth/dev-token
test('SC-1: POST /api/auth/dev-token returns a valid JWT token', async ({ request }) => {
  const response = await request.post(`${apiUrl}/api/auth/dev-token`);
  expect(response.status()).toBe(200);
  const body = await response.json();
  expect(body).toHaveProperty('token');
  expect(typeof body.token).toBe('string');
  expect(body.token.length).toBeGreaterThan(0);
});

// SC-2: Получение списка заметок с Bearer-токеном
test('SC-2: GET /api/notes returns a list of notes with Bearer token', async ({ request }) => {
  const token = await getDevToken(request);

  const response = await request.get(`${apiUrl}/api/notes`, {
    headers: { Authorization: `Bearer ${token}` },
  });
  expect(response.status()).toBe(200);
  const notes = await response.json();
  expect(Array.isArray(notes)).toBe(true);

  if (notes.length > 0) {
    const note = notes[0];
    expect(note).toHaveProperty('id');
    expect(note).toHaveProperty('title');
    expect(note).toHaveProperty('content');
  }
});

// SC-3: Создание заметки через POST /api/notes
test('SC-3: POST /api/notes creates a new note', async ({ request }) => {
  const token = await getDevToken(request);

  const response = await request.post(`${apiUrl}/api/notes`, {
    headers: {
      Authorization: `Bearer ${token}`,
      'Content-Type': 'application/json',
    },
    data: { title: 'Test Note', content: 'Test Note' },
  });
  expect(response.status()).toBe(201);
  const note = await response.json();
  expect(note).toHaveProperty('id');
  expect(typeof note.id).toBe('string');
  expect(note.id.length).toBeGreaterThan(0);
  expect(note.title).toBe('Test Note');
  expect(note).toHaveProperty('content');

  // Cleanup
  await request.delete(`${apiUrl}/api/notes/${note.id}`, {
    headers: { Authorization: `Bearer ${token}` },
  });
});

// SC-4: Удаление заметки через DELETE /api/notes/:id
test('SC-4: DELETE /api/notes/:id removes a note', async ({ request }) => {
  const token = await getDevToken(request);

  // Create a note to delete
  const createResponse = await request.post(`${apiUrl}/api/notes`, {
    headers: {
      Authorization: `Bearer ${token}`,
      'Content-Type': 'application/json',
    },
    data: { title: 'To Delete', content: 'To Delete' },
  });
  expect(createResponse.status()).toBe(201);
  const created = await createResponse.json();
  const noteId = created.id;

  // Delete it
  const deleteResponse = await request.delete(`${apiUrl}/api/notes/${noteId}`, {
    headers: { Authorization: `Bearer ${token}` },
  });
  expect(deleteResponse.status()).toBe(204);

  // Verify it's gone
  const listResponse = await request.get(`${apiUrl}/api/notes`, {
    headers: { Authorization: `Bearer ${token}` },
  });
  expect(listResponse.status()).toBe(200);
  const notes = await listResponse.json();
  const found = notes.find((n: any) => n.id === noteId);
  expect(found).toBeUndefined();
});

// SC-5: Запрос без токена возвращает 401
test('SC-5: GET /api/notes without Authorization returns 401', async ({ request }) => {
  const response = await request.get(`${apiUrl}/api/notes`);
  expect(response.status()).toBe(401);
  const body = await response.json();
  expect(body).toHaveProperty('error');
});
