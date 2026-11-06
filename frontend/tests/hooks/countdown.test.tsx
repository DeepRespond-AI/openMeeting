import { afterEach, describe, expect, setSystemTime, test } from 'bun:test';
import { act, create, type ReactTestRenderer } from 'react-test-renderer';
import { secondsLeft, useCountdown } from '../../src/hooks/useCountdown';

type Countdown = ReturnType<typeof useCountdown>;

describe('secondsLeft', () => {
  test('rounds up and never goes negative', () => {
    expect(secondsLeft(null, 0)).toBe(0);
    expect(secondsLeft(60_000, 0)).toBe(60);
    expect(secondsLeft(60_000, 100)).toBe(60);
    expect(secondsLeft(60_000, 59_001)).toBe(1);
    expect(secondsLeft(60_000, 60_000)).toBe(0);
    expect(secondsLeft(60_000, 90_000)).toBe(0);
  });
});

describe('useCountdown', () => {
  let renderer: ReactTestRenderer | undefined;
  afterEach(() => {
    act(() => renderer?.unmount());
    renderer = undefined;
    setSystemTime();
  });

  test('counts down from start() and stops at zero', async () => {
    let latest: Countdown | undefined;
    function Probe() {
      latest = useCountdown(10);
      return null;
    }
    const t0 = new Date('2026-10-07T00:00:00Z').getTime();
    setSystemTime(new Date(t0));
    act(() => {
      renderer = create(<Probe />);
    });
    expect(latest!.running).toBe(false);
    expect(latest!.remaining).toBe(0);

    act(() => latest!.start(60));
    expect(latest!.running).toBe(true);
    expect(latest!.remaining).toBe(60);

    setSystemTime(new Date(t0 + 30_500));
    await act(async () => {
      await new Promise((resolve) => setTimeout(resolve, 30));
    });
    expect(latest!.remaining).toBe(30);

    setSystemTime(new Date(t0 + 61_000));
    await act(async () => {
      await new Promise((resolve) => setTimeout(resolve, 30));
    });
    expect(latest!.remaining).toBe(0);
    expect(latest!.running).toBe(false);
  });

  test('reset() and non-positive durations stop the countdown', () => {
    let latest: Countdown | undefined;
    function Probe() {
      latest = useCountdown(10);
      return null;
    }
    act(() => {
      renderer = create(<Probe />);
    });
    act(() => latest!.start(10));
    expect(latest!.running).toBe(true);
    act(() => latest!.reset());
    expect(latest!.running).toBe(false);
    act(() => latest!.start(0));
    expect(latest!.running).toBe(false);
  });
});
