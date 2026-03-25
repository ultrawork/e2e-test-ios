import { test, expect } from '@playwright/test';

const apiUrl = process.env.API_URL || process.env.BASE_URL || 'http://localhost:3001';

let authToken: string;

test.beforeAll(async ({ request }) => {
  const response = await request.post(`${apiUrl}/api/auth/dev-token`);
  expect(response.status()).toBe(200);
  const body = await response.json();
  authToken = body.token;
});

// SC-001: Получение dev-токена
test('SC-001: POST /api/auth/dev-token returns a JWT token', async ({ request }) => {
  const response = await request.post(`${apiUrl}/api/auth/dev-token`);
  expect(response.status()).toBe(200);

  const body = await response.json();
  expect(body).toHaveProperty('token');
  expect(typeof body.token).toBe('string');
  expect(body.token.length).toBeGreaterThan(0);

  // JWT format: xxxxx.yyyyy.zzzzz
  const parts = body.token.split('.');
  expect(parts.length).toBe(3);
});

// SC-002: Загрузка заметок с валидным токеном
test('SC-002: GET /api/notes returns notes array with valid token', async ({ request }) => {
  const response = await request.get(`${apiUrl}/api/notes`, {
    headers: { Authorization: `Bearer ${authToken}` },
  });
  expect(response.status()).toBe(200);

  const notes = await response.json();
  expect(Array.isArray(notes)).toBe(true);

  if (notes.length > 0) {
    const note = notes[0];
    expect(note).toHaveProperty('id');
    expect(typeof note.id).toBe('string');
    expect(note).toHaveProperty('title');
    expect(typeof note.title).toBe('string');
    expect(note).toHaveProperty('content');
    expect(typeof note.content).toBe('string');
    expect(note).toHaveProperty('createdAt');
    expect(note).toHaveProperty('updatedAt');
    expect(note).toHaveProperty('categories');
    expect(Array.isArray(note.categories)).toBe(true);
  }
});

// SC-003: Создание заметки через API
test('SC-003: POST /api/notes creates a note', async ({ request }) => {
  const response = await request.post(`${apiUrl}/api/notes`, {
    headers: {
      Authorization: `Bearer ${authToken}`,
      'Content-Type': 'application/json',
    },
    data: { title: 'Test note', content: 'Test content' },
  });
  expect(response.status()).toBe(201);

  const note = await response.json();
  expect(note).toHaveProperty('id');
  expect(typeof note.id).toBe('string');
  expect(note.title).toBe('Test note');
  expect(note.content).toBe('Test content');
  expect(note).toHaveProperty('createdAt');
  expect(note).toHaveProperty('updatedAt');
  expect(note).toHaveProperty('categories');
  expect(Array.isArray(note.categories)).toBe(true);
});

// SC-004: Удаление заметки через API
test('SC-004: DELETE /api/notes/:id removes a note', async ({ request }) => {
  // Create a note first
  const createResponse = await request.post(`${apiUrl}/api/notes`, {
    headers: {
      Authorization: `Bearer ${authToken}`,
      'Content-Type': 'application/json',
    },
    data: { title: 'Note to delete', content: 'Will be deleted' },
  });
  expect(createResponse.status()).toBe(201);
  const created = await createResponse.json();

  // Delete it
  const deleteResponse = await request.delete(`${apiUrl}/api/notes/${created.id}`, {
    headers: { Authorization: `Bearer ${authToken}` },
  });
  expect(deleteResponse.status()).toBe(204);

  // Verify it's gone
  const listResponse = await request.get(`${apiUrl}/api/notes`, {
    headers: { Authorization: `Bearer ${authToken}` },
  });
  const notes = await listResponse.json();
  const found = notes.find((n: { id: string }) => n.id === created.id);
  expect(found).toBeUndefined();
});

// SC-005: Запрос заметок без токена возвращает 401
test('SC-005: GET /api/notes without token returns 401', async ({ request }) => {
  const response = await request.get(`${apiUrl}/api/notes`);
  expect(response.status()).toBe(401);

  const body = await response.json();
  expect(body).toHaveProperty('error');
});
