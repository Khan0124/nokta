# سكريبت PowerShell لحذف جميع المعاملات المالية
# PowerShell Script to Clear Financial Data

Write-Host "🚀 بدء عملية حذف البيانات المالية من نظام Nokta POS" -ForegroundColor Green
Write-Host "==================================================" -ForegroundColor Cyan

# التحقق من وجود Node.js
try {
    $nodeVersion = node --version
    Write-Host "✅ تم العثور على Node.js: $nodeVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ لم يتم العثور على Node.js. يرجى تثبيته أولاً." -ForegroundColor Red
    exit 1
}

# الانتقال إلى مجلد المشروع
$projectPath = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $projectPath

Write-Host "📁 المجلد الحالي: $(Get-Location)" -ForegroundColor Yellow

# التحقق من وجود ملف .env
if (Test-Path "backend\.env") {
    Write-Host "✅ تم العثور على ملف .env" -ForegroundColor Green
} else {
    Write-Host "⚠️  تحذير: لم يتم العثور على ملف .env" -ForegroundColor Yellow
    Write-Host "   تأكد من إعداد متغيرات البيئة لقاعدة البيانات" -ForegroundColor Yellow
}

# الانتقال إلى مجلد backend
Set-Location "backend"

Write-Host "🔧 تثبيت التبعيات..." -ForegroundColor Yellow
npm install

Write-Host "🗑️ تشغيل سكريبت حذف البيانات المالية..." -ForegroundColor Red
Write-Host "⚠️  تحذير: سيتم حذف جميع البيانات المالية نهائياً!" -ForegroundColor Red

$confirmation = Read-Host "هل أنت متأكد من المتابعة؟ (اكتب 'نعم' للمتابعة)"

if ($confirmation -eq "نعم") {
    Write-Host "🚨 بدء عملية الحذف..." -ForegroundColor Red
    node clear_financial_data.js
} else {
    Write-Host "❌ تم إلغاء العملية" -ForegroundColor Yellow
}

Write-Host "🏁 انتهت العملية" -ForegroundColor Green
