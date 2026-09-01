import { memo } from "react";

type BadgeProps = { label: string };

export const Badge = memo(function BadgeInner({ label }: BadgeProps) {
  return <span className="badge">{label}</span>;
});
