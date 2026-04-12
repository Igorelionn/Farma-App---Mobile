-- ============================================================
-- Migration: Tornar bucket 'documents' privado e configurar
--            políticas de acesso seguro via RLS de storage.
-- ============================================================

-- 1. Tornar o bucket 'documents' privado (não público)
--    Se o bucket não existir, cria. Se existir, atualiza.
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'documents',
  'documents',
  false,           -- privado: sem acesso público por URL direta
  10485760,        -- 10 MB por arquivo
  ARRAY['application/pdf', 'image/jpeg', 'image/png']
)
ON CONFLICT (id) DO UPDATE SET
  public             = false,
  file_size_limit    = 10485760,
  allowed_mime_types = ARRAY['application/pdf', 'image/jpeg', 'image/png'];

-- ============================================================
-- 2. Políticas de storage para o bucket 'documents'
-- ============================================================

-- Remove políticas antigas se existirem (idempotente)
DROP POLICY IF EXISTS "Usuário envia seus próprios documentos"   ON storage.objects;
DROP POLICY IF EXISTS "Usuário lê seus próprios documentos"      ON storage.objects;
DROP POLICY IF EXISTS "Admin lê todos os documentos"             ON storage.objects;
DROP POLICY IF EXISTS "Admin deleta documentos"                  ON storage.objects;

-- 2a. Upload: usuário autenticado só pode fazer upload na própria pasta (userId/...)
CREATE POLICY "Usuário envia seus próprios documentos"
  ON storage.objects
  FOR INSERT
  TO authenticated
  WITH CHECK (
    bucket_id = 'documents'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

-- 2b. Download/leitura: o próprio usuário lê seus documentos
CREATE POLICY "Usuário lê seus próprios documentos"
  ON storage.objects
  FOR SELECT
  TO authenticated
  USING (
    bucket_id = 'documents'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

-- 2c. Download/leitura: administradores leem todos os documentos
CREATE POLICY "Admin lê todos os documentos"
  ON storage.objects
  FOR SELECT
  TO authenticated
  USING (
    bucket_id = 'documents'
    AND EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid()
        AND role = 'admin'
    )
  );

-- 2d. Delete: administradores podem remover documentos
CREATE POLICY "Admin deleta documentos"
  ON storage.objects
  FOR DELETE
  TO authenticated
  USING (
    bucket_id = 'documents'
    AND EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid()
        AND role = 'admin'
    )
  );

-- 2e. Update (upsert): usuário só pode substituir seus próprios arquivos
CREATE POLICY "Usuário atualiza seus próprios documentos"
  ON storage.objects
  FOR UPDATE
  TO authenticated
  USING (
    bucket_id = 'documents'
    AND (storage.foldername(name))[1] = auth.uid()::text
  )
  WITH CHECK (
    bucket_id = 'documents'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );
