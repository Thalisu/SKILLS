export type Invoice = { id: string; total: number };

export function createInvoice(customerId: string, total: number): Invoice {
  return { id: `${customerId}-${Date.now()}`, total };
}
