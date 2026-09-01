import { formatCpf } from "../utils/format";

export function renderClient(document: string): string {
  const masked = formatCpf(document);
  return `CPF: ${formatCpf(masked)}`;
}
