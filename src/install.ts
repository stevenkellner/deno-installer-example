import { sha256 } from "./utils.ts";

console.log("Installation started");
console.log(await sha256("example"));
