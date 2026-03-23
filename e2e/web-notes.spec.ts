import { test, expect } from '@playwright/test';

test.describe('Web Notes UI', () => {
  test('SC-006: Add a note on Notes page', async ({ page }) => {
    await page.goto('/notes');

    // Verify empty state
    await expect(page.getByText('Всего заметок: 0')).toBeVisible();

    // Add a note
    await page.getByPlaceholder('Enter a note').fill('Моя первая заметка');
    await page.getByRole('button', { name: 'Add' }).click();

    // Verify note appears and counter updates
    await expect(page.getByText('Моя первая заметка')).toBeVisible();
    await expect(page.getByPlaceholder('Enter a note')).toHaveValue('');
    await expect(page.getByText('Всего заметок: 1')).toBeVisible();
  });

  test('SC-007: Delete a note on Notes page', async ({ page }) => {
    await page.goto('/notes');

    // Add a note
    await page.getByPlaceholder('Enter a note').fill('Заметка для удаления');
    await page.getByRole('button', { name: 'Add' }).click();
    await expect(page.getByText('Заметка для удаления')).toBeVisible();

    const countBefore = await page.getByText(/Всего заметок: \d+/).textContent();
    const numBefore = parseInt(countBefore!.match(/\d+/)![0]);

    // Delete the note
    const noteRow = page.getByText('Заметка для удаления').locator('..');
    await noteRow.getByRole('button', { name: 'Delete' }).click();

    // Verify note removed and counter decremented
    await expect(page.getByText('Заметка для удаления')).not.toBeVisible();
    await expect(page.getByText(`Всего заметок: ${numBefore - 1}`)).toBeVisible();
  });

  test('SC-008: Search and filter notes', async ({ page }) => {
    await page.goto('/notes');

    // Add three notes
    for (const text of ['Купить молоко', 'Купить хлеб', 'Позвонить маме']) {
      await page.getByPlaceholder('Enter a note').fill(text);
      await page.getByRole('button', { name: 'Add' }).click();
      await expect(page.getByText(text)).toBeVisible();
    }

    await expect(page.getByText('Всего заметок: 3')).toBeVisible();

    // Search
    await page.getByPlaceholder('Поиск заметок...').fill('Купить');

    // Verify filtered results
    await expect(page.getByText('Купить молоко')).toBeVisible();
    await expect(page.getByText('Купить хлеб')).toBeVisible();
    await expect(page.getByText('Позвонить маме')).not.toBeVisible();
    await expect(page.getByText('Найдено: 2 из 3')).toBeVisible();

    // Clear search
    await page.getByRole('button', { name: '×' }).click();

    // Verify all notes visible again
    await expect(page.getByText('Купить молоко')).toBeVisible();
    await expect(page.getByText('Купить хлеб')).toBeVisible();
    await expect(page.getByText('Позвонить маме')).toBeVisible();
    await expect(page.getByText('Всего заметок: 3')).toBeVisible();
  });
});
