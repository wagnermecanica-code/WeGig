import fs from 'node:fs/promises';
import path from 'node:path';

const routePaths = [
  'access-denied',
  'analytics',
  'audit',
  'catalog',
  'comments',
  'crashlytics',
  'dashboard',
  'feedbacks',
  'feed-admin',
  'heatmap',
  'login',
  'moderation/reports',
  'posts',
  'reputation',
  'settings',
  'users',
];

async function main() {
  const outDirArg = process.argv[2];
  const outDir = path.resolve(outDirArg ?? 'dist');
  const indexPath = path.join(outDir, 'index.html');
  const indexHtml = await fs.readFile(indexPath, 'utf8');

  await Promise.all(
    routePaths.map(async (routePath) => {
      const routeDir = path.join(outDir, ...routePath.split('/'));
      await fs.mkdir(routeDir, { recursive: true });
      await fs.writeFile(path.join(routeDir, 'index.html'), indexHtml);
    }),
  );
}

main().catch((error) => {
  console.error('[create-route-stubs] failed:', error);
  process.exitCode = 1;
});