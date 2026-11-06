import { createHash, createPublicKey, verify } from 'node:crypto';

export function verifyUpdaterSignature(payload, signature, publicKey) {
  try {
    const pub = Buffer.from(Buffer.from(publicKey.trim(), 'base64').toString('utf8').trim().split(/\r?\n/)[1], 'base64');
    const sig = Buffer.from(Buffer.from(signature.trim(), 'base64').toString('utf8').trim().split(/\r?\n/)[1], 'base64');
    if (pub.length !== 42 || sig.length !== 74 || !pub.subarray(2, 10).equals(sig.subarray(2, 10))) return false;
    const algorithm = sig.subarray(0, 2).toString();
    if (!['Ed', 'ED'].includes(algorithm)) return false;
    const key = createPublicKey({ key: Buffer.concat([Buffer.from('302a300506032b6570032100', 'hex'), pub.subarray(10)]), format: 'der', type: 'spki' });
    return verify(null, algorithm === 'ED' ? createHash('blake2b512').update(payload).digest() : payload, key, sig.subarray(10));
  } catch { return false; }
}
