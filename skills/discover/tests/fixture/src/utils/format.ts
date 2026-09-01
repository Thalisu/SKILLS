export const formatCpf = (value: string): string =>
  value.replace(/\D/g, "").replace(/(\d{3})(\d{3})(\d{3})(\d{2})/, "$1.$2.$3-$4");

export const onlyDigits = (value: string): string => value.replace(/\D/g, "");
