# Responsive product images

Keep original screenshots and artwork at their existing URLs. After adding or
updating product captures, run `node tools/optimize-product-images.cjs --apply`
(or `npm run images:build`) to regenerate the responsive WebP copies and page
attributes. The generator uses the pinned Sharp dev dependency. Commit the new
files in `assets/images/display/` and `assets/data/product-display-images.json`
along with the page changes. Full-size gallery links and `img.src` stay unchanged;
the browser chooses a smaller display file through `srcset` and `sizes`.

Run `node tools/optimize-product-images.cjs --check` and
`node tools/test-product-images.cjs` to verify generated files and desktop/mobile
gallery behavior. `PRODUCT_IMAGES_TEST_ORIGIN=https://scoobymenu.cc` targets the
published site for the browser check.

Display variants use content hashes so new captures receive fresh URLs. The
first preview is eager/high-priority; later previews use native lazy loading.
Width and height attributes preserve layout space during loading. Originals
remain available to the existing full-size gallery, and existing optimized
`srcset` definitions are preserved.
