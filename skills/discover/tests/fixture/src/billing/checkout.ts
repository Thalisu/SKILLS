import { createInvoice } from "./invoice";

export function checkout(customerId: string, total: number) {
  return createInvoice(customerId, total);
}
