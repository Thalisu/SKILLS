import { Badge } from "./Badge";

export function Card({ title, tag }: { title: string; tag: string }) {
  return (
    <div>
      <h2>{title}</h2>
      <Badge label={tag} />
      <Badge label="new" />
    </div>
  );
}
