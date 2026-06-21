-- ============================================================
--  منصة نُجوم — إعداد قاعدة بيانات Supabase
--  انسخ هذا الملف بالكامل والصقه في:
--  Supabase Dashboard → SQL Editor → New query → Run
-- ============================================================
-- ملاحظة: هذا الإعداد مخصّص لعائلة واحدة (الأبسط للانطلاق).
-- المصادقة تتم عبر كلمة سرّ موحّدة للوحة الإدارة على مستوى التطبيق،
-- والوصول للبيانات مفتوح للقراءة/الكتابة عبر مفتاح anon (مناسب للاستخدام العائلي).
-- لرفع الأمان لاحقاً يمكن تفعيل Supabase Auth + RLS كاملة.

-- ---------- تنظيف (للسماح بإعادة التشغيل بأمان) ----------
DROP TABLE IF EXISTS app_state CASCADE;

-- ---------- جدول الحالة الموحّد ----------
-- نخزّن حالة التطبيق كاملة ككائن JSON واحد تحت مفتاح ثابت.
-- هذا يجعل المزامنة بين الأجهزة فورية وبسيطة جداً.
CREATE TABLE app_state (
    id          TEXT PRIMARY KEY,            -- نستخدم 'family' كمفتاح وحيد
    data        JSONB NOT NULL,              -- كل بيانات العائلة (أطفال، مهام، مراحل…)
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ---------- منح الصلاحيات (ضروري في إصدارات Supabase الحديثة) ----------
-- بدون هذه الأوامر لن يصل التطبيق إلى الجدول عبر الـ API.
GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON app_state TO anon, authenticated;

-- ---------- تفعيل RLS مع سياسة مفتوحة للاستخدام العائلي ----------
ALTER TABLE app_state ENABLE ROW LEVEL SECURITY;

CREATE POLICY "وصول عائلي مفتوح"
    ON app_state
    FOR ALL
    TO anon, authenticated
    USING (true)
    WITH CHECK (true);

-- ---------- تفعيل المزامنة الفورية (Realtime) ----------
-- يجعل كل الأجهزة تتحدّث تلقائياً عند أي تغيير.
ALTER PUBLICATION supabase_realtime ADD TABLE app_state;

-- ---------- صف ابتدائي فارغ ----------
-- التطبيق سيملؤه ببيانات البداية عند أول تشغيل إذا كان فارغاً.
INSERT INTO app_state (id, data)
VALUES ('family', '{}'::jsonb)
ON CONFLICT (id) DO NOTHING;

-- تم! الآن انتقل إلى Project Settings → API وانسخ:
--   Project URL  +  anon public key
-- ثم ضعهما في ملف config.js داخل المشروع.
