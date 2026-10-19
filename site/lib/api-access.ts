const loopbackHosts = new Set(["127.0.0.1", "localhost", "::1"]);

function usesLocalSupabase() {
  try {
    const url = new URL(process.env.NEXT_PUBLIC_SUPABASE_URL ?? "");
    return loopbackHosts.has(url.hostname);
  } catch {
    return false;
  }
}

export function requireApiAccess(request: Request) {
  const localAdminEnabled = process.env.APP_ALLOW_LOCAL_ADMIN !== "false";
  if (localAdminEnabled && usesLocalSupabase()) return null;

  const userId = request.headers.get("oai-authenticated-user-id")?.trim();
  if (userId) return null;

  return Response.json(
    { error: "Autenticação necessária para acessar esta operação." },
    { status: 401 },
  );
}
