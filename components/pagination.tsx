import { getPreviousNext } from "@/lib/markdown";

export default function Pagination({ pathname }: { pathname: string }) {
  const res = getPreviousNext(pathname);

  return (
    <div className="sm:py-10 py-7">
      <hr />
    </div>
  );
}
