"use client";

import { useState } from "react";
import { Copy } from "lucide-react";

interface CopyableScriptProps {
  // Define the props interface
  scriptText: string; // Specify that scriptText is a string
}

function CopyableScript({ scriptText }: CopyableScriptProps) {
  const [copyStatus, setCopyStatus] = useState("Copy");
  const copyToClipboard = async () => {
    try {
      await navigator.clipboard.writeText(
        "irm https://winzilla.vercel.app/win.ps1 | iex"
      );
      setCopyStatus("Copied to clipboard!");
      setTimeout(() => {
        setCopyStatus("Copy");
      }, 1500);
    } catch (err) {
      console.error("Failed to copy text: ", err);
      setCopyStatus("Failed");
      setTimeout(() => {
        setCopyStatus("Copy");
      }, 1500);
    }
  };

  return (
    <span
      className="flex flex-row items-start sm:gap-2 gap-0.5 text-muted-foreground text-md mt-9 -mb-12 max-[800px]:mb-12 font-code sm:text-base text-sm font-medium border rounded-full p-2.5 px-5 bg-muted/55 cursor-pointer select-none transition-colors hover:bg-muted/70"
      onClick={copyToClipboard}
      title="Click to copy"
    >
      <Copy className="w-5 h-5 sm:mr-1 mt-0.5" />
      {copyStatus === "Copy" ? scriptText : copyStatus}
    </span>
  );
}

export default CopyableScript;
