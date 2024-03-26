// import { ethers } from "ethers";
const { AbiCoder, keccak256, toUtf8Bytes, arrayify } = ethers;
// const { hexlify } = ethers.utils;

// export function encodeData(dataTypes, dataValues) {
//   const bytes = AbiCoder.defaultAbiCoder().encode(dataTypes, dataValues);
//   return hexlify(bytes);
// }

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
