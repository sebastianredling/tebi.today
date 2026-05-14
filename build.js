import * as esbuild from 'esbuild';

// Build the Speed Insights script
await esbuild.build({
  entryPoints: ['speed-insights.js'],
  bundle: true,
  minify: true,
  format: 'iife',
  outfile: 'dist/speed-insights.min.js',
  platform: 'browser',
  target: ['es2020'],
}).catch(() => process.exit(1));

console.log('✓ Speed Insights bundle created at dist/speed-insights.min.js');
