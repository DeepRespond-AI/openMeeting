import { describe, expect, test } from 'bun:test';
import {
  avatarInitial,
  isValidPhone,
  maskPhone,
  normalizePhone,
  sanitizeCodeInput,
  sanitizePhoneInput,
} from '../../src/lib/phone';

describe('phone helpers', () => {
  test('normalizes valid mainland mobile numbers', () => {
    expect(normalizePhone('13800138000')).toBe('13800138000');
    expect(normalizePhone('+86 138-0013-8000')).toBe('13800138000');
    expect(normalizePhone('8613800138000')).toBe('13800138000');
    expect(normalizePhone(' 199 0000 0000 ')).toBe('19900000000');
  });

  test('rejects invalid numbers', () => {
    for (const bad of ['', '1380013800', '138001380001', '12800138000', '23800138000', '1380013800a', '+8512800138000']) {
      expect(isValidPhone(bad)).toBe(false);
    }
  });

  test('sanitizes typed or pasted input', () => {
    expect(sanitizePhoneInput('+86 138 0013 8000')).toBe('13800138000');
    expect(sanitizePhoneInput('8613800138000')).toBe('13800138000');
    expect(sanitizePhoneInput('138abc0013')).toBe('1380013');
    expect(sanitizePhoneInput('1380013800099')).toBe('13800138000');
    expect(sanitizeCodeInput(' 12a3456789')).toBe('123456');
    expect(sanitizeCodeInput('1234', 4)).toBe('1234');
  });

  test('masks phone numbers and builds avatar initials', () => {
    expect(maskPhone('13800138000')).toBe('138****8000');
    expect(maskPhone('+8613800138000')).toBe('138****8000');
    expect(maskPhone('n/a')).toBe('n/a');
    expect(maskPhone(null)).toBe('');
    expect(avatarInitial('张三')).toBe('张');
    expect(avatarInitial(' alice ')).toBe('A');
    expect(avatarInitial('')).toBe('?');
  });
});
