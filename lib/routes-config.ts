// for page navigation & to sort on leftbar

export type EachRoute = {
  title: string;
  href: string;
  noLink?: true; // noLink will create a route segment (section) but cannot be navigated
  items?: EachRoute[];
  tag?: string;
};

export const ROUTES: EachRoute[] = [
  {
    title: "Getting Started",
    href: "/getting-started",
    noLink: true,
    items: [
      { title: "Introduction", href: "/introduction" },
    ],
  },
  {
    title: "",
    href: "",
    noLink: true,
  },
  {
    title: "",
    href: "",
    noLink: true,
  },
  {
    title: "App Guides",
    href: "/app-guides",
    tag: "Essential",
    noLink: true,
    items: [
      { title: "Introduction", 
        href: "/introduction" 
      },
      { title: "Using Ninite", 
        href: "/ninite" 
      },
      { title: "Using WinGet", 
        href: "/winget" 
      },
      {
        title: "Apps",
        href: "/apps",
        items: [
          { title: "Discord", href: "/discord" },
          { title: "Youtube Music", href: "/youtubeMusic" },
          { title: "Hydra Launcher", href: "/hydraLauncher" },
          { title: "Spotify", href: "/spotify" },
        ],
      },
    ],
  },
];

type Page = { title: string; href: string };

function getRecurrsiveAllLinks(node: EachRoute) {
  const ans: Page[] = [];
  if (!node.noLink) {
    ans.push({ title: node.title, href: node.href });
  }
  node.items?.forEach((subNode) => {
    const temp = { ...subNode, href: `${node.href}${subNode.href}` };
    ans.push(...getRecurrsiveAllLinks(temp));
  });
  return ans;
}

export const page_routes = ROUTES.map((it) => getRecurrsiveAllLinks(it)).flat();
