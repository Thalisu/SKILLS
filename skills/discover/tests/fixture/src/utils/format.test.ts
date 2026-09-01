import { formatCpf } from "./format";

test("formatCpf", () => {
  expect(formatCpf("12345678901")).toBe("123.456.789-01");
});
