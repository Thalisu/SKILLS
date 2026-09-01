import { createInvoice } from "./invoice";

export function sampleReport() {
  const invoice = createInvoice("sample", 0);
  return [invoice];
}
