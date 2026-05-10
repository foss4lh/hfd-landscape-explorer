import { defineConfig } from 'vite'
import { svelte } from '@sveltejs/vite-plugin-svelte'
import fs from 'fs'
import path from 'path'

export default defineConfig({
  base: '/hfd-landscape-explorer/',
  resolve: {
    alias: {
      '@': path.resolve(__dirname),
    },
  },
  plugins: [
    svelte(),
    {
      name: 'serve-tiles-from-public',
      configureServer(server) {
        server.middlewares.use('/tiles/rotherwas', (req, res, next) => {
          if (!req.url) return next();
          const tilePath = path.resolve(__dirname, 'public/tiles/rotherwas', req.url.split('?')[0].slice(1));
          if (fs.existsSync(tilePath) && fs.statSync(tilePath).isFile()) {
            res.setHeader('Content-Type', 'image/png');
            res.setHeader('Cache-Control', 'public, max-age=31536000');
            fs.createReadStream(tilePath).pipe(res);
          } else {
            res.statusCode = 404;
            res.end('Not Found');
          }
        });
      }
    }
  ],
  build: {
    rollupOptions: {
      input: {
        main: path.resolve(__dirname, 'index.html'),
        docs: path.resolve(__dirname, 'docs.html'),
      },
    },
  },
})