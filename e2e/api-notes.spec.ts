import { test, expect } from '@playwright/test';

const apiUrl = process.env.API_URL || process.env.BASE_URL || 'http://localhost:4000';

test.describe('API Notes', () => {
  test('SC-001: Create a note via API', async ({ request }) => {
    const response = await request.post(`${apiUrl}/api/notes`, {
      data: {
        title: 'Тестовая заметка',
        content: 'Содержимое заметки',
      },
    });

    expect(response.status()).toBe(201);

    const body = await response.json();
    expect(body.id).toBeTruthy();
    expect(typeof body.id).toBe('string');
    expect(body.title).toBe('Тестовая заметка');
    expect(body.content).toBe('Содержимое заметки');
    expect(body.userId).toBe('default-user-id');
    expect(body.createdAt).toBeTruthy();
    expect(body.updatedAt).toBeTruthy();
    expect(Array.isArray(body.categories)).toBe(true);
  });

  test('SC-002: Get list of notes via API', async ({ request }) => {
    // Create a note first
    const createResponse = await request.post(`${apiUrl}/api/notes`, {
      data: {
        title: 'Заметка для списка',
        content: 'Контент',
      },
    });
    expect(createResponse.status()).toBe(201);

    // Fetch notes
    const response = await request.get(`${apiUrl}/api/notes`);
    expect(response.status()).toBe(200);

    const notes = await response.json();
    expect(Array.isArray(notes)).toBe(true);
    expect(notes.length).toBeGreaterThanOrEqual(1);

    const found = notes.find((n: any) => n.title === 'Заметка для списка');
    expect(found).toBeTruthy();
    expect(found.id).toBeTruthy();
    expect(found.content).toBeTruthy();
    expect(found.userId).toBeTruthy();
    expect(found.createdAt).toBeTruthy();
    expect(found.updatedAt).toBeTruthy();
    expect(Array.isArray(found.categories)).toBe(true);
  });

  test('SC-003: Create note without required fields returns 400', async ({ request }) => {
    const response = await request.post(`${apiUrl}/api/notes`, {
      data: {},
    });

    expect(response.status()).toBe(400);

    const body = await response.json();
    expect(body.error).toBe('title and content are required');
  });

  test('SC-004: Delete a note via API', async ({ request }) => {
    // Create a note
    const createResponse = await request.post(`${apiUrl}/api/notes`, {
      data: {
        title: 'Удаляемая заметка',
        content: 'Контент',
      },
    });
    expect(createResponse.status()).toBe(201);
    const created = await createResponse.json();
    const noteId = created.id;

    // Delete note
    const deleteResponse = await request.delete(`${apiUrl}/api/notes/${noteId}`);
    expect(deleteResponse.status()).toBe(204);

    // Verify deletion
    const listResponse = await request.get(`${apiUrl}/api/notes`);
    const notes = await listResponse.json();
    const found = notes.find((n: any) => n.id === noteId);
    expect(found).toBeUndefined();
  });

  test('SC-005: Delete non-existent note returns 404', async ({ request }) => {
    const response = await request.delete(`${apiUrl}/api/notes/non-existent-id-12345`);

    expect(response.status()).toBe(404);

    const body = await response.json();
    expect(body.error).toBe('Note not found');
  });
});
