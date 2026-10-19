import fs from "node:fs";
import path from "node:path";
import * as tus from "tus-js-client";

const filePath = process.argv[2];
const baseUrl = process.argv[3] ?? "http://127.0.0.1:5173";
if (!filePath) throw new Error("Informe o caminho do relatório.");
const bytes = fs.readFileSync(filePath);
const name = path.basename(filePath);

const startResponse = await fetch(`${baseUrl}/api/importacoes/iniciar`, {
  method: "POST", headers: { "content-type": "application/json" },
  body: JSON.stringify({ name, size: bytes.byteLength, type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" })
});
const start = await startResponse.json();
if (!startResponse.ok) throw new Error(start.error ?? "Falha ao iniciar teste");

await new Promise((resolve, reject) => {
  const upload = new tus.Upload(bytes, {
    endpoint: `${start.endpoint}/storage/v1/upload/resumable`, uploadSize: bytes.byteLength,
    retryDelays: [0, 1000, 3000], chunkSize: 6 * 1024 * 1024,
    headers: { authorization: `Bearer ${start.apiKey}`, apikey: start.apiKey, "x-signature": start.token },
    metadata: { bucketName: "importacoes", objectName: start.path, contentType: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", cacheControl: "3600" },
    onError: reject, onSuccess: resolve
  });
  upload.start();
});

const confirmResponse = await fetch(`${baseUrl}/api/importacoes/confirmar`, { method: "POST", headers: { "content-type": "application/json" }, body: JSON.stringify({ id: start.id }) });
if (!confirmResponse.ok) throw new Error((await confirmResponse.json()).error ?? "Falha ao confirmar teste");

let result;
for (let attempt = 0; attempt < 120; attempt++) {
  const response = await fetch(`${baseUrl}/api/importacoes/status?id=${start.id}`);
  result = await response.json();
  if (["concluida", "duplicada", "falhou"].includes(result.status)) break;
  await new Promise((resolve) => setTimeout(resolve, 1000));
}
if (result?.status === "duplicada") {
  throw new Error("A amostra já existe na base. Use uma base limpa ou um arquivo inédito para validar Bronze, Silver e Parquet.");
}
if (result?.status !== "concluida") throw new Error(result?.mensagem_erro ?? "Tempo limite excedido");
if (result.total_linhas !== 88 || result.total_colunas !== 87 || result.colunas_mapeadas !== 87) throw new Error(`Resultado inesperado: ${JSON.stringify(result)}`);

console.log(JSON.stringify({ status: result.status, id: result.id, linhas: result.total_linhas, colunas: result.total_colunas, mapeadas: result.colunas_mapeadas, validas: result.linhas_validas, erros: result.linhas_erro, duplicadas: result.linhas_duplicadas, parquet: result.storage_parquet_path }, null, 2));
