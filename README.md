# API de ventas

Documentación para clientes que integran el servicio Express de ventas.

## Estado de las rutas

La aplicación monta el router con el prefijo `/api/v1/ventas`, y `routes/ventas.js` vuelve a declarar los prefijos completos dentro del router. Por tanto, según la configuración actual, las rutas efectivas son:

| Operación | Método | Ruta efectiva |
|---|---|---|
| Consultar ventas consolidadas | `GET` | `/api/v1/ventas/api/v1/ventas/consolidado` |
| Registrar una venta | `POST` | `/api/v1/ventas/api/v1/consolidado` |

La ruta GET requiere parámetros `sucursal` y `anio`. El POST espera `id_producto`, `id_cliente`, `cantidad` y `fecha_venta` en un cuerpo JSON.

> **Nota de integración:** hay dos detalles de implementación que afectan el consumo. `express.json()` se registra después de las rutas, por lo que el cuerpo JSON no se procesa antes del POST; actualmente la lectura de `req.body` puede producir una respuesta `500`. Además, el `POST` valida los campos con comprobaciones de valor truthy, así que `cantidad: 0` también se rechaza. Esta guía refleja el código actual; conviene corregir esos detalles y alinear los prefijos antes de publicar una URL estable a clientes.

## Base URL y ejecución

El servidor escucha en `http://localhost:3000` por defecto. Si se define `PORT`, escucha en ese puerto. En otro entorno, reemplaza `localhost:3000` por el host y puerto publicados por el despliegue.

Configura estas variables para la conexión MySQL (no incluyas credenciales en el cliente):

- `DB_HOST`
- `DB_USER`
- `DB_PASSWORD`
- `DB_NAME`
- `PORT` (opcional; por defecto `3000`)

La base de datos debe tener disponibles los procedimientos almacenados `db_ventas_tech` y `db_registrar_ventas`.

## Formato general

Las respuestas se envían como JSON. No se configura autenticación, versionado adicional, CORS ni una respuesta de salud en el código actual. Envía `Accept: application/json`; para el POST envía también `Content-Type: application/json`.

## Consultar ventas consolidadas

```http
GET /api/v1/ventas/api/v1/ventas/consolidado?sucursal={sucursal}&anio={anio}
Accept: application/json
```

| Parámetro | En | Requerido | Descripción |
|---|---|---|---|
| `sucursal` | query | Sí | Identificador o valor de sucursal que espera `db_ventas_tech`. |
| `anio` | query | Sí | Año que espera `db_ventas_tech`. |

Ejemplo:

```bash
curl --get 'http://localhost:3000/api/v1/ventas/api/v1/ventas/consolidado' \
  --data-urlencode 'sucursal=1' \
  --data-urlencode 'anio=2026' \
  --header 'Accept: application/json'
```

Respuesta `200` (los campos de cada elemento dependen del procedimiento almacenado):

```json
{
  "status": "success",
  "total_registros": 1,
  "data": [
    {}
  ]
}
```

Si falta uno o ambos parámetros, responde `400`:

```json
{
  "error": "Bad Request",
  "message": "Debe Enviar Ambos Parametros"
}
```

Si falla la consulta a MySQL, responde `500`:

```json
{
  "error": "Internal Server Error",
  "message": "Error En MySQL"
}
```

## Registrar una venta

```http
POST /api/v1/ventas/api/v1/consolidado
Content-Type: application/json
Accept: application/json
```

Cuerpo requerido:

| Campo | Tipo esperado | Requerido | Descripción |
|---|---|---|---|
| `id_producto` | Según el esquema de la base de datos | Sí | Identificador del producto. |
| `id_cliente` | Según el esquema de la base de datos | Sí | Identificador del cliente. |
| `cantidad` | Según el esquema de la base de datos | Sí | Cantidad vendida; debe ser truthy para pasar la validación actual. |
| `fecha_venta` | Según el esquema de la base de datos | Sí | Fecha que acepta el procedimiento almacenado. |

Ejemplo de cuerpo:

```json
{
  "id_producto": 10,
  "id_cliente": 25,
  "cantidad": 2,
  "fecha_venta": "2026-10-23"
}
```

Ejemplo de llamada:

```bash
curl --request POST 'http://localhost:3000/api/v1/ventas/api/v1/consolidado' \
  --header 'Content-Type: application/json' \
  --header 'Accept: application/json' \
  --data '{"id_producto":10,"id_cliente":25,"cantidad":2,"fecha_venta":"2026-10-23"}'
```

Cuando se registra correctamente, responde `201`:

```json
{
  "status": "success",
  "message": "Venta registrada exitosamente",
  "datos_registrados": {
    "id_producto": 10,
    "id_cliente": 25,
    "cantidad": 2,
    "fecha_venta": "2026-10-23"
  }
}
```

Si faltan campos, la ruta responde `400` con `{"error":"Bad request","message":"Todos los campos son obligatorios"}`. Si ocurre un error en la base de datos, responde `500` con `{"error":"Internal Server Error","message":"Error al registrar la venta en la base de datos"}`. Con la ubicación actual de `express.json()`, el POST puede responder `500` antes de alcanzar la validación.
