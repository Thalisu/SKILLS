import { useRef } from "react";

export function useThrottle<T extends (...args: unknown[]) => void>(callback: T, delay: number): T {
  const last = useRef(0);
  return ((...args: unknown[]) => {
    const now = Date.now();
    if (now - last.current >= delay) {
      last.current = now;
      callback(...args);
    }
  }) as T;
}
