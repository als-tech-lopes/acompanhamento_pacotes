import * as tus from "tus-js-client";

export function uploadResumable(file: File, options: { endpoint: string; path: string; token: string; apiKey: string; onProgress: (value: number) => void }) {
  return new Promise<void>((resolve, reject) => {
    const upload = new tus.Upload(file, {
      endpoint: `${options.endpoint.replace(/\/$/, "")}/storage/v1/upload/resumable`,
      retryDelays: [0, 1000, 3000, 5000, 10000],
      headers: { authorization: `Bearer ${options.apiKey}`, apikey: options.apiKey, "x-signature": options.token },
      uploadDataDuringCreation: true,
      removeFingerprintOnSuccess: true,
      chunkSize: 6 * 1024 * 1024,
      metadata: { bucketName: "importacoes", objectName: options.path, contentType: file.type || "application/octet-stream", cacheControl: "3600" },
      onError: reject,
      onProgress: (uploaded, total) => options.onProgress(total ? Math.round((uploaded / total) * 100) : 0),
      onSuccess: () => resolve(),
    });
    upload.findPreviousUploads().then((previous) => { if (previous[0]) upload.resumeFromPreviousUpload(previous[0]); upload.start(); }).catch(reject);
  });
}
