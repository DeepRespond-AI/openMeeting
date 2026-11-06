import { describe, expect, test } from "bun:test";
import { passwordProblem } from "../../src/lib/password";

describe("passwordProblem", () => {
  test("mirrors the server rules", () => {
    expect(passwordProblem("Meeting2026")).toBeNull();
    expect(passwordProblem("short1")).toBe("length");
    expect(passwordProblem("a1".repeat(33))).toBe("length");
    expect(passwordProblem(" abc12345")).toBe("spaces");
    expect(passwordProblem("onlyletters")).toBe("letterDigit");
    expect(passwordProblem("12345678")).toBe("letterDigit");
  });

  test("uses the server-provided lengths", () => {
    expect(passwordProblem("abc123", { minLength: 6, maxLength: 10 })).toBeNull();
    expect(passwordProblem("abc12345678", { minLength: 6, maxLength: 10 })).toBe("length");
  });
});
