# نظام إدارة الحضور والغياب بالبصمة — دراسة جدوى تقنية

> **النوع:** مشروع جامعي (فريق من 4 طلاب)  
> **تاريخ التحديث:** 30 يوليو 2026  
> **الحالة:** ممكن التنفيذ ✅

---

## فهرس المحتويات

| # | القسم | الوصف |
|:-:|-------|-------|
| 1 | [وصف المشروع](#1-وصف-المشروع) | الفكرة والمتطلبات |
| 2 | [متطلبات الجامعة → الحل التقني](#2-متطلبات-الجامعة--الحل-التقني) | ربط كل متطلب بالتنفيذ |
| 3 | [التقنيات المختارة](#3-التقنيات-المختارة-tech-stack) | اللغات والأدوات |
| 4 | [البنية المعمارية](#4-البنية-المعمارية-architecture) | كيف يتصل كل شيء ببعض |
| 5 | [الـ APIs الأربعة](#5-الـ-apis-الأربعة-restful) | Endpoints + CRUD |
| 6 | [ربط جهاز البصمة](#6-ربط-جهاز-البصمة-zkteco) | 3 طرق للاتصال |
| 7 | [قاعدة البيانات](#7-قاعدة-البيانات) | ERD + SQL Schema |
| 8 | [الأمان والحماية](#8-الأمان-والحماية-security) | JWT, Hashing, Validation |
| 9 | [Design Patterns](#9-أنماط-التصميم-design-patterns) | 4 أنماط مطلوبة |
| 10 | [SOLID Principles](#10-مبادئ-solid) | تطبيق عملي |
| 11 | [تصدير PDF ومشاركة واتساب](#11-تصدير-pdf-ومشاركة-واتساب) | تصدير + حفظ + مشاركة |
| 12 | [خدمة الذكاء الاصطناعي](#12-خدمة-الذكاء-الاصطناعي-ai-bonus) | Chatbot بسيط (Bonus) |
| 13 | [الاختبار](#13-الاختبار-testing) | Unit + Integration |
| 14 | [التوثيق](#14-التوثيق-documentation) | Swagger + Architecture Diagram |
| 15 | [هيكل المشروع](#15-هيكل-المشروع-folder-structure) | ملفات ومجلدات |
| 16 | [توزيع المهام على الفريق](#16-توزيع-المهام-على-الفريق-4-أشخاص) | من يعمل ماذا |
| 17 | [خطة التنفيذ](#17-خطة-التنفيذ) | الجدول الزمني |
| 18 | [أجهزة البصمة](#18-أجهزة-البصمة--الموديلات-والأسعار) | الموديلات والأسعار |
| 19 | [التكاليف](#19-تقدير-التكاليف) | المصاريف المتوقعة |
| 20 | [Checklist المتطلبات](#20-checklist--متطلبات-الجامعة) | تأكد من كل شيء |

---

## 1. وصف المشروع

نظام يربط جهاز بصمة (ZKTeco) بقاعدة بيانات مركزية لتسجيل حضور وغياب الطلاب تلقائياً، مع تصنيفهم حسب الصف والمرحلة، وإنتاج تقارير PDF قابلة للمشاركة عبر واتساب.

### المنصتان:
1. **Web Application** — لوحة إدارة + تقارير + إدارة الطلاب (Laravel)
2. **Desktop Application** — ربط جهاز البصمة + الحضور المباشر (C# WinForms)

### قاعدة بيانات مركزية واحدة:
- **MySQL** — تشترك فيها المنصتان عبر **REST API**

---

## 2. متطلبات الجامعة → الحل التقني

### 🔴 المتطلبات الإجبارية:

| # | المتطلب | ✅ الحل في مشروعنا |
|:-:|---------|-------------------|
| 1 | فريق 3-4 طلاب | 4 طلاب — توزيع المهام في القسم 16 |
| 2 | منصتين مختلفتين | **Web (Laravel)** + **Desktop (C# WinForms)** |
| 3 | قاعدة بيانات مركزية واحدة | **MySQL** — المنصتين تتصلان بها عبر API |
| 4 | التواصل عبر REST APIs حصرياً | كل العمليات عبر `api/v1/*` — لا اتصال مباشر بالـ DB |
| 5 | 4 واجهات APIs بـ CRUD | Auth, Students, Attendance, Reports (القسم 5) |
| 6 | دعم JSON و XML | `Accept: application/json` أو `Accept: application/xml` |
| 7 | JWT Authentication | Laravel Sanctum — Bearer Token |
| 8 | Authorization (صلاحيات) | 3 أدوار: Admin, Teacher, Viewer |
| 9 | Input Validation | Laravel Form Requests + `strip_tags()` |
| 10 | حماية SQL Injection | Eloquent ORM (parameterized queries) |
| 11 | حماية XSS | Blade auto-escaping `{{ }}` + CSP headers |
| 12 | تشفير كلمات المرور | `bcrypt` via `Hash::make()` |
| 13 | Token Expiry | `expiration` في Sanctum config (مثلاً 24 ساعة) |
| 14 | HTTPS | Enforce HTTPS في `.env` + middleware |
| 15 | إطارين عمل مختلفين | **Laravel** (PHP) + **WinForms/.NET** (C#) |
| 16 | 3 Design Patterns | Repository + Factory + Observer + Strategy (القسم 9) |
| 17 | SOLID Principles | تطبيق في كل طبقة (القسم 10) |
| 18 | كود Modular | طبقات: Controller → Service → Repository → Model |
| 19 | Unit Testing | PHPUnit (Laravel) + xUnit (C#) — القسم 13 |
| 20 | Integration Testing | API tests في Laravel (القسم 13) |
| 21 | توثيق الكود | Docstrings + PHPDoc + XML Comments |
| 22 | Architecture Diagram | مخطط كامل في القسم 4 |
| 23 | Swagger/OpenAPI | `L5-Swagger` package — القسم 14 |
| 24 | تقرير نهائي | المشكلة + الهيكلية + الاختبار + صور الواجهات |

### 🟢 المتطلبات الاختيارية (Bonus):

| # | المتطلب | ✅ الحل في مشروعنا |
|:-:|---------|-------------------|
| 1 | AI | Chatbot بسيط — Python Flask + OpenAI API (القسم 12) |
| 2 | UI/UX احترافي | Dark/Light mode + Responsive (Bootstrap/Tailwind) |
| 3 | MVC/MVVM | Laravel = MVC ✅ |
| 4 | WebSockets | Laravel Echo + Pusher — حضور مباشر Live |
| 5 | UI Testing | Selenium (اختياري) |

---

## 3. التقنيات المختارة (Tech Stack)

```
┌─────────────────────────────────────────────────────────────┐
│                    Tech Stack                               │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Backend API    → Laravel 11 (PHP 8.2+)        Framework 1  │
│  Desktop App    → C# WinForms (.NET 8)         Framework 2  │
│  Database       → MySQL 8.0                                 │
│  Auth           → Laravel Sanctum (JWT/Token)               │
│  PDF Export     → DomPDF (Laravel) + QuestPDF (C#)          │
│  API Docs       → Swagger (L5-Swagger)                      │
│  AI Service     → Python Flask + OpenAI API    Framework 3  │
│  Testing        → PHPUnit + xUnit                           │
│  Version Control→ Git + GitHub                              │
│                                                             │
│  Bonus:                                                     │
│  Real-time      → Laravel Echo + Pusher (WebSocket)         │
│  UI             → Bootstrap 5 / Tailwind CSS                │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### لماذا هذا الاختيار؟

| السؤال | الإجابة |
|--------|---------|
| لماذا Laravel؟ | MVC جاهز، Sanctum للـ Auth، Eloquent للـ DB، أمثلة كثيرة، سهل التقسيم |
| لماذا C# WinForms؟ | الطريقة الوحيدة السهلة لربط `zkemkeeper.dll` (جهاز البصمة) |
| لماذا MySQL؟ | مركزية، مجانية، Laravel يدعمها بشكل ممتاز |
| لماذا Python Flask للـ AI؟ | أبسط framework + مكتبات AI جاهزة + يعتبر framework ثالث (Bonus) |
| لماذا ليس React؟ | Blade templates أسرع للتطوير. React ممكن كـ Bonus لاحقاً |

---

## 4. البنية المعمارية (Architecture)

```
┌─────────────────────────────────────────────────────────────┐
│                    System Architecture                       │
│                                                             │
│   ┌──────────────┐         ┌──────────────────────────┐     │
│   │  Desktop App │         │   Web Application        │     │
│   │  C# WinForms │         │   Laravel (Blade views)  │     │
│   │              │         │                          │     │
│   │ • البصمة     │         │ • لوحة التحكم            │     │
│   │ • حضور مباشر │         │ • إدارة الطلاب           │     │
│   │ • تصدير PDF  │         │ • التقارير               │     │
│   └──────┬───────┘         │ • الإعدادات              │     │
│          │                 └──────────┬───────────────┘     │
│          │  HTTP/REST                 │  Internal            │
│          │                            │                      │
│          ▼                            ▼                      │
│   ┌──────────────────────────────────────────────────┐      │
│   │          Laravel REST API (api/v1/*)              │      │
│   │                                                   │      │
│   │  ┌──────────┐ ┌──────────┐ ┌──────────┐         │      │
│   │  │ Auth API │ │Students  │ │Attendance│         │      │
│   │  │ /auth/*  │ │ /students│ │ /attend/*│         │      │
│   │  └──────────┘ └──────────┘ └──────────┘         │      │
│   │  ┌──────────┐ ┌──────────┐                      │      │
│   │  │Reports   │ │Staff API │                      │      │
│   │  │/reports/*│ │ /staff/* │                      │      │
│   │  └──────────┘ └──────────┘                      │      │
│   │                                                   │      │
│   │  Security: Sanctum Token + Roles + Validation     │      │
│   └──────────────────────┬───────────────────────────┘      │
│                          │                                   │
│                     ┌────┴────┐                              │
│                     │  MySQL  │ ← قاعدة بيانات مركزية واحدة │
│                     │  8.0    │                              │
│                     └────┬────┘                              │
│                          │                                   │
│                   ┌──────┴──────┐                            │
│                   │ AI Service  │  ← (Bonus)                │
│                   │ Flask API   │                            │
│                   │ /ai/chat    │                            │
│                   │ /ai/predict │                            │
│                   └─────────────┘                            │
│                                                             │
│   ┌─────────────┐                                           │
│   │ ZKTeco      │ ← جهاز البصمة (TCP/4370)                 │
│   │ Device      │    يتصل بالـ Desktop App فقط              │
│   └─────────────┘                                           │
└─────────────────────────────────────────────────────────────┘
```

### تدفق البيانات:

```
جهاز البصمة ──TCP/4370──→ Desktop App (C#)
                               │
                               │ POST api/v1/attendance
                               ▼
                          Laravel API ──→ MySQL
                               │
                          Web App يقرأ من نفس الـ API
                               │
                          GET api/v1/reports/daily?class_id=3
                               │
                               ▼
                          PDF ──→ حفظ / مشاركة واتساب
```

---

## 5. الـ APIs الأربعة (RESTful)

> كل التواصل بين المنصتين وقاعدة البيانات يتم **حصرياً** عبر هذه الـ APIs.

### API 1: Authentication (`/api/v1/auth/*`)

| Method | Endpoint | الوصف | Auth |
|:------:|----------|-------|:----:|
| POST | `/api/v1/auth/register` | تسجيل مستخدم جديد | ❌ |
| POST | `/api/v1/auth/login` | تسجيل دخول → يرجع Token | ❌ |
| POST | `/api/v1/auth/logout` | تسجيل خروج (حذف Token) | ✅ |
| GET | `/api/v1/auth/me` | بيانات المستخدم الحالي | ✅ |
| PUT | `/api/v1/auth/password` | تغيير كلمة المرور | ✅ |

**Response (Login):**
```json
{
    "status": "success",
    "data": {
        "user": { "id": 1, "name": "أحمد", "role": "admin" },
        "token": "1|abc123...",
        "expires_at": "2026-08-01T00:00:00Z"
    }
}
```

---

### API 2: Students & Classes (`/api/v1/students/*`, `/api/v1/classes/*`)

| Method | Endpoint | الوصف | Auth | Role |
|:------:|----------|-------|:----:|:----:|
| GET | `/api/v1/students` | قائمة الطلاب (مع pagination) | ✅ | All |
| GET | `/api/v1/students/{id}` | بيانات طالب محدد | ✅ | All |
| POST | `/api/v1/students` | إضافة طالب جديد | ✅ | Admin |
| PUT | `/api/v1/students/{id}` | تعديل بيانات طالب | ✅ | Admin |
| DELETE | `/api/v1/students/{id}` | حذف طالب | ✅ | Admin |
| GET | `/api/v1/classes` | قائمة الصفوف | ✅ | All |
| POST | `/api/v1/classes` | إضافة صف | ✅ | Admin |
| PUT | `/api/v1/classes/{id}` | تعديل صف | ✅ | Admin |
| DELETE | `/api/v1/classes/{id}` | حذف صف | ✅ | Admin |
| GET | `/api/v1/grades` | قائمة المراحل | ✅ | All |

**Content Negotiation (JSON/XML):**
```
// JSON (default)
GET /api/v1/students
Accept: application/json

// XML
GET /api/v1/students
Accept: application/xml
```

**Response (JSON):**
```json
{
    "status": "success",
    "data": [
        {
            "id": 1,
            "full_name": "أحمد محمد",
            "class": { "id": 3, "name": "الصف الثالث أ" },
            "grade": { "id": 1, "name": "ابتدائي" },
            "fingerprint_id": "101",
            "guardian": { "name": "محمد علي", "phone": "+967..." }
        }
    ],
    "meta": { "current_page": 1, "total": 150 }
}
```

**Response (XML):**
```xml
<?xml version="1.0"?>
<response>
    <status>success</status>
    <data>
        <student>
            <id>1</id>
            <full_name>أحمد محمد</full_name>
            <fingerprint_id>101</fingerprint_id>
        </student>
    </data>
</response>
```

---

### API 3: Attendance (`/api/v1/attendance/*`)

| Method | Endpoint | الوصف | Auth | Role |
|:------:|----------|-------|:----:|:----:|
| POST | `/api/v1/attendance` | تسجيل حضور (من Desktop App) | ✅ | Admin/Teacher |
| GET | `/api/v1/attendance?date=2026-07-30&class_id=3` | سجلات يوم معين | ✅ | All |
| PUT | `/api/v1/attendance/{id}` | تعديل سجل (تصحيح خطأ) | ✅ | Admin |
| DELETE | `/api/v1/attendance/{id}` | حذف سجل | ✅ | Admin |
| POST | `/api/v1/attendance/mark-absent` | تسجيل الغائبين تلقائياً | ✅ | Admin |
| GET | `/api/v1/attendance/stats?class_id=3` | إحصائيات صف | ✅ | All |

**Request (تسجيل حضور من Desktop):**
```json
POST /api/v1/attendance
Authorization: Bearer 1|abc123...
Content-Type: application/json

{
    "fingerprint_id": "101",
    "check_in_time": "2026-07-30T07:20:00",
    "device_serial": "ZK-001"
}
```

---

### API 4: Reports (`/api/v1/reports/*`)

| Method | Endpoint | الوصف | Auth | Role |
|:------:|----------|-------|:----:|:----:|
| GET | `/api/v1/reports/daily?class_id=3&date=2026-07-30` | تقرير يومي لصف | ✅ | All |
| GET | `/api/v1/reports/weekly?class_id=3` | تقرير أسبوعي | ✅ | All |
| GET | `/api/v1/reports/monthly?class_id=3&month=7` | تقرير شهري | ✅ | All |
| GET | `/api/v1/reports/student/{id}` | تقرير طالب فردي | ✅ | All |
| GET | `/api/v1/reports/export/pdf?class_id=3&date=...` | تصدير PDF | ✅ | All |
| GET | `/api/v1/reports/export/excel?class_id=3&date=...` | تصدير Excel | ✅ | All |

**Response (تقرير يومي):**
```json
{
    "status": "success",
    "data": {
        "class": "الصف الثالث أ",
        "grade": "ابتدائي",
        "date": "2026-07-30",
        "summary": {
            "total": 31,
            "present": 28,
            "absent": 2,
            "late": 1,
            "attendance_rate": 90.3
        },
        "students": {
            "present": [
                { "name": "أحمد محمد", "check_in": "07:15", "status": "حاضر" }
            ],
            "absent": [
                { "name": "ياسر علي", "status": "غائب" }
            ],
            "late": [
                { "name": "عمر خالد", "check_in": "08:05", "late_minutes": 35 }
            ]
        }
    }
}
```

### (Bonus) API 5: AI Service (`/api/v1/ai/*`)

| Method | Endpoint | الوصف |
|:------:|----------|-------|
| POST | `/api/v1/ai/chat` | سؤال الـ Chatbot |
| GET | `/api/v1/ai/predict/{student_id}` | توقع خطر الغياب |

---

## 6. ربط جهاز البصمة (ZKTeco)

> Desktop App (C#) يتصل بالجهاز محلياً → يرسل البيانات لـ Laravel API عبر REST.

### الطريقة: PULL SDK + REST API

```
جهاز ZKTeco ←TCP/4370→ C# WinForms ←HTTP/REST→ Laravel API → MySQL
```

### كود الربط (C#):

```csharp
// 1. سحب البيانات من الجهاز
public List<RawAttendanceLog> PullFromDevice(string ip, int port = 4370)
{
    var device = new CZKEM();
    if (!device.Connect_Net(ip, port))
        throw new Exception("فشل الاتصال بالجهاز");

    var logs = new List<RawAttendanceLog>();
    device.ReadGeneralLogData(device.MachineNumber);

    string enrollNumber;
    int verifyMode, inOutMode, year, month, day, hour, minute, second, workCode = 0;

    while (device.SSR_GetGeneralLogData(device.MachineNumber,
        out enrollNumber, out verifyMode, out inOutMode,
        out year, out month, out day, out hour, out minute, out second, ref workCode))
    {
        logs.Add(new RawAttendanceLog
        {
            FingerprintId = enrollNumber,
            DateTime = new DateTime(year, month, day, hour, minute, second),
            Type = inOutMode == 0 ? "check_in" : "check_out"
        });
    }
    device.Disconnect();
    return logs;
}

// 2. إرسال البيانات لـ Laravel API
public async Task SendToApi(RawAttendanceLog log)
{
    var payload = new {
        fingerprint_id = log.FingerprintId,
        check_in_time = log.DateTime.ToString("yyyy-MM-ddTHH:mm:ss"),
        device_serial = "ZK-001"
    };
    var json = JsonSerializer.Serialize(payload);
    var content = new StringContent(json, Encoding.UTF8, "application/json");

    _httpClient.DefaultRequestHeaders.Authorization =
        new AuthenticationHeaderValue("Bearer", _token);

    await _httpClient.PostAsync($"{API_BASE}/api/v1/attendance", content);
}
```

---

## 7. قاعدة البيانات

### ERD:

```
┌──────────┐     ┌──────────┐     ┌──────────┐
│  users   │     │  grades  │────→│ classes  │
│──────────│     │──────────│     │──────────│
│ id (PK)  │     │ id (PK)  │     │ id (PK)  │
│ name     │     │ name     │     │ name     │
│ email    │     └──────────┘     │ grade_id │
│ password │                      └────┬─────┘
│ role     │                           │
└──────────┘                      ┌────┴─────┐     ┌──────────────┐
                                  │ students │────→│  guardians   │
                                  │──────────│     │──────────────│
                                  │ id (PK)  │     │ id (PK)      │
                                  │ full_name│     │ name         │
                                  │ class_id │     │ phone        │
                                  │ guard_id │     └──────────────┘
                                  │ finger_id│
                                  │ is_active│
                                  └────┬─────┘
                                       │
                              ┌────────┴────────┐
                              │attendance_logs  │
                              │────────────────│
                              │ id (PK)        │
                              │ student_id(FK) │
                              │ check_in_time  │
                              │ check_out_time │
                              │ date           │
                              │ status         │  ← حاضر|غائب|متأخر
                              └────────────────┘

┌──────────┐     ┌────────────────────┐
│  staff   │────→│ staff_attendance   │
│──────────│     │────────────────────│
│ id (PK)  │     │ id (PK)           │
│ full_name│     │ staff_id (FK)     │
│ role     │     │ check_in_time     │
│ finger_id│     │ check_out_time    │
│ is_active│     │ date              │
└──────────┘     │ status            │
                 └────────────────────┘
```

### Laravel Migrations:

```php
// database/migrations/create_students_table.php
Schema::create('students', function (Blueprint $table) {
    $table->id();
    $table->string('full_name');
    $table->foreignId('class_id')->constrained('classes');
    $table->foreignId('guardian_id')->nullable()->constrained('guardians');
    $table->string('fingerprint_id')->unique();
    $table->boolean('is_active')->default(true);
    $table->timestamps();

    $table->index('class_id');
    $table->index('fingerprint_id');
});

// database/migrations/create_attendance_logs_table.php
Schema::create('attendance_logs', function (Blueprint $table) {
    $table->id();
    $table->foreignId('student_id')->constrained()->onDelete('cascade');
    $table->dateTime('check_in_time')->nullable();
    $table->dateTime('check_out_time')->nullable();
    $table->date('attendance_date');
    $table->enum('status', ['حاضر', 'غائب', 'متأخر'])->default('حاضر');
    $table->timestamps();

    $table->index(['attendance_date', 'student_id']);
});
```

---

## 8. الأمان والحماية (Security)

> كل المتطلبات الأمنية المطلوبة وكيف ننفذها:

| # | المتطلب | التنفيذ في Laravel | التنفيذ في C# |
|:-:|---------|-------------------|--------------|
| 1 | **JWT/Token Auth** | `Sanctum::actingAs()` — Token في Header | `Authorization: Bearer {token}` عبر HttpClient |
| 2 | **Authorization** | Middleware: `role:admin` + Gates/Policies | تحقق من role في response الـ login |
| 3 | **Input Validation** | `FormRequest` classes + `strip_tags()` | Validate قبل الإرسال لـ API |
| 4 | **SQL Injection** | Eloquent ORM = parameterized queries تلقائياً | لا يتصل بـ DB مباشرة (عبر API فقط) |
| 5 | **XSS Protection** | Blade: `{{ $var }}` auto-escapes + CSP headers | لا يعرض HTML خارجي |
| 6 | **Password Hashing** | `Hash::make($password)` = bcrypt | لا يخزّن كلمات مرور محلياً |
| 7 | **Token Expiry** | `config/sanctum.php`: `'expiration' => 1440` (24 ساعة) | يتحقق من 401 ويطلب login جديد |
| 8 | **HTTPS** | `APP_URL=https://...` + `\ForceScheme::class` middleware | `HttpClient.BaseAddress = https://...` |

### كود Auth في Laravel:

```php
// app/Http/Controllers/Api/AuthController.php
class AuthController extends Controller
{
    public function login(LoginRequest $request)  // FormRequest validation
    {
        $user = User::where('email', $request->email)->first();

        if (!$user || !Hash::check($request->password, $user->password)) {
            return response()->json(['error' => 'بيانات غير صحيحة'], 401);
        }

        $token = $user->createToken('api-token', [$user->role], now()->addHours(24));

        return response()->json([
            'user' => new UserResource($user),
            'token' => $token->plainTextToken,
            'expires_at' => now()->addHours(24)->toISOString()
        ]);
    }
}

// routes/api.php
Route::prefix('v1')->group(function () {
    Route::post('auth/login', [AuthController::class, 'login']);
    Route::post('auth/register', [AuthController::class, 'register']);

    Route::middleware('auth:sanctum')->group(function () {
        Route::post('auth/logout', [AuthController::class, 'logout']);
        Route::apiResource('students', StudentController::class);
        Route::apiResource('attendance', AttendanceController::class);
        Route::get('reports/daily', [ReportController::class, 'daily']);

        // Admin only
        Route::middleware('role:admin')->group(function () {
            Route::delete('students/{id}', [StudentController::class, 'destroy']);
        });
    });
});
```

---

## 9. أنماط التصميم (Design Patterns)

> المطلوب 3 على الأقل — سنطبّق 4:

### Pattern 1: Repository Pattern

```php
// الغرض: فصل منطق الوصول للبيانات عن Controllers

// app/Repositories/Contracts/StudentRepositoryInterface.php
interface StudentRepositoryInterface
{
    public function all(array $filters = []): Collection;
    public function findById(int $id): ?Student;
    public function create(array $data): Student;
    public function update(int $id, array $data): Student;
    public function delete(int $id): bool;
    public function findByFingerprintId(string $fingerprintId): ?Student;
}

// app/Repositories/Eloquent/StudentRepository.php
class StudentRepository implements StudentRepositoryInterface
{
    public function findByFingerprintId(string $fingerprintId): ?Student
    {
        return Student::where('fingerprint_id', $fingerprintId)->first();
    }
    // ... باقي الـ methods
}
```

### Pattern 2: Factory Pattern

```php
// الغرض: إنشاء أنواع مختلفة من التقارير (PDF, Excel, Word)

// app/Services/Export/ExportFactory.php
class ExportFactory
{
    public static function create(string $format): ExportInterface
    {
        return match($format) {
            'pdf'   => new PdfExporter(),
            'excel' => new ExcelExporter(),
            'word'  => new WordExporter(),
            default => throw new \InvalidArgumentException("Unsupported format: $format")
        };
    }
}

// الاستخدام:
$exporter = ExportFactory::create('pdf');
$file = $exporter->export($reportData);
```

### Pattern 3: Observer Pattern

```php
// الغرض: عند تسجيل حضور → تنبيهات + تحديث إحصائيات

// app/Events/AttendanceRecorded.php
class AttendanceRecorded
{
    public function __construct(public AttendanceLog $log) {}
}

// app/Listeners/UpdateClassStats.php
class UpdateClassStats
{
    public function handle(AttendanceRecorded $event)
    {
        // تحديث إحصائيات الصف
        Cache::forget("class_stats_{$event->log->student->class_id}");
    }
}

// app/Listeners/NotifyGuardianIfAbsent.php
class NotifyGuardianIfAbsent
{
    public function handle(AttendanceRecorded $event)
    {
        if ($event->log->status === 'غائب') {
            // إرسال SMS لولي الأمر (اختياري)
        }
    }
}
```

### Pattern 4: Strategy Pattern

```php
// الغرض: طرق مختلفة لتحديد حالة الحضور

// app/Services/Attendance/AttendanceStrategyInterface.php
interface AttendanceStrategyInterface
{
    public function determineStatus(Carbon $checkInTime, Carbon $schoolStart): string;
}

// app/Services/Attendance/DefaultAttendanceStrategy.php
class DefaultAttendanceStrategy implements AttendanceStrategyInterface
{
    public function determineStatus(Carbon $checkInTime, Carbon $schoolStart): string
    {
        $lateThreshold = $schoolStart->copy()->addMinutes(15);
        if ($checkInTime->lte($lateThreshold)) return 'حاضر';
        return 'متأخر';
    }
}
```

---

## 10. مبادئ SOLID

| المبدأ | التطبيق في مشروعنا |
|--------|-------------------|
| **S — Single Responsibility** | كل Controller يعالج resource واحد. Service للمنطق. Repository للبيانات |
| **O — Open/Closed** | `ExportFactory` يدعم إضافة formats جديدة بدون تعديل الكود الموجود |
| **L — Liskov Substitution** | `StudentRepository` يمكن استبداله بـ `CachedStudentRepository` بدون كسر |
| **I — Interface Segregation** | `StudentRepositoryInterface` منفصل عن `AttendanceRepositoryInterface` |
| **D — Dependency Inversion** | Controllers تعتمد على Interfaces — Binding يتم في `AppServiceProvider` |

```php
// D — Dependency Inversion في AppServiceProvider
public function register()
{
    $this->app->bind(StudentRepositoryInterface::class, StudentRepository::class);
    $this->app->bind(AttendanceRepositoryInterface::class, AttendanceRepository::class);
}
```

---

## 11. تصدير PDF ومشاركة واتساب

### تصدير PDF (Laravel — DomPDF):

```php
// app/Http/Controllers/Api/ReportController.php
use Barryvdh\DomPDF\Facade\Pdf;

public function exportPdf(Request $request)
{
    $data = $this->reportService->getDailyReport(
        $request->class_id,
        $request->date
    );

    $pdf = Pdf::loadView('reports.daily-pdf', compact('data'));
    $pdf->setPaper('A4');

    // حفظ في السيرفر
    $path = "reports/report_{$request->class_id}_{$request->date}.pdf";
    Storage::put($path, $pdf->output());

    // أو إرجاع مباشرة
    return $pdf->download("تقرير_حضور_{$data['class']}.pdf");
}
```

### تصدير PDF (C# — QuestPDF):

```csharp
using QuestPDF.Fluent;

public byte[] GeneratePdf(DailyReport report)
{
    QuestPDF.Settings.License = LicenseType.Community;

    return Document.Create(container =>
    {
        container.Page(page =>
        {
            page.Size(PageSizes.A4);
            page.Margin(30);
            page.DefaultTextStyle(x => x.FontFamily("Arial").FontSize(12));

            page.Header().Text($"تقرير حضور {report.ClassName}")
                .FontSize(18).Bold().AlignCenter();

            page.Content().Table(table =>
            {
                table.ColumnsDefinition(c => {
                    c.RelativeColumn(); c.RelativeColumn(); c.RelativeColumn();
                });
                table.Header(h => {
                    h.Cell().Text("الاسم").Bold();
                    h.Cell().Text("الحالة").Bold();
                    h.Cell().Text("الوقت").Bold();
                });
                foreach (var s in report.Students)
                {
                    table.Cell().Text(s.Name);
                    table.Cell().Text(s.Status);
                    table.Cell().Text(s.CheckInTime?.ToString("hh:mm tt") ?? "—");
                }
            });
        });
    }).GeneratePdf();
}
```

### المشاركة عبر واتساب:

```
خيارات المشاركة في التطبيق:
├── 📥 حفظ PDF — حفظ الملف في مجلد على الجهاز
├── 📤 مشاركة — فتح نافذة مشاركة Windows
│                (المستخدم يختار واتساب أو أي تطبيق)
└── 📋 نسخ النص — نسخ ملخص نصي للـ Clipboard (كخيار إضافي)
```

```csharp
// C# — حفظ PDF ثم فتحه (المستخدم يشاركه يدوياً)
void BtnExportPdf_Click(object sender, EventArgs e)
{
    var pdf = _reportService.GeneratePdf(currentReport);
    var path = Path.Combine(Environment.GetFolderPath(
        Environment.SpecialFolder.MyDocuments), $"تقرير_{DateTime.Now:yyyyMMdd}.pdf");
    File.WriteAllBytes(path, pdf);

    // فتح الملف (المستخدم يشاركه من هناك للواتساب)
    Process.Start(new ProcessStartInfo(path) { UseShellExecute = true });
}

// أو فتح مجلد الحفظ
void BtnOpenFolder_Click(object sender, EventArgs e)
{
    Process.Start("explorer.exe", $"/select,\"{savedFilePath}\"");
}
```

---

## 12. خدمة الذكاء الاصطناعي (AI — Bonus)

> خدمة بسيطة بـ Python Flask تعمل كـ microservice منفصل.

### الفكرة: Chatbot مساعد + توقع الغياب

```
┌───────────────┐         ┌──────────────────┐
│ Laravel API   │ ←HTTP→  │ Flask AI Service │
│ /api/v1/ai/*  │         │ Port 5000        │
└───────────────┘         │                  │
                          │ /chat            │ ← سؤال وجواب عن الحضور
                          │ /predict/{id}    │ ← توقع خطر الغياب
                          └──────────────────┘
```

### كود AI Service (Python Flask):

```python
from flask import Flask, request, jsonify
from openai import OpenAI
import mysql.connector

app = Flask(__name__)
client = OpenAI(api_key="YOUR_KEY")

@app.route('/chat', methods=['POST'])
def chat():
    """Chatbot: اسأل عن حضور طالب أو صف"""
    user_message = request.json.get('message', '')

    # جلب بيانات من قاعدة البيانات لإعطاء سياق
    db = get_db_connection()
    cursor = db.cursor(dictionary=True)
    cursor.execute("""
        SELECT c.name, COUNT(*) as total,
               SUM(CASE WHEN a.status='حاضر' THEN 1 ELSE 0 END) as present
        FROM attendance_logs a
        JOIN students s ON a.student_id = s.id
        JOIN classes c ON s.class_id = c.id
        WHERE a.attendance_date = CURDATE()
        GROUP BY c.id
    """)
    stats = cursor.fetchall()

    response = client.chat.completions.create(
        model="gpt-3.5-turbo",
        messages=[
            {"role": "system", "content": f"""أنت مساعد ذكي لنظام حضور مدرسي.
            إحصائيات اليوم: {stats}
            أجب بالعربية بشكل مختصر ومفيد."""},
            {"role": "user", "content": user_message}
        ]
    )
    return jsonify({"reply": response.choices[0].message.content})

@app.route('/predict/<int:student_id>')
def predict_risk(student_id):
    """توقع: هل الطالب معرّض لخطر غياب مرتفع؟"""
    db = get_db_connection()
    cursor = db.cursor(dictionary=True)
    cursor.execute("""
        SELECT COUNT(*) as total_days,
               SUM(CASE WHEN status='غائب' THEN 1 ELSE 0 END) as absent_days,
               SUM(CASE WHEN status='متأخر' THEN 1 ELSE 0 END) as late_days
        FROM attendance_logs WHERE student_id = %s
        AND attendance_date >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
    """, (student_id,))
    data = cursor.fetchone()

    if not data or data['total_days'] == 0:
        return jsonify({"risk": "unknown", "message": "لا توجد بيانات كافية"})

    absence_rate = data['absent_days'] / data['total_days']

    if absence_rate > 0.3:
        risk = "high"
        message = "⚠️ خطر عالي — نسبة الغياب تتجاوز 30%"
    elif absence_rate > 0.15:
        risk = "medium"
        message = "⚡ خطر متوسط — يجب المتابعة"
    else:
        risk = "low"
        message = "✅ الطالب منتظم"

    return jsonify({
        "student_id": student_id,
        "risk": risk,
        "message": message,
        "stats": data
    })

if __name__ == '__main__':
    app.run(port=5000)
```

> **ملاحظة في التوثيق:** مصدر البيانات = قاعدة بيانات الحضور. النموذج = Rule-based + OpenAI GPT-3.5 للـ chatbot.

---

## 13. الاختبار (Testing)

### Unit Tests (PHPUnit — Laravel):

```php
// tests/Unit/AttendanceServiceTest.php
class AttendanceServiceTest extends TestCase
{
    public function test_determine_status_on_time()
    {
        $service = new AttendanceService(new DefaultAttendanceStrategy());
        $schoolStart = Carbon::parse('07:30');
        $checkIn = Carbon::parse('07:20');

        $status = $service->determineStatus($checkIn, $schoolStart);

        $this->assertEquals('حاضر', $status);
    }

    public function test_determine_status_late()
    {
        $service = new AttendanceService(new DefaultAttendanceStrategy());
        $schoolStart = Carbon::parse('07:30');
        $checkIn = Carbon::parse('08:10');

        $status = $service->determineStatus($checkIn, $schoolStart);

        $this->assertEquals('متأخر', $status);
    }

    public function test_mark_absent_students()
    {
        // seed students, no attendance for today
        Student::factory()->count(5)->create();

        $service = app(AttendanceService::class);
        $service->markAbsentStudents(today());

        $this->assertEquals(5, AttendanceLog::where('status', 'غائب')->count());
    }
}
```

### Integration Tests (Laravel API):

```php
// tests/Feature/AttendanceApiTest.php
class AttendanceApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_record_attendance_requires_auth()
    {
        $response = $this->postJson('/api/v1/attendance', [
            'fingerprint_id' => '101',
            'check_in_time' => now()->toISOString(),
        ]);
        $response->assertStatus(401);
    }

    public function test_record_attendance_success()
    {
        $user = User::factory()->create(['role' => 'admin']);
        $student = Student::factory()->create(['fingerprint_id' => '101']);

        $response = $this->actingAs($user, 'sanctum')
            ->postJson('/api/v1/attendance', [
                'fingerprint_id' => '101',
                'check_in_time' => '2026-07-30T07:20:00',
            ]);

        $response->assertStatus(201);
        $this->assertDatabaseHas('attendance_logs', [
            'student_id' => $student->id,
            'status' => 'حاضر',
        ]);
    }

    public function test_daily_report_returns_correct_data()
    {
        $user = User::factory()->create();
        // seed class, students, and attendance

        $response = $this->actingAs($user, 'sanctum')
            ->getJson('/api/v1/reports/daily?class_id=1&date=2026-07-30');

        $response->assertStatus(200)
            ->assertJsonStructure([
                'data' => ['class', 'summary' => ['total', 'present', 'absent']]
            ]);
    }
}
```

### اختبار أوامر التشغيل:

```bash
# Laravel
php artisan test                        # كل الاختبارات
php artisan test --filter=Attendance    # اختبارات الحضور فقط

# C# (xUnit)
dotnet test
```

---

## 14. التوثيق (Documentation)

### Swagger/OpenAPI (L5-Swagger):

```bash
composer require darkaonline/l5-swagger
php artisan l5-swagger:generate
# يفتح على: http://localhost/api/documentation
```

```php
/**
 * @OA\Post(
 *     path="/api/v1/attendance",
 *     summary="تسجيل حضور طالب",
 *     tags={"Attendance"},
 *     security={{"bearerAuth":{}}},
 *     @OA\RequestBody(
 *         @OA\JsonContent(
 *             required={"fingerprint_id", "check_in_time"},
 *             @OA\Property(property="fingerprint_id", type="string", example="101"),
 *             @OA\Property(property="check_in_time", type="string", format="datetime")
 *         )
 *     ),
 *     @OA\Response(response=201, description="تم التسجيل بنجاح"),
 *     @OA\Response(response=401, description="غير مصرح"),
 *     @OA\Response(response=404, description="بصمة غير مسجلة")
 * )
 */
```

### Architecture Diagram:
- الرسم في القسم 4 (البنية المعمارية)
- يُصدّر كصورة أو PDF في التقرير النهائي

### التقرير النهائي يشمل:
1. المشكلة والحل المقترح
2. Architecture Diagram
3. مخطط ERD
4. شرح الـ APIs (Swagger link)
5. مراحل التطوير
6. استراتيجية الاختبار ونتائجه
7. صور/screenshots لواجهات النظام
8. قسم AI: مصدر البيانات + النموذج المستخدم

---

## 15. هيكل المشروع (Folder Structure)

### Backend (Laravel):

```
attendance-api/
├── app/
│   ├── Http/
│   │   ├── Controllers/Api/
│   │   │   ├── AuthController.php
│   │   │   ├── StudentController.php
│   │   │   ├── AttendanceController.php
│   │   │   ├── ReportController.php
│   │   │   └── StaffController.php
│   │   ├── Requests/
│   │   │   ├── LoginRequest.php
│   │   │   ├── StoreStudentRequest.php        ← Input Validation
│   │   │   └── RecordAttendanceRequest.php
│   │   ├── Resources/
│   │   │   ├── StudentResource.php            ← JSON/XML formatting
│   │   │   ├── AttendanceResource.php
│   │   │   └── ReportResource.php
│   │   └── Middleware/
│   │       ├── RoleMiddleware.php             ← Authorization
│   │       └── ForceJsonResponse.php
│   ├── Models/
│   ├── Repositories/
│   │   ├── Contracts/                         ← Interfaces
│   │   └── Eloquent/                          ← Implementations
│   ├── Services/
│   │   ├── AttendanceService.php
│   │   ├── ReportService.php
│   │   └── Export/
│   │       ├── ExportInterface.php
│   │       ├── ExportFactory.php              ← Factory Pattern
│   │       ├── PdfExporter.php
│   │       └── ExcelExporter.php
│   ├── Events/
│   │   └── AttendanceRecorded.php             ← Observer Pattern
│   └── Listeners/
│       ├── UpdateClassStats.php
│       └── NotifyGuardianIfAbsent.php
├── database/migrations/
├── resources/views/
│   ├── layouts/app.blade.php
│   ├── dashboard.blade.php
│   └── reports/daily-pdf.blade.php
├── routes/
│   ├── api.php                                ← REST API routes
│   └── web.php                                ← Web views routes
├── tests/
│   ├── Unit/
│   │   └── AttendanceServiceTest.php
│   └── Feature/
│       └── AttendanceApiTest.php
└── storage/app/reports/                       ← PDF files
```

### Desktop (C# WinForms):

```
AttendanceDesktop/
├── AttendanceDesktop.csproj
├── Program.cs
├── Models/                                    ← DTOs matching API responses
├── Services/
│   ├── ApiClient.cs                           ← HttpClient wrapper
│   ├── FingerprintService.cs                  ← zkemkeeper.dll
│   ├── PdfService.cs                          ← QuestPDF
│   └── AuthService.cs
├── Forms/
│   ├── LoginForm.cs
│   ├── MainForm.cs
│   ├── LiveAttendancePanel.cs
│   └── ReportsPanel.cs
└── Tests/
    └── FingerprintServiceTests.cs
```

### AI Service (Python Flask):

```
ai-service/
├── app.py
├── requirements.txt                           ← flask, openai, mysql-connector
├── config.py
└── tests/
    └── test_predict.py
```

---

## 16. توزيع المهام على الفريق (4 أشخاص)

```
┌─────────────────────────────────────────────────────────────┐
│              توزيع المهام على الفريق                         │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  👤 شخص 1 — Backend Developer                              │
│  ├── Laravel API (Controllers, Routes, Middleware)          │
│  ├── Authentication (Sanctum, JWT)                          │
│  ├── Database (Migrations, Seeders)                         │
│  ├── Repository + Service Layer                             │
│  └── API Testing (Integration Tests)                        │
│                                                             │
│  👤 شخص 2 — Frontend Developer                             │
│  ├── Laravel Blade Views (Dashboard, Students, Reports)     │
│  ├── Bootstrap/Tailwind CSS                                 │
│  ├── Dark/Light Mode                                        │
│  ├── PDF View Template (daily-pdf.blade.php)                │
│  └── Responsive Design                                      │
│                                                             │
│  👤 شخص 3 — Desktop Developer                              │
│  ├── C# WinForms Application                                │
│  ├── ZKTeco Device Connection (zkemkeeper.dll)              │
│  ├── API Client (HttpClient → Laravel API)                  │
│  ├── PDF Export (QuestPDF) + File Sharing                   │
│  └── Unit Tests (xUnit)                                     │
│                                                             │
│  👤 شخص 4 — AI + Testing + Documentation                   │
│  ├── Python Flask AI Service (Chatbot + Prediction)         │
│  ├── Unit Tests (PHPUnit — Core Logic)                      │
│  ├── Swagger/OpenAPI Documentation                          │
│  ├── Architecture Diagram                                   │
│  ├── التقرير النهائي                                        │
│  └── Code Comments + Docstrings                             │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### التنسيق بين الفريق:

```
أسبوع 1: الكل يشتغل بالتوازي
├── شخص 1: يجهز API + DB
├── شخص 2: يجهز الـ views الأساسية (بدون بيانات حقيقية)
├── شخص 3: يجهز Desktop App skeleton + اتصال الجهاز
└── شخص 4: يجهز Flask AI skeleton

أسبوع 2: الربط
├── شخص 2 يربط views بـ API (شخص 1)
├── شخص 3 يربط Desktop بـ API (شخص 1)
└── شخص 4 يربط AI بـ Laravel

أسبوع 3-4: التحسين + الاختبار + التوثيق
```

---

## 17. خطة التنفيذ

| الأسبوع | المهام | المخرجات |
|:-------:|--------|----------|
| **1** | DB + Models + Auth API + Desktop skeleton | يمكن تسجيل دخول عبر API |
| **2** | Students API + Classes API + CRUD views | إدارة الطلاب والصفوف تعمل |
| **3** | Attendance API + ربط الجهاز + Live panel | البصمة تسجل الحضور عبر API |
| **4** | Reports API + PDF export + Dashboard | تقارير جاهزة + تصدير PDF |
| **5** | AI service + Staff module | Chatbot يعمل + قسم الإداريين |
| **6** | Testing + Swagger + Security audit | كل الاختبارات تمر |
| **7** | التقرير النهائي + Polish + Screenshots | جاهز للتسليم |

---

## 18. أجهزة البصمة — الموديلات والأسعار

| الموديل | السعر | سعة البصمات | سعة السجلات | بطارية | SDK |
|---------|:-----:|:-----------:|:-----------:|:------:|:---:|
| **K40** | $90-150 | 1,000-2,000 | 80,000+ | ✅ | ✅ |
| **K60** | $100-170 | 3,000 | 100,000 | ✅ | ✅ |
| **SpeedFace** | $250-500 | 10,000+ | 200,000+ | حسب الموديل | ✅ |

### الاختيار:
- **أقل من 500 طالب** → K40 ($90-150)
- **أكثر** → K60 أو SpeedFace

---

## 19. تقدير التكاليف

| البند | التكلفة | نوع |
|-------|:-------:|:---:|
| جهاز ZKTeco (K40/K60) | $90-170 | لمرة واحدة |
| استضافة MySQL + Laravel (VPS) | $5-10/شهر | شهري |
| OpenAI API (GPT-3.5 — للـ AI) | $1-5/شهر | شهري |
| البرنامج + الأدوات | $0 | مجاني |
| **الإجمالي** | **~$100-185 + $10/شهر** | |

---

## 20. Checklist — متطلبات الجامعة

### 🔴 إجبارية:

```
[ ] فريق 3-4 طلاب
[ ] منصتين: Web (Laravel) + Desktop (C# WinForms)
[ ] قاعدة بيانات مركزية: MySQL
[ ] REST API حصرياً (لا DB مباشر)
[ ] 4+ APIs: Auth, Students, Attendance, Reports
[ ] CRUD لكل API
[ ] JSON + XML support
[ ] JWT (Sanctum) Authentication
[ ] Authorization (Admin/Teacher/Viewer)
[ ] Input Validation (FormRequests)
[ ] SQL Injection protection (Eloquent ORM)
[ ] XSS protection (Blade escaping)
[ ] Password Hashing (bcrypt)
[ ] Token Expiry (24h)
[ ] HTTPS
[ ] 2 Frameworks: Laravel + .NET WinForms
[ ] 3+ Design Patterns: Repository, Factory, Observer, Strategy
[ ] SOLID Principles
[ ] Modular Code (Layered Architecture)
[ ] Unit Tests (PHPUnit + xUnit)
[ ] Integration Tests (API tests)
[ ] Code Documentation (Docstrings/PHPDoc)
[ ] Architecture Diagram
[ ] Swagger/OpenAPI
[ ] التقرير النهائي
```

### 🟢 اختيارية (Bonus):

```
[ ] AI: Flask Chatbot + Absence Prediction
[ ] UI/UX: Dark/Light Mode, Responsive
[ ] MVC Architecture (Laravel = MVC ✅)
[ ] WebSocket: Laravel Echo (Live Attendance)
[ ] UI Testing: Selenium (اختياري)
```
