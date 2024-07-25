
const { AbiCoder, keccak256, toUtf8Bytes } = ethers;

export function hashData(dataTypes, dataValues) {
  const bytes = AbiCoder.defaultAbiCoder().encode(dataTypes, dataValues);
  const hash = keccak256(bytes);

  return hash;
}

export function hashString(string) {
  return hashData(["string"], [string]);
}

export function keccakString(string) {
  return keccak256(toUtf8Bytes(string));
}
