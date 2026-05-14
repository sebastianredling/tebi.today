/**
 * Speed Insights initialization script
 * This file imports and initializes Vercel Speed Insights for the static site
 */
import { injectSpeedInsights } from '@vercel/speed-insights';

// Initialize Speed Insights
// This will automatically track Core Web Vitals and send them to Vercel
injectSpeedInsights({
  debug: false, // Set to true during development if you want to see debug logs
  sampleRate: 1.0, // Track 100% of page views
});
