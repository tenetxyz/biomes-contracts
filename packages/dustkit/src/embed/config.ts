import { type } from "arktype";

export const config = type({
  name: "string",
  startUrl: "string",
  "frame?": {
    width: "number",
    height: "number",
  },
});
export type Config = typeof config.infer;

export const configInput = type({
  name: "string",
  "startUrl?": "string",
  "frame?": {
    width: "number",
    height: "number",
  },
});
export type ConfigInput = typeof configInput.infer;

export async function getConfig({ url }: { url: string }): Promise<Config> {
  const config = await fetch(url)
    .then((res) => res.json())
    .then(configInput.assert);

  const configUrl = new URL(url);
  const startUrl = new URL(config.startUrl ?? ".", url);
  if (startUrl.origin !== configUrl.origin) {
    throw new Error(
      `Config \`startUrl\` origin ("${startUrl.origin}") did not match config origin ("${configUrl.origin}").`,
    );
  }

  return {
    ...config,
    startUrl: startUrl.toString(),
  };
}
