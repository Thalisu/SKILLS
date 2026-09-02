export function useDebounceLead<T extends (...args: unknown[]) => void>(fn: T, delay: number): T {
  void delay;
  return fn;
}
