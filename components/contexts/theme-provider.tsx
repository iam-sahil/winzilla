"use client";

import * as React from "react";
import { ThemeProvider as NextThemesProvider } from "next-themes";

export function ThemeProvider({
  children,
  ...props
}: {
  children: React.ReactNode;
}) {
  return (
    <NextThemesProvider
      {...props}
      attribute="data-theme"
      defaultTheme="gruvbox-hard"
      enableSystem={false}
    >
      {children}
    </NextThemesProvider>
  );
}
