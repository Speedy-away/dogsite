/* Generate responsive display copies; original src/href URLs remain full size. */
const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const sharp = require('sharp');
const root = path.resolve(__dirname, '..');
const outputDirectory = path.join(root, 'assets/images/display');
const manifestPath = path.join(root, 'assets/data/product-display-images.json');
const widths = [320, 640, 960, 1440];
const minimumBytes = 80 * 1024;
const gallerySizes = '(max-width: 980px) calc(100vw - 40px), (max-width: 1240px) 66vw, 740px';
const tf2Sizes = '(max-width: 760px) calc(100vw - 64px), (max-width: 1080px) 60vw, 640px';
const cardSizes = '(max-width: 600px) calc(100vw - 40px), 480px';
const hash = bytes => crypto.createHash('sha256').update(bytes).digest('hex');
const get = (tag, key) => tag.match(new RegExp('(?:^|\\s)' + key + '\\s*=\\s*(["\'])(.*?)\\1', 'i'))?.[2];
function set(tag, key, value) {
    const pattern = new RegExp('\\s' + key + '\\s*=\\s*(["\'])(.*?)\\1', 'i');
    return pattern.test(tag) ? tag.replace(pattern, ` ${key}="${value}"`) : tag.replace(/\s*\/?>$/, ` ${key}="${value}">`);
}
function pagePaths() {
    const pages = ['index.html'];
    for (const folder of ['products', 'store', 'source-games', 'more-games', 'rockstar-classics']) {
        const direct = path.join(folder, 'index.html');
        if (fs.existsSync(path.join(root, direct))) pages.push(direct);
        if (folder === 'products') for (const entry of fs.readdirSync(path.join(root, folder), { withFileTypes: true })) {
            const file = path.join(folder, entry.name, 'index.html');
            if (entry.isDirectory() && fs.existsSync(path.join(root, file))) pages.push(file);
        }
    }
    return [...new Set(pages)].sort();
}
function isBackdrop(markup, position) {
    const start = markup.lastIndexOf('<picture', position);
    return start > markup.lastIndexOf('</picture', position) && /product-backdrop/.test(markup.slice(start, markup.indexOf('>', start)));
}
function candidates(markup) {
    return [...markup.matchAll(/<img\b[^>]*>/gi)].filter(match => {
        const src = get(match[0], 'src');
        return src?.startsWith('/assets/images/') && /\.(png|jpe?g|webp)$/i.test(src) && !isBackdrop(markup, match.index);
    });
}
async function build() {
    fs.mkdirSync(outputDirectory, { recursive: true });
    const previous = fs.existsSync(manifestPath) ? JSON.parse(fs.readFileSync(manifestPath, 'utf8')).images : {};
    const pages = pagePaths();
    const images = {};
    for (const page of pages) {
        const markup = fs.readFileSync(path.join(root, page), 'utf8');
        for (const match of candidates(markup)) {
            const tag = match[0], src = get(tag, 'src');
            if (images[src] || (get(tag, 'srcset') && !get(tag, 'srcset').includes('/assets/images/display/'))) continue;
            const original = path.join(root, src.slice(1));
            if (!fs.existsSync(original) || fs.statSync(original).size < minimumBytes) continue;
            const bytes = fs.readFileSync(original);
            const metadata = await sharp(bytes).metadata();
            if (!metadata.width || !metadata.height || metadata.pages > 1) continue;
            const quality = src.includes('/previews/') ? 86 : 82;
            const sourceHash = hash(bytes);
            const identity = hash(Buffer.concat([bytes, Buffer.from(`webp-${quality}-v1`)])).slice(0, 12);
            const stem = path.basename(src, path.extname(src)).slice(0, 65);
            const variants = [];
            for (const width of [...new Set(widths.map(value => Math.min(value, metadata.width)))]) {
                const name = `${stem}-${identity}-${width}.webp`;
                const destination = path.join(outputDirectory, name);
                if (!fs.existsSync(destination)) {
                    await sharp(bytes).resize({ width, withoutEnlargement: true }).webp({ quality, effort: 6, smartSubsample: true }).toFile(destination);
                }
                const info = await sharp(destination).metadata();
                variants.push({ src: '/assets/images/display/' + name, width: info.width, height: info.height, bytes: fs.statSync(destination).size });
            }
            images[src] = { width: metadata.width, height: metadata.height, bytes: bytes.length, sha256: sourceHash, variants };
        }
    }
    let changed = 0;
    for (const page of pages) {
        const file = path.join(root, page), markup = fs.readFileSync(file, 'utf8');
        let firstPreview = true;
        let updated = markup.replace(/<img\b[^>]*>/gi, (tag, position) => {
            const src = get(tag, 'src');
            if (!src || isBackdrop(markup, position)) return tag;
            const preview = src.includes('/previews/');
            if (preview) {
                tag = set(tag, 'loading', firstPreview ? 'eager' : 'lazy');
                if (firstPreview) tag = set(tag, 'fetchpriority', 'high');
                else if (get(tag, 'fetchpriority') === 'high') tag = set(tag, 'fetchpriority', 'auto');
                tag = set(tag, 'decoding', 'async');
                firstPreview = false;
            }
            const image = images[src];
            if (!image) return tag;
            tag = set(tag, 'srcset', image.variants.map(variant => `${variant.src} ${variant.width}w`).join(', '));
            const isProduct = page.startsWith('products' + path.sep) && !page.includes(path.sep + 'free' + path.sep);
            const sizes = page.includes(path.sep + 'tf2' + path.sep) ? tf2Sizes
                : isProduct ? gallerySizes
                : get(tag, 'fetchpriority') === 'high' ? '(max-width: 1280px) calc(100vw - 40px), 1240px'
                : cardSizes;
            tag = set(tag, 'sizes', sizes);
            if (!get(tag, 'width')) tag = set(tag, 'width', image.width);
            if (!get(tag, 'height')) tag = set(tag, 'height', image.height);
            tag = set(tag, 'decoding', 'async');
            if (get(tag, 'fetchpriority') === 'high') tag = set(tag, 'loading', 'eager');
            else if (!get(tag, 'loading')) tag = set(tag, 'loading', 'lazy');
            return tag;
        });
        // Some artwork is also used as a blurred backdrop. Avoid fetching its
        // large original a second time through an inline CSS custom property.
        const backdrop = image => {
            const standard = image.variants.find(variant => variant.width >= Math.min(960, image.width));
            return `image-set(url('${standard.src}') 1x, url('${image.variants.at(-1).src}') 2x)`;
        };
        for (const [src, image] of Object.entries(images)) {
            const background = backdrop(image);
            for (const value of [`url('${src}')`, `url("${src}")`, `url(${src})`]) updated = updated.replaceAll(value, background);
            if (previous[src]) updated = updated.replaceAll(backdrop(previous[src]), background);
        }
        if (updated !== markup) { fs.writeFileSync(file, updated); changed++; }
    }
    fs.writeFileSync(manifestPath, JSON.stringify({ version: 1, pages: pages.map(page => page.split(path.sep).join('/')), images }, null, 2) + '\n');
    const total = Object.values(images).reduce((sum, image) => sum + image.bytes, 0);
    const display = Object.values(images).reduce((sum, image) => sum + image.variants.find(variant => variant.width >= Math.min(960, image.width)).bytes, 0);
    console.log(`Updated ${changed} pages; ${Object.keys(images).length} responsive images. Originals ${(total / 1048576).toFixed(1)} MiB; 960px copies ${(display / 1048576).toFixed(1)} MiB (${Math.round((1 - display / total) * 100)}% smaller).`);
}
function check() {
    const manifest = JSON.parse(fs.readFileSync(manifestPath, 'utf8'));
    for (const [src, image] of Object.entries(manifest.images)) {
        if (hash(fs.readFileSync(path.join(root, src.slice(1)))) !== image.sha256) throw Error(`Changed original; rebuild display images: ${src}`);
        for (const variant of image.variants) {
            const file = path.join(root, variant.src.slice(1));
            if (!fs.existsSync(file) || fs.statSync(file).size !== variant.bytes) throw Error(`Missing or stale display image: ${variant.src}`);
        }
    }
    for (const page of manifest.pages) {
        const markup = fs.readFileSync(path.join(root, page), 'utf8');
        for (const match of candidates(markup)) {
            const src = get(match[0], 'src'), image = manifest.images[src];
            if (image && get(match[0], 'srcset') !== image.variants.map(variant => `${variant.src} ${variant.width}w`).join(', ')) throw Error(`Missing responsive variants: ${page}: ${src}`);
        }
    }
    console.log(`PASS: ${Object.keys(manifest.images).length} original images and all responsive variants are current.`);
}
if (require.main === module) {
    if (process.argv[2] === '--apply') build().catch(error => { console.error(error); process.exitCode = 1; });
    else if (process.argv[2] === '--check') { try { check(); } catch (error) { console.error(error); process.exitCode = 1; } }
    else { console.error('Use --apply to generate/update display images, or --check to validate them.'); process.exitCode = 1; }
}
module.exports = { build, check };
