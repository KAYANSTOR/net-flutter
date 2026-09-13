# Phase 8 — Customer SMS Broadcast

**تاريخ:** 2026-09-13

## الهدف

تمكين صاحب الشبكة من إرسال رسالة إدارية جماعية للعملاء المسجلين، مع استبعاد المحظورين والتالفين والمدمجين، وتأكيد صريح قبل الإرسال، وتسجيل نتيجة كل مستلم.

## ما تم تنفيذه

- كيانات `BroadcastJob` و`BroadcastRecipient` مع الحالات المعتمدة في الخطة.
- `LocalBroadcastRepository` يخزّن المهام كـ JSON في الإعدادات (`broadcast_jobs`) دون جدول Drift جديد.
- `LocalBroadcastService`: معاينة المستلمين، مسودة، تأكيد، تشغيل على دفعات، إيقاف، إلغاء.
- استبعاد: `blacklisted`، `merged`/`archived`، بلا رقم هاتف، وتكرار الرقم بعد التطبيع.
- البث الإداري **لا يستهلك رصيد ترخيص الكروت**.
- معدل الإرسال عبر `SettingKeys.broadcastRatePerMinute` (افتراضي 20 رسالة/دقيقة).
- Audit: `broadcast_drafted` / `broadcast_confirmed` / `broadcast_started` / `broadcast_finished`.
- واجهة: `BroadcastSmsScreen` من إعدادات الجهاز والرسائل، مع حوار تأكيد يعرض العدد والنص.

## اختبارات

`test/services/broadcast_sms_service_test.dart`

## بوابة التحقق المتبقية

- تجربة إرسال حقيقية على جهاز Android مع سياسات Google Play وصلاحيات SMS.
- قياس معدل الإرسال على أرقام إنتاجية وتكلفة المشغّل.
- إيقاف المهمة أثناء الإرسال من واجهة التشغيل إن لزم بعد التحقق الميداني.
