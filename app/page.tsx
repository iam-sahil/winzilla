import { buttonVariants } from "@/components/ui/button";
import { page_routes } from "@/lib/routes-config";
import { MoveUpRightIcon } from "lucide-react";
import Link from "next/link";
import CopyableScript from "@/components/CopyableScript";

export default function Home() {
  return (
    <div className="flex sm:min-h-[85.5vh] min-h-[85vh] flex-col items-center justify-center text-center px-2 sm:py-8 py-12">
      <Link
        href="https://github.com/iam-sahil/winzilla"
        target="_blank"
        className="mb-5 sm:text-lg flex items-center gap-2 underline underline-offset-4 sm:-mt-12"
      >
        Follow along on GitHub{" "}
        <MoveUpRightIcon className="w-4 h-4 font-extrabold" />
      </Link>
      <h1 className="text-3xl font-bold mb-4 sm:text-6xl">
        A faster system is in your hands. Improve security. Have Control. More
        Performance.
      </h1>
      <p className="mb-8 sm:text-lg max-w-[800px] text-muted-foreground">
        Even a fresh windows install is ridiculed with inhouse spyware from
        Microsoft, not to mention the loads of background services bogging down
        your system.
      </p>
      <div className="flex flex-row items-center gap-5">
        <Link
          href={`/docs${page_routes[0].href}`}
          className={buttonVariants({ className: "px-6", size: "lg" })}
        >
          Get Stared
        </Link>
        <Link
          href={`/docs`}
          className={buttonVariants({
            variant: "secondary",
            className: "px-6",
            size: "lg",
          })}
        >
          App Guides
        </Link>
      </div>
      <CopyableScript scriptText={"irm winzilla.vercel.app/win | iex"} />
    </div>
  );
}
