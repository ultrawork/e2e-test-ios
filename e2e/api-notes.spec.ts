import { test, expect } from '@playwright/test';

const apiUrl = process.env.API_URL || process.env.BASE_URL || 'http://localhost:4000';

test.describe('API: Notes CRUD', () => {

  // SC-007: Health endpoint
  test('SC-007: health endpoint returns ok', async ({ request }) => {
    const response = await request.get(`${apiUrl}/health`);
    expect(response.status()).toBe(200);
    const body = await response.json();
    expect(body).toEqual({ status: 'ok' });
  });

  // SC-001: Get notes from empty database
  test('SC-001: GET /api/notes returns empty array initially', async ({ request }) => {
    const response = await request.get(`${apiUrl}/api/notes`);
    expect(response.status()).toBe(200);
    expect(response.headers()['content-type']).toContain('application/json');
    const body = await response.json();
    expect(Array.isArray(body)).toBe(true);
  });

  // SC-002: Create a note
  test('SC-002: POST /api/notes creates a note', async ({ request }) => {
    const response = await request.post(`${apiUrl}/api/notes`, {
      headers: { 'Content-Type': 'application/json' },
      data: { title: 'Тестовая заметка', content: 'Содержимое заметки' },
    });
    expect(response.status()).toBe(201);
    const note = await response.json();
    expect(note.id).toBeTruthy();
    expect(note.title).toBe('Тестовая заметка');
    expect(note.content).toBe('Содержимое заметки');
    expect(note.userId).toBe('default-user-id');
    expect(note.createdAt).toBeTruthy();
    expect(note.updatedAt).toBeTruthy();
    expect(Array.isArray(note.categories)).toBe(true);
  });

  // SC-003: Get notes after creation
  test('SC-003: GET /api/notes returns created note', async ({ request }) => {
    // Create a note first
    const createRes = await request.post(`${apiUrl}/api/notes`, {
      headers: { 'Content-Type': 'application/json' },
      data: { title: 'Заметка для списка', content: 'Текст' },
    });
    expect(createRes.status()).toBe(201);

    // Fetch all notes
    const response = await request.get(`${apiUrl}/api/notes`);
    expect(response.status()).toBe(200);
    const notes = await response.json();
    expect(Array.isArray(notes)).toBe(true);
    const found = notes.find((n: any) => n.title === 'Заметка для списка');
    expect(found).toBeTruthy();
    expect(found.id).toBeTruthy();
    expect(found.content).toBe('Текст');
    expect(found.userId).toBeTruthy();
    expect(found.createdAt).toBeTruthy();
    expect(found.updatedAt).toBeTruthy();
    expect(Array.isArray(found.categories)).toBe(true);
  });

  // SC-004: Delete a note
  test('SC-004: DELETE /api/notes/:id removes the note', async ({ request }) => {
    // Create a note
    const createRes = await request.post(`${apiUrl}/api/notes`, {
      headers: { 'Content-Type': 'application/json' },
      data: { title: 'Для удаления', content: 'Текст' },
    });
    expect(createRes.status()).toBe(201);
    const created = await createRes.json();

    // Delete it
    const deleteRes = await request.delete(`${apiUrl}/api/notes/${created.id}`);
    expect(deleteRes.status()).toBe(204);

    // Verify it's gone
    const listRes = await request.get(`${apiUrl}/api/notes`);
    const notes = await listRes.json();
    const found = notes.find((n: any) => n.id === created.id);
    expect(found).toBeUndefined();
  });

  // SC-005: Create note without required fields
  test('SC-005: POST /api/notes with empty fields returns 400', async ({ request }) => {
    // Empty title and content
    const res1 = await request.post(`${apiUrl}/api/notes`, {
      headers: { 'Content-Type': 'application/json' },
      data: { title: '', content: '' },
    });
    expect(res1.status()).toBe(400);
    const body1 = await res1.json();
    expect(body1.error).toBe('title and content are required');

    // Empty object
    const res2 = await request.post(`${apiUrl}/api/notes`, {
      headers: { 'Content-Type': 'application/json' },
      data: {},
    });
    expect(res2.status()).toBe(400);
    const body2 = await res2.json();
    expect(body2.error).toBe('title and content are required');
  });

  // SC-006: Delete non-existent note
  test('SC-006: DELETE /api/notes/nonexistent returns 404', async ({ request }) => {
    const response = await request.delete(`${apiUrl}/api/notes/nonexistent-id-12345`);
    expect(response.status()).toBe(404);
    const body = await response.json();
    expect(body.error).toBe('Note not found');
  });
});
