# Flutter Prueba — Frontend

Este README explica cómo ejecutar la app Flutter y cómo enlazarla con el mock API. Contiene además decisiones de arquitectura, cómo se cumple el alcance solicitado y referencias a la documentación del backend (Swagger).

# ⚠️ Importante

**DEBES INGRESAR A ESTE LINK PARA QUE RENDER INICIALICE:**  
https://flutter-prueba-backend.onrender.com/api

[Ver video en YouTube](https://youtu.be/pVl4b69sT-Y)

![Captura 1](imagenes/Captura%20de%20pantalla%202025-09-18%20201311.png)
![Captura 2](imagenes/Captura%20de%20pantalla%202025-09-18%20201323.png)
![Captura 3](imagenes/Captura%20de%20pantalla%202025-09-18%20201332.png)
![Captura 4](imagenes/Captura%20de%20pantalla%202025-09-18%20201349.png)
![Captura 5](imagenes/Captura%20de%20pantalla%202025-09-18%20201357.png)
![Captura 6](imagenes/Captura%20de%20pantalla%202025-09-18%20201406.png)


Resumen del alcance implementado
- Autenticación simple con email y código OTP (simulado en el backend).
- Listado paginado de movimientos (mínimo 20 por página) con pull-to-refresh.
- Modo offline: si no hay conexión, la app muestra los últimos datos almacenados en SQLite y muestra un aviso al usuario.
- Manejo de errores: mensajes amigables y posibilidad de reintentar.
- Modo claro y oscuro.
- Animaciones sutiles en tarjetas y transiciones.

Referencia al Mock API y Swagger
- El backend mock expuesto públicamente tiene la UI de Swagger en:

  https://flutter-prueba-backend.onrender.com/api

  Allí puedes explorar todos los endpoints (`/auth`, `/movimientos`, etc.), ver los modelos y probar peticiones desde el navegador.

Stack y decisiones clave
- Flutter (stable)
- State management: BLoC (`flutter_bloc`). Justificación: separación UI / lógica de negocio, testabilidad y compatibilidad con flujos por eventos (paginación, refresh, sync).
- Offline storage: SQLite via `sqflite` y capa `DBProvider` + `MovementRepository` con upsert desde servidor y colas de sync.
- API client: `Dio` con interceptor que inyecta `Authorization` (access token) y reintenta con `refresh_token` ante 401.

Estructura principal del proyecto
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
  unit/                    # tests unitarios
  widget/                  # widget tests
flutter_prueba_backend/    # mock API (NestJS)
```

Cómo ejecutar (FRONT)

# ⚠️ Importante

**DEBES INGRESAR A ESTE LINK PARA QUE RENDER INICIALICE:**  
https://flutter-prueba-backend.onrender.com/api

1. Asegúrate de tener Flutter SDK instalado y actualizado.
2. En la carpeta del proyecto Flutter:

```powershell
flutter pub get
```

3. Configura la URL del backend en `.env` (archivo en la raíz del proyecto Flutter):

```
BASE_URL=https://flutter-prueba-backend.onrender.com
```

4. Ejecuta la app en un emulador/dispositivo:

```powershell
flutter run
```

5. Ejecuta tests:

```powershell
flutter test --coverage
flutter analyze
```

Notas sobre el uso de Swagger y el backend
- Desde la app, `ApiService` se inicializa con `BASE_URL` tomado del archivo `.env` (si existe), por eso puedes apuntar la app a la URL pública del backend (`https://flutter-prueba-backend.onrender.com`) para probarla sin ejecutar el backend localmente.
- Para desarrollo local: ejecuta el backend en `localhost:3000` y coloca `BASE_URL=http://localhost:3000` en `.env`.

Requisitos y entregables
- Código fuente con historial de commits (local o remoto).
- README (este)
- Evidencia de ejecución: tests, capturas o video (agregar al paquete de entrega).

Mejoras sugeridas
- Migrar a ISAR para almacenamiento offline si buscas mayor rendimiento y consultas más complejas.
- Añadir tests de integración que levanten el backend mock y la app para validar flujos E2E.

Contacto
Si necesitas que incluya capturas de pantalla, un breve video de demostración o un archivo ZIP con el historial de commits, lo genero y lo subo según me indiques.
