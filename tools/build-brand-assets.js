/* Build the small UI mask from the supplied, unchanged Scooby PNG. */
const fs = require('fs'), path = require('path');
const root = path.resolve(__dirname, '..');
function buildBrandMask() {
  const png = fs.readFileSync(path.join(root, 'assets/images/brand/scooby-logo.png'));
  if (png.readUInt32BE(16) !== 1254 || png.readUInt32BE(20) !== 1254) {
    throw new Error('The Scooby source dimensions changed; review the mark viewBox before rebuilding.');
  }
  // Alpha conversion removes the black canvas. A small native-resolution dilation
  // preserves the thin outline when the mark is shown in a 29–43px UI slot.
  const svg = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="200 100 740 980"><defs><filter id="outline" x="0" y="0" width="100%" height="100%" color-interpolation-filters="sRGB"><feColorMatrix type="luminanceToAlpha"/><feMorphology operator="dilate" radius="5"/></filter></defs><image width="1254" height="1254" href="data:image/png;base64,' + png.toString('base64') + '" filter="url(#outline)"/></svg>\n';
  fs.writeFileSync(path.join(root, 'assets/images/brand/scooby-mark.svg'), svg);
}
if (require.main === module) { buildBrandMask(); console.log('Built the Scooby UI mask from the original PNG.'); }
module.exports = { buildBrandMask };
