"use client";

import * as React from "react";
import { PaintbrushVertical } from "lucide-react";
import { useTheme } from "next-themes";

import { Button } from "@/components/ui/button";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";

export function ModeToggle() {
  const { setTheme } = useTheme();

  return (
    <DropdownMenu>
      <DropdownMenuTrigger asChild>
        <Button variant="ghost" size="icon">
          <PaintbrushVertical className="absolute h-[1.1rem] w-[1.1rem] rotate-90 scale-0 transition-all dark:rotate-0 dark:scale-100" />
          <span className="sr-only">Toggle theme</span>
        </Button>
      </DropdownMenuTrigger>
      <DropdownMenuContent align="end">
        <DropdownMenuItem onClick={() => setTheme("dark")}>
          Dark
        </DropdownMenuItem>
        <DropdownMenuItem onClick={() => setTheme("gruvbox-hard")}>
          Gruvbox Hard
        </DropdownMenuItem>
        <DropdownMenuItem onClick={() => setTheme("halloween")}>
          Halloween
        </DropdownMenuItem>
        <DropdownMenuItem onClick={() => setTheme("tokyo-night")}>
          Tokyo Night
        </DropdownMenuItem>
        <DropdownMenuItem onClick={() => setTheme("catppuccin")}>
          Catppuccin
        </DropdownMenuItem>
        <DropdownMenuItem onClick={() => setTheme("night-owl")}>
          Night Owl
        </DropdownMenuItem>
        <DropdownMenuItem onClick={() => setTheme("dracula")}>
          Dracula
        </DropdownMenuItem>
        <DropdownMenuItem onClick={() => setTheme("one-dark")}>
          One Dark
        </DropdownMenuItem>
        <DropdownMenuItem onClick={() => setTheme("monokai")}>
          Monokai
        </DropdownMenuItem>
      </DropdownMenuContent>
    </DropdownMenu>
  );
}
