# Roadmap de Silvalde Web

Plan de fases del proyecto y referencia de control. Cada fase terminada e
integrada en `main` publica una versión (ver [versioning.md](./versioning.md)).
Este documento se actualiza conforme avanza el proyecto.

El desglose fino en **slices** está en [`backend-plan.md`](./backend-plan.md).
Las decisiones ya tomadas con su porqué están en `AGENTS.full.md`
(«Decisiones de stack»).

Leyenda: ✅ hecho · 🚧 en curso · ⬜ pendiente · ❓ decisión abierta

---

## La primera versión de la web (objetivo: v1.0.0)

Silvalde es una tienda de decoración con **dos tiendas físicas en la
provincia de A Coruña: Bertamirans y Noia**. La web vende online y aprovecha
esas tiendas para la recogida.

### Lo que podrá hacer una clienta

- Usar la web en **español, gallego o inglés**. ✅
- Ver el **catálogo** por categorías, con fotos, precios (IVA incluido),
  variantes y disponibilidad, y **buscar** productos. ✅
- **Registrarse**, iniciar/cerrar sesión y recuperar la contraseña. ✅
- Tener un **carrito**, con o sin cuenta. ✅
- **Hacer un pedido con o sin cuenta** (como invitada, con su email).
- Elegir la **entrega**: **recogida en tienda** (Bertamirans o Noia, gratis)
  o **envío a domicilio** (con coste de envío).
- Elegir cómo **pagar**: **tarjeta** (Stripe), **PayPal**,
  **transferencia o Bizum** (la tienda confirma el cobro) o **en la tienda al
  recoger**.
- Ver el **estado de sus pedidos** (en «Mis pedidos» o, sin cuenta, con el
  enlace del email) y recibir emails de confirmación y de cambio de estado.
- Elegir si quiere recibir **ofertas** (consentimiento explícito y
  revocable). ✅
- **Borrar su cuenta** y sus datos personales (RGPD).

### Lo que podrá hacer la tienda

- Entrar a un **panel `/admin` protegido por rol**.
- Gestionar **productos, pedidos y usuarias**: confirmar pagos por
  transferencia/Bizum, preparar, enviar o marcar como recogido, cancelar.
- Imprimir el **justificante del pedido** (no es una factura fiscal).
- Ver **métricas básicas** y la versión de la app.

### Lo que NO entra en la v1.0.0

Cada punto necesita su propia especificación antes de implementarse:

- **Facturación fiscal** (facturas con numeración legal, Verifactu…):
  consultar antes con la gestoría qué exige.
- **Bizum integrado** en el pago online (requiere el TPV del banco, Redsys).
  En la v1.0.0, Bizum funciona como la transferencia: la clienta lo envía y
  la tienda confirma el cobro.
- **Campañas de marketing** (el consentimiento ya se guarda).
- Integración con transportistas (etiquetas y seguimiento automáticos), ERP
  o redes sociales.
- **Stock por tienda** (Bertamirans y Noia por separado): de momento hay un
  único stock por variante.

---

## Fases publicadas

### ✅ v0.1.0 — Base del proyecto

Estructura Rails 8.1, documentación del proyecto y de agentes, versionado y
flujo de trabajo con git. Publicada el 2026-10-11 con el tag `v0.1.0`.

### ✅ v0.2.0 — Autenticación y usuarios

Registro, inicio/cierre de sesión y recuperación de contraseña; roles
`customer`/`admin`; perfil de cliente; consentimiento de comunicaciones.
Construida por slices pequeños (11 slices, 103 specs en verde). Publicada el
2026-10-24 con el tag `v0.2.0`.

### ✅ v0.3.0 — Catálogo

Categorías y productos con variantes, imágenes y disponibilidad; navegación
pública por categorías y búsqueda; landing como portada con productos
destacados, ofertas y galería de fotos. Modelos `Catalog::Category`,
`Catalog::Product` y `Catalog::Variant` (precios en céntimos, disponibilidad
por stock de la variante), imágenes con Active Storage, `Catalog::Search`,
vistas públicas con Tailwind, accesibilidad WCAG 2.2 AA y base de SEO en
página. Publicada el 2026-11-01 con el tag `v0.3.0`.

### ✅ v0.4.0 — Carrito

Carrito para visitantes y clientas registradas, con cantidades y variantes,
que sobrevive al iniciar sesión. Modelos `Carts::Cart` y `Carts::CartItem`
(precio congelado al añadir), consultas en `Carts::Search` y caducidad a los
6 meses de inactividad con purge recurrente silencioso. Carrito de invitada
en la sesión, UI con Turbo Frames (ficha de producto, contador del header y
página `/cart`) y fusión al login sumando cantidades. Endurecida antes de
publicar: reintento ante carreras, validación de cantidades, memoización de
`current_cart`, system spec, cops de arquitectura y Rails 8.1.4.1. Publicada
el 2026-11-10 con el tag `v0.4.0`.

### 🚧 v0.4.1 — Endurecimiento

Arreglos de la auditoría completa con `/project-review full`: reset de
contraseña en blanco, límite de intentos en login/registro/reset, contraseña
para cambiar el email, HTTPS y dominio en producción, fusión de carritos,
ofertas, mensajes de validación en los dos idiomas, purga de sesiones y
otros detalles (ver `CHANGELOG.md`). PR #25; se publica con el tag
`v0.4.1` al mergearlo.

---

## Fases pendientes

El orden importa: cada fase deja algo usable y no depende de las
siguientes. Los pagos online van después de la puesta en producción porque
necesitan una URL pública real (los avisos de pago de Stripe y PayPal llegan
por webhook).

### ⬜ v0.5.0 — Pedidos (checkout con recogida en tienda y pago offline)

**Qué se hace:** la clienta, con o sin cuenta, convierte su carrito en un
pedido para **recoger en Bertamirans o Noia**, pagando **por
transferencia/Bizum** o **al recoger**. Ve su pedido y recibe el email de
confirmación.

**Cómo se hará:**

- **Modelos `Orders::Order` y `Orders::OrderItem`**, con los precios
  congelados al comprar (como en el carrito) y los datos de contacto
  (nombre, email, teléfono). Una invitada compra con su email; si tiene
  cuenta, el pedido queda en su cuenta.
- **Número de pedido público** (p. ej. `SV-7K3Q9P`), no el id de la base de
  datos: el id es consecutivo y dejaría adivinar cuántos pedidos hay o
  probar los de otras.
- **Máquina de estados con AASM** (decisión tomada; ver «Por qué AASM» más
  abajo). Estados del pedido (lo que pasa con el paquete):
  `pending` (recibido) → `confirmed` (pago confirmado o pago al recoger) →
  `ready_for_pickup` → `picked_up`; desde `pending` o `confirmed` se puede
  ir a `cancelled`. La v0.7.0 añade la rama de envío (`shipped` →
  `delivered`). Cada transición queda registrada (quién y cuándo).
- **Pago separado del pedido:** un atributo `payment_method`
  (`bank_transfer`, `pay_in_store` y, desde la v0.9.0 «Pagos», `card`, `paypal`) y un
  `payment_status` (`pending`, `paid`, `refunded`). Así, un pedido puede
  estar «listo para recoger» y «pendiente de pago» a la vez (pago al
  recoger) sin inventar estados mezclados.
- **Servicio de checkout en una transacción:** valida el carrito, bloquea
  las filas de las variantes (`with_lock`), comprueba y descuenta el stock,
  crea el pedido y vacía el carrito; si algo falla, no se guarda nada. Dos
  personas no pueden comprar la última unidad a la vez. Si no hay stock
  suficiente, la clienta vuelve al carrito con un mensaje claro de qué línea
  falla.
- **Restricciones en la base de datos** (CHECK): `stock >= 0`, cantidades
  entre 1 y 999 y precios `>= 0`. Las validaciones de Ruby no bastan ante
  carreras.
- **Cancelar devuelve el stock** (en la misma transacción).
- **IVA incluido**: los precios del catálogo ya incluyen el IVA. El
  checkout y el email lo indican («IVA incluido»).
- **Condiciones de venta**: la clienta las acepta en el checkout (casilla
  obligatoria) y se guarda qué versión aceptó y cuándo. El texto legal llega
  en la v1.0.0; aquí va el mecanismo con un texto provisional.
- **Ver el pedido:** con cuenta, en «Mis pedidos»; sin cuenta, con un
  enlace firmado que llega en el email (sin login).
- **Emails** con Action Mailer: confirmación del pedido y cambios de
  estado. En desarrollo se ven con las previews de Rails; el envío real
  necesita el SMTP de la v0.8.0.
- **Datos de la transferencia/Bizum** (IBAN, número de Bizum) en la
  configuración, no en el código.

**A tener en cuenta:** la FK `cart_items.variant_id` impide borrar una
variante que esté en algún carrito, y ahora también en pedidos. Se resuelve
en la v0.6.0 archivando productos en vez de borrarlos.

### ⬜ v0.6.0 — Panel de administración

**Qué se hace:** la tienda gestiona el día a día sin consola: pedidos,
productos y usuarias.

**Cómo se hará:**

- Rutas bajo `/admin` con un `before_action` que exige rol `admin` **en
  servidor** (ocultar botones nunca es autorizar). Pundit solo si los
  permisos se vuelven más finos (decidir aquí).
- **Primer admin** con una tarea `bin/rails admin:create` que pide el email
  (nunca con contraseñas en los seeds).
- **Pedidos:** listado con filtros por estado y tienda; acciones según el
  estado (confirmar pago, listo para recoger, recogido, cancelar), cada una
  con su transición de AASM. **Justificante del pedido** imprimible.
- **Productos:** crear, editar, fotos, variantes y stock. **Archivar** en
  lugar de borrar (`archived_at`): un producto archivado desaparece de la
  tienda, pero los pedidos antiguos lo siguen mostrando.
- **Usuarias:** listado, rol y bloqueo.
- **Métricas básicas:** ventas por periodo, pedidos por estado y productos
  más vendidos. La versión de la app en el pie del panel.

### ⬜ v0.7.0 — Envío a domicilio

**Qué se hace:** además de recoger en tienda, la clienta puede pedir que se
lo envíen a casa.

**Cómo se hará:**

- **Dirección de envío** en el checkout (y libreta de direcciones para quien
  tiene cuenta).
- **Coste de envío** según una tabla sencilla (p. ej. por zona y tramo de
  importe, con envío gratis a partir de cierta cantidad), editable desde el
  admin.
- La rama de estados `confirmed → shipped → delivered`, con el número de
  seguimiento del transportista escrito a mano en el admin y enviado por
  email.
- ❓ **Decidir:** zonas a las que se envía (solo España peninsular, islas…),
  tarifas y transportista.

### ⬜ v0.8.0 — Puesta en producción

**Qué se hace:** la web funciona en internet con su dominio, aunque todavía
solo con pagos offline. Ver «Guía de despliegue» abajo.

**Cómo se hará:**

- **Servidor:** un VPS (servidor virtual) con **Kamal**, que Rails 8 ya trae
  configurado (`config/deploy.yml`).
- **Dominio y HTTPS:** el dominio apunta al VPS y `kamal-proxy` pide y
  renueva el certificado gratis (Let's Encrypt). La app ya fuerza HTTPS desde
  la v0.4.1.
- **Base de datos MySQL** en el VPS (como accessory de Kamal) con **copias de
  seguridad automáticas diarias fuera del servidor y una restauración
  probada**.
- **Fotos de producto** en un almacenamiento externo compatible con S3 (o en
  disco con copia de seguridad), y **tamaños de imagen** optimizados
  (`ruby-vips` + variantes de Active Storage) en lugar de servir originales
  de hasta 5 MB.
- **Email transaccional** con un proveedor (SMTP), dominio verificado
  (SPF, DKIM y DMARC) para que no acabe en spam. La app ya lee `SMTP_*`
  desde la v0.4.1.
- **Monitorización:** aviso de errores (un servicio de seguimiento de
  errores), aviso si la web cae (monitor de `/up`) y aviso de jobs fallidos
  (emails que no salen).
- **Migraciones en producción:** proceso escrito (copia antes de migrar,
  migración, comprobación y cómo volver atrás). Hasta tenerlo, sigue
  prohibido tocar la base de producción a mano.
- **Despliegue desde GitHub Actions** cuando el CI pasa en `main`, y un
  **entorno de staging** para probar antes.
- ❓ **Decidir:** proveedor del VPS, dominio, proveedor de email y de copias.

### ⬜ v0.9.0 — Pagos

**Qué se hace:** pagar el pedido **online** con **tarjeta (Stripe)** o
**PayPal**, además de los métodos offline de la v0.5.0 (transferencia/Bizum y
pago en tienda), y devolver el dinero cuando se cancela un pedido pagado.

**Conceptos, para quien no lo ha hecho nunca:**

- **Pasarela de pago:** una empresa que cobra por ti (Stripe, PayPal, el TPV
  de un banco). Tu web nunca ve ni guarda el número de la tarjeta: lo recoge
  la pasarela en su página. Por eso no tienes que certificar tu servidor con
  la normativa de tarjetas (PCI DSS); la pasarela ya lo está.
- **Stripe:** la pasarela más usada por tiendas online pequeñas y medianas.
  Cobra una comisión por cada pago (sin cuota fija). Acepta tarjetas, Apple
  Pay y Google Pay con la misma integración. Tiene un **modo de pruebas** con
  tarjetas falsas para desarrollar sin dinero real.
- **Stripe Checkout:** la página de pago que aloja Stripe. Tu web crea una
  «sesión de pago» con el importe y redirige a la clienta; al terminar,
  Stripe la devuelve a tu web.
- **PayPal:** la clienta paga con su cuenta de PayPal (o con tarjeta a
  través de PayPal). Funciona igual: crear el pago, redirigir y confirmar.
- **Webhook:** una llamada que la pasarela hace **a tu servidor** para
  avisar de que un pago se ha completado, ha fallado o se ha devuelto. Es la
  única confirmación fiable: que la clienta vuelva a la página de «gracias»
  no prueba nada (se puede cerrar la pestaña antes o falsificar la URL).
- **Firma del webhook:** cada aviso viene firmado con una clave secreta; se
  comprueba la firma para saber que viene de verdad de Stripe o PayPal.
- **Idempotencia:** la pasarela puede repetir el mismo aviso. Procesarlo dos
  veces no debe cobrar, enviar emails ni cambiar el estado dos veces: se
  guarda el id del evento y se ignoran los repetidos.

**Cómo se hará:**

- **Modelo `Orders::Payment`** (un pedido puede tener varios intentos):
  método, importe en céntimos, estado (`pending`, `paid`, `failed`,
  `refunded`), id del pago en la pasarela y fecha. El `payment_status` del
  pedido se deriva de sus pagos.
- **Flujo con tarjeta:** checkout → se crea el pedido `pending` con el
  stock reservado → sesión de Stripe Checkout → la clienta paga → el webhook
  `checkout.session.completed` marca el pago como `paid` y el pedido pasa a
  `confirmed` → email de confirmación. Si vuelve sin pagar, el pedido sigue
  `pending` y puede reintentar.
- **Flujo con PayPal:** el mismo, con la API de pedidos de PayPal y su
  webhook de pago capturado.
- **Pedidos sin pagar caducan:** un job recurrente cancela los pedidos
  online `pending` con más de un tiempo (p. ej. 1 hora) y **devuelve el
  stock**, para que nadie bloquee unidades sin pagar.
- **Reembolsos** desde el admin: al cancelar un pedido pagado, se pide la
  devolución a la pasarela y el pago pasa a `refunded` cuando llega su
  webhook. Devoluciones parciales: ❓ decidir.
- **Seguridad:** el importe se calcula **siempre en el servidor** a partir
  del pedido, nunca con lo que mande el navegador; el webhook es la única
  ruta que da un pago por bueno; claves de las pasarelas en variables de
  entorno (`STRIPE_SECRET_KEY`, `STRIPE_WEBHOOK_SECRET`, `PAYPAL_*`); la ruta
  del webhook no usa CSRF (no viene de un formulario) pero sí la firma.
- **Pruebas:** specs con las respuestas de la pasarela simuladas (sin red),
  y pruebas a mano en modo test con la Stripe CLI, que reenvía los webhooks
  a tu PC antes de tener el servidor público.
- **Bizum integrado:** no entra (requiere el TPV del banco, Redsys). Bizum
  sigue como en la v0.5.0: la clienta lo envía y la tienda confirma el cobro.
- ❓ **Decidir:** cuenta de Stripe y de PayPal a nombre de la tienda (lo hace
  la dueña: datos fiscales y cuenta bancaria), si algún método tiene
  recargo y la política de devoluciones parciales.

### ⬜ v1.0.0 — Lanzamiento público

**Qué se hace:** todo lo necesario para abrir al público con garantías.

- **Legal:** aviso legal, política de privacidad, política de cookies,
  **condiciones de venta** definitivas y **derecho de desistimiento de 14
  días** (obligatorio en la venta online en la UE), con un formulario para
  ejercerlo. Revisado por quien lleve lo legal.
- **RGPD:** borrar la cuenta y los datos personales a petición, y
  exportarlos; los pedidos se conservan anonimizados el tiempo que exija la
  ley.
- **Cookies:** hoy solo hay cookies técnicas (sesión, carrito e idioma), que
  no necesitan banner. Si se añade analítica, entra el banner de
  consentimiento.
- **Seguridad:** Content Security Policy (primero en modo informe),
  revisión de cabeceras y review de versión completa.
- **Rendimiento y SEO:** paginación del catálogo y del sitemap, caché de las
  páginas públicas, imágenes optimizadas y comprobación en móvil.
- **Accesibilidad:** pasada completa WCAG 2.2 AA, también en el checkout y
  el admin.

---

## Por qué AASM para los pedidos

Un pedido pasa por estados (recibido, confirmado, listo, recogido,
cancelado…) y **no todos los saltos son válidos**: no se puede marcar como
recogido un pedido cancelado. AASM es una gema que define esos estados y
las transiciones permitidas en un solo sitio, y da métodos como
`order.confirm!` que fallan si el salto no está permitido.

- **Alternativa descartada: un `enum` de Rails a mano.** Sirve para
  guardar el estado, pero las reglas de qué salto vale acabarían repartidas
  por services y controllers, y es fácil que alguna se olvide.
- **Por qué encaja:** la decisión ya se tomó en la v0.2.0, es la gema más
  usada para esto en Rails y la conoces del trabajo.
- **Cómo se usa aquí:** AASM **solo valida y cambia el estado**. Los efectos
  (devolver stock, enviar el email, registrar quién lo hizo) van en los
  services de caso de uso (`Orders::Cancel`, `Orders::MarkReady`…), como el
  resto del proyecto, y no en callbacks de AASM, para que se puedan leer y
  probar.

## Guía de despliegue (para la v0.8.0)

Conceptos, en orden:

1. **VPS:** un ordenador en un centro de datos que alquilas por meses. Es
   tuyo: instalas lo que quieras. Para una tienda pequeña basta uno modesto.
2. **Docker:** empaqueta la app con todo lo que necesita (Ruby, gemas) en
   una **imagen**, que funciona igual en tu PC y en el servidor. El proyecto
   ya tiene `Dockerfile`.
3. **Kamal:** la herramienta de Rails 8 para desplegar esa imagen en el VPS
   con un comando (`kamal deploy`). Se encarga de arrancar la versión nueva,
   comprobar que responde en `/up` y apagar la vieja sin cortar el servicio.
4. **kamal-proxy:** el portero que recibe las visitas, gestiona el HTTPS y
   las pasa a la app.
5. **Accessories:** servicios que Kamal arranca junto a la app, como MySQL.
6. **Secretos:** contraseñas y claves que nunca van al repo; Kamal las lee
   de `.kamal/secrets` (que a su vez las toma de variables de entorno o de
   un gestor de contraseñas).

Cuando lleguemos a la v0.8.0, el agente lo hace contigo paso a paso: primero
en un VPS de pruebas, después el real.

---

## Cómo se trabaja cada fase (resumen del flujo)

1. Leer esta fase y su desglose en `backend-plan.md`; resolver las ❓.
2. El agente **propone el nombre de la rama** y espera el OK
   (`feat/<nombre>` desde `main`).
3. Antes de cada slice, el agente explica qué entra, qué no y cómo se prueba
   a mano, y espera el OK.
4. Cada slice: **TDD** (test en rojo, código, verde) → validaciones →
   propuesta de commit (Conventional Commits).
5. La review la lanza el usuario cuando quiere (`/project-review slice`); al
   cerrar la versión, el agente **recuerda** la review de versión
   (`/project-review version`).
6. `bin/ci` en verde, commit de publicación (`VERSION`, `CHANGELOG.md`,
   esta página) y **PR solo con el OK del usuario**.
7. Merge con su confirmación propia y, después, el **tag** `vX.Y.Z` sobre
   `main` (ver [versioning.md](./versioning.md)).

## Notas

- Las fases pueden solaparse, pero no se integra nada a medias en `main`.
- Los arreglos sin funcionalidad nueva salen como versión de parche
  (`0.4.1`); cada fase nueva sube el número del medio (`0.5.0`).
- Cualquier funcionalidad fuera de esta lista necesita antes su
  especificación (ver `AGENTS.full.md`, sección «Cambios y documentación»).
