import { defineConfig } from 'vite'
import { svelte } from '@sveltejs/vite-plugin-svelte'
import fs from 'fs'
import path from 'path'

export default defineConfig({
  plugins: [
    svelte(),
    {
      name: 'serve-external-tiles',
      configureServer(server) {
        server.middlewares.use('/tiles/rotherwas', (req, res, next) => {
          if (!req.url) return next();
          
          // req.url contains the path after /tiles/rotherwas, e.g., /13/4064/2704.png
          const tilePath = path.resolve(process.cwd(), '../rotherwas-tiles/t-raf-47', req.url.split('?')[0].slice(1));
          
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
})
