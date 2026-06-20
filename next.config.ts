import type { NextConfig } from "next";

// When FORCE_STATIC_EXPORT=true (set in CI), produce a static HTML export
// suitable for GitHub Pages, Netlify, or any static host.
// Otherwise use "standalone" for self-hosted server deployment.
const isStaticExport = process.env.FORCE_STATIC_EXPORT === "true";

// When deploying to GitHub Pages under /<repo>/, set this to "/glucotrack".
// For Vercel / custom domain / root deployment, leave empty.
const basePath = process.env.GH_PAGES_BASE_PATH || "";

const nextConfig: NextConfig = {
  output: isStaticExport ? "export" : "standalone",
  trailingSlash: isStaticExport,
  images: { unoptimized: isStaticExport },
  // basePath + assetPrefix must BOTH be set for Pages subpath deployment
  ...(basePath ? { basePath, assetPrefix: basePath } : {}),
  typescript: {
    ignoreBuildErrors: true,
  },
  reactStrictMode: false,
};

export default nextConfig;
