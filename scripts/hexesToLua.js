// Tiny script to convert a string of hexes into a lua string literal.
// Doesn't supply quotes, you'll have to bring your own.
// Currently just converts each command line argument into a separate line.

const octetsToLuaString = octs => octs.map(v => `${v}`).map(vs => `\\${'0'.repeat(3 - vs.length)}${vs}`).join('');
const hexStringToOctets = hs => {
  const octetsCount = Math.floor(hs.length / 2);
  const octets = []
  for (let i = 0; i < octetsCount; ++i) {
    const start = i * 2;
    const end = (i + 1) * 2;
    octets.push(parseInt(hs.substring(start, end), 16));
  }
  return octets;
}

process.argv.slice(2).forEach(s => {
  console.log(octetsToLuaString(hexStringToOctets(s)));
});
