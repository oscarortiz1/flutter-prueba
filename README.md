# Flutter Prueba — Frontend

Este README describe cómo ejecutar la app Flutter incluida en este repositorio, la arquitectura general, las decisiones de diseño y cómo cumple los requisitos del enunciado.

> Alcance general implementado (resumen):
>- Autenticación simple con email y código OTP (simulado / local notification para pruebas).
>- Listado paginado de movimientos (mínimo 20 por página) con pull-to-refresh.
>- Modo offline: si no hay conexión, la app muestra los últimos datos almacenados en SQLite y muestra un aviso al usuario.
>- Manejo de errores: mensajes amigables y posibilidad de reintentar operaciones.
>- Tema claro/oscuro completo.
>- Animaciones sutiles para tarjetas y transición.

Condición especial (implementado / notas):
- Crear tu propio mock API: el repositorio incluye un backend NestJS (`../flutter_prueba_backend`) que funciona como API mock (endpoints: `/auth`, `/movimientos`, etc.).
- Manejo de estados: utilizo BLoC (`flutter_bloc`) para la mayoría de flujos (auth, movimientos). Justificación abajo.
- Almacenamiento offline: implementado con SQLite a través de `sqflite` y una abstracción `DBProvider`. (Si prefieres ISAR, puede migrarse; hoy la app usa SQLite por compatibilidad y simplicidad.)
- Pruebas unitarias: hay tests unitarios y widget tests en `test/` que cubren: repositorios, blocs y widgets clave.

Repositorio — estructura clave
```
lib/
  main.dart                # entrypoint, carga .env y configura ApiService
  pages/
    movements/             # UI y Bloc para listado paginado
    login/                 # login + OTP
  shared/
    services/
      api_service.dart     # Dio wrapper, auth interceptor
      auth_service.dart
      sync_service.dart
      db_provider.dart     # SQLite provider
    repositories/
      movement_repository.dart
    models/
      movement.dart
test/
  movement_repository_test.dart
  widget_test.dart
flutter_prueba_backend/    # mock API (NestJS)
  src/
    movimientos/
    auth/
```

Requisitos y cómo correr

1) Backend (mock API - NestJS)

Requisitos: Node.js v18+ y npm

Desde la carpeta `flutter_prueba_backend`:

```powershell
npm install
npm run build   # (o `nest build` si usas `@nestjs/cli` global)
npm run start   # ejecuta `node dist/main.js`
# en desarrollo puedes usar:
npm run start:dev
```

Endpoints principales (resumen):
- `POST /auth/otp` — solicita/crea OTP para email (mock)
- `POST /auth/verify` — verifica OTP, retorna access_token & refresh_token
- `POST /auth/refresh` — refresh token
- `GET /movimientos` — obtiene movimientos; soporta query `?page=&limit=&q=` y devuelve `{ data, total, totalPages }`
- `POST /movimientos`, `DELETE /movimientos/:id`

2) Frontend (Flutter app)

Requisitos: Flutter SDK (stable), `flutter pub get` ejecutado.

Preparar entorno:
- Crea un archivo `.env` en la raíz del proyecto Flutter (`flutter_prueba/.env`) con:
```
BASE_URL=http://localhost:3000
```
(O usa la URL remota si prefieres, p.ej. `https://flutter-prueba-backend.onrender.com`)

Comandos:
```powershell
flutter pub get
flutter run           # o `flutter run -d <device>`
flutter test --coverage
flutter analyze
```

Arquitectura y decisiones

- State management: BLoC
  - Por qué: separa claramente UI y lógica de negocio, facilita testing y trazabilidad, y encaja bien con la estructura de eventos/estados que requiere paginado, refresh y sincronización.
- Almacenamiento offline: SQLite (via `sqflite`) y una capa `MovementRepository` que abstrae la fuente de datos. Se implementa `upsertFromServer()` y colas de sincronización para cambios offline.
- API client: `Dio` con interceptor que inyecta `Authorization` y reintenta usando `refresh_token` si recibe 401.
- Paginación: servidor provee `totalPages`, frontend muestra controles de paginador (Anterior / Página X de Y / Siguiente). Tamaño de página por defecto: 20.
- Tests: tests unitarios para repositorio y bloc; widget tests para vistas críticas.

Cómo cumple los entregables

- Código fuente
  - Está todo en este repositorio; preserva el historial de commits localmente.
- README breve (este documento)
- Cómo ejecutar mock API y la app
  - Instrucciones arriba.
- Evidencia de ejecución
  - Incluye tests en `test/`; puedes agregar capturas de pantalla o un corto video y subirlo junto al repositorio.

Notas finales y mejoras sugeridas

- Si deseas migrar a ISAR para mejor rendimiento offline y consultas más rápidas, puedo proveer una PR que lo migre.
- Puedo añadir pruebas E2E (integration tests) que arranquen la API mock y la app para validar flujos críticos.

Contacta si quieres que genere también un ZIP con el historial de commits o que suba el repositorio a un remoto privado (te doy instrucciones).
