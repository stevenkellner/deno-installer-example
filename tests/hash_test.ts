import { assertEquals } from "@std/assert";
import { sha256 } from "../src/utils.ts";

Deno.test("sha256", async () => {
  assertEquals(
    await sha256("abc"),
    "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad",
  );
});
