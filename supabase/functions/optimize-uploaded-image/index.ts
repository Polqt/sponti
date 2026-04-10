import { createClient } from 'jsr:@supabase/supabase-js@2';
import { Image } from 'https://deno.land/x/imagescript@1.3.0/mod.ts';

type OptimizeRequest = {
  bucket?: string;
  path?: string;
};

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

function jsonResponse(status: number, body: Record<string, unknown>) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...corsHeaders,
      'Content-Type': 'application/json',
    },
  });
}

function buildOptimizedPath(path: string): string {
  const slashIndex = path.lastIndexOf('/');
  const dotIndex = path.lastIndexOf('.');
  const hasExtension = dotIndex > slashIndex;
  const base = hasExtension ? path.substring(0, dotIndex) : path;
  return `${base}.jpg`;
}

async function optimizeToJpeg(bytes: Uint8Array): Promise<Uint8Array> {
  const decoded = await Image.decode(bytes);
  const maxWidth = 1200;
  if (decoded.width > maxWidth) {
    decoded.resize(maxWidth, Image.RESIZE_AUTO);
  }
  return await decoded.encodeJPEG(85);
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL');
    const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');

    if (!supabaseUrl || !serviceRoleKey) {
      return jsonResponse(500, {
        error: 'Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY.',
      });
    }

    const payload = (await req.json()) as OptimizeRequest;
    const bucket = payload.bucket?.trim();
    const objectPath = payload.path?.trim();

    if (!bucket || !objectPath) {
      return jsonResponse(400, {
        error: 'Both "bucket" and "path" are required.',
      });
    }

    const supabase = createClient(supabaseUrl, serviceRoleKey);
    const download = await supabase.storage.from(bucket).download(objectPath);
    if (download.error != null || download.data == null) {
      return jsonResponse(400, {
        error: `Failed to download source image for path "${objectPath}".`,
      });
    }

    const sourceBytes = new Uint8Array(await download.data.arrayBuffer());
    const optimizedBytes = await optimizeToJpeg(sourceBytes);
    const optimizedPath = buildOptimizedPath(objectPath);

    const upload = await supabase.storage
      .from(bucket)
      .upload(optimizedPath, optimizedBytes, {
        contentType: 'image/jpeg',
        upsert: true,
      });

    if (upload.error != null) {
      return jsonResponse(500, {
        error: `Failed to upload optimized image to "${optimizedPath}".`,
      });
    }

    if (optimizedPath !== objectPath) {
      await supabase.storage.from(bucket).remove([objectPath]);
    }

    return jsonResponse(200, {
      optimized_path: optimizedPath,
    });
  } catch (error) {
    return jsonResponse(500, {
      error: error instanceof Error ? error.message : 'Unexpected optimization error.',
    });
  }
});
