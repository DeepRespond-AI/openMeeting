import { expect, mock, test } from 'bun:test';

const invoke = mock(async (): Promise<boolean> => false);
mock.module('@tauri-apps/api/core', () => ({ invoke }));
const { default: Analytics } = await import('../../src/lib/analytics');

test('unconfigured builds and unavailable native bridges keep analytics unavailable', async () => {
  invoke.mockResolvedValue(false);
  expect(await Analytics.isConfigured()).toBe(false);
  invoke.mockRejectedValue(new Error('native bridge unavailable'));
  expect(await Analytics.isConfigured()).toBe(false);
});

test('availability comes from the native build rather than stored user consent', async () => {
  invoke.mockResolvedValue(true);
  expect(await Analytics.isConfigured()).toBe(true);
  expect(invoke).toHaveBeenLastCalledWith('is_analytics_configured');
});
