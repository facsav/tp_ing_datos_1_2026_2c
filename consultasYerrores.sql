-- ==========================================================================
-- SECCION 08_consultas
-- ==========================================================================
USE tpDatos;
GO

SELECT v.patente,
       v.marca,
       v.modelo,
       v.anio,
       CONCAT(c.nombre, ' ', c.apellido) AS dueno
FROM vehiculos v
INNER JOIN cliente c ON c.id_cliente = v.id_cliente
ORDER BY c.apellido, c.nombre, v.patente;
GO

SELECT c.id_cliente,
       CONCAT(c.nombre, ' ', c.apellido) AS cliente,
       COUNT(v.patente)                  AS vehiculos
FROM cliente c
LEFT JOIN vehiculos v ON v.id_cliente = c.id_cliente
GROUP BY c.id_cliente, c.nombre, c.apellido
ORDER BY vehiculos DESC, c.apellido;
GO

SELECT patente, marca, modelo, anio
FROM vehiculos
WHERE anio < 2018
   OR anio IS NULL
ORDER BY anio;
GO

SELECT o.id_orden_trabajo,
       o.estado,
       o.fecha_ingreso,
       v.patente,
       v.marca,
       v.modelo,
       CONCAT(c.nombre, ' ', c.apellido) AS cliente,
       g.nombre                          AS grupo
FROM orden_de_trabajo o
INNER JOIN vehiculos v          ON v.patente = o.patente
INNER JOIN cliente c            ON c.id_cliente = v.id_cliente
LEFT JOIN grupos_de_trabajo g   ON g.id_grupo_de_trabajo = o.id_grupo_de_trabajo
WHERE o.estado IN ('Pendiente', 'En progreso')
ORDER BY o.fecha_ingreso;
GO

SELECT s.id_orden_trabajo,
       s.patente,
       s.estado,
       s.total,
       s.cobrado,
       s.saldo
FROM vw_saldo_ordenes s
WHERE s.saldo > 0
ORDER BY s.saldo DESC;
GO

SELECT s.tipo,
       COUNT(*)       AS veces,
       SUM(os.precio) AS facturado,
       AVG(os.precio) AS precio_promedio
FROM orden_servicio os
INNER JOIN servicios s ON s.id_servicio = os.id_servicio
GROUP BY s.id_servicio, s.tipo
ORDER BY facturado DESC;
GO

SELECT r.descripcion,
       SUM(orp.cantidad)                AS unidades,
       SUM(orp.cantidad * orp.precio)   AS facturado
FROM orden_repuesto orp
INNER JOIN repuestos r ON r.id_repuesto = orp.id_repuesto
GROUP BY r.id_repuesto, r.descripcion
HAVING SUM(orp.cantidad * orp.precio) >= 100000
ORDER BY facturado DESC;
GO

SELECT metodo_de_cobro,
       COUNT(*)   AS cobros,
       SUM(monto) AS total,
       AVG(monto) AS promedio,
       MIN(monto) AS minimo,
       MAX(monto) AS maximo
FROM cobros
GROUP BY metodo_de_cobro
ORDER BY total DESC;
GO

SELECT YEAR(fecha_cobro)  AS anio,
       MONTH(fecha_cobro) AS mes,
       COUNT(*)           AS cobros,
       SUM(monto)         AS ingresos
FROM cobros
GROUP BY YEAR(fecha_cobro), MONTH(fecha_cobro)
HAVING SUM(monto) > 300000
ORDER BY anio, mes;
GO

SELECT c.id_cliente,
       CONCAT(c.nombre, ' ', c.apellido)              AS cliente,
       COUNT(o.id_orden_trabajo)                      AS ordenes,
       SUM(dbo.fn_total_orden(o.id_orden_trabajo))    AS total_facturado
FROM cliente c
INNER JOIN vehiculos v        ON v.id_cliente = c.id_cliente
INNER JOIN orden_de_trabajo o ON o.patente = v.patente
GROUP BY c.id_cliente, c.nombre, c.apellido
HAVING SUM(dbo.fn_total_orden(o.id_orden_trabajo)) > 170000
ORDER BY total_facturado DESC;
GO

SELECT g.nombre                  AS grupo,
       COUNT(eg.id_mecanico)     AS integrantes
FROM grupos_de_trabajo g
LEFT JOIN empleados_grupos eg ON eg.id_grupo_de_trabajo = g.id_grupo_de_trabajo
GROUP BY g.id_grupo_de_trabajo, g.nombre
ORDER BY integrantes DESC, g.nombre;
GO

SELECT g.nombre                                                                AS grupo,
       COUNT(*)                                                                AS terminadas,
       AVG(CAST(DATEDIFF(DAY, o.fecha_ingreso, o.fecha_fin) AS DECIMAL(10,2))) AS dias_promedio,
       MAX(DATEDIFF(DAY, o.fecha_ingreso, o.fecha_fin))                        AS dias_maximo
FROM orden_de_trabajo o
INNER JOIN grupos_de_trabajo g ON g.id_grupo_de_trabajo = o.id_grupo_de_trabajo
WHERE o.estado = 'Terminado'
GROUP BY g.id_grupo_de_trabajo, g.nombre
ORDER BY dias_promedio DESC, g.nombre;
GO

SELECT os.id_orden_trabajo,
       s.tipo,
       os.precio            AS precio_cobrado,
       s.precio             AS precio_lista,
       s.precio - os.precio AS diferencia
FROM orden_servicio os
INNER JOIN servicios s ON s.id_servicio = os.id_servicio
WHERE os.precio <> s.precio
ORDER BY os.id_orden_trabajo;
GO

SELECT id_repuesto,
       descripcion,
       stock,
       stock_minimo,
       faltante,
       proveedor
FROM vw_stock_critico
ORDER BY faltante DESC;
GO

SELECT pr.nombre   AS proveedor,
       COUNT(*)    AS pedidos_impagos,
       SUM(sp.saldo) AS deuda
FROM vw_saldo_pedidos sp
INNER JOIN repuestos r     ON r.id_repuesto = sp.id_repuesto
INNER JOIN proveedores pr  ON pr.id_proveedor = r.id_proveedor
WHERE sp.estado_pago = 'Pendiente de pago'
GROUP BY pr.id_proveedor, pr.nombre
HAVING SUM(sp.saldo) > 0
ORDER BY deuda DESC;
GO

SELECT tipo, precio
FROM servicios
WHERE precio > (SELECT AVG(CAST(precio AS DECIMAL(12,2)))
                FROM servicios)
ORDER BY precio DESC;
GO

SELECT r.id_repuesto, r.descripcion, r.stock, r.precio
FROM repuestos r
WHERE r.id_repuesto NOT IN (SELECT orp.id_repuesto
                            FROM orden_repuesto orp)
ORDER BY r.descripcion;
GO

SELECT c.id_cliente, c.nombre, c.apellido, c.telefono
FROM cliente c
WHERE NOT EXISTS (SELECT 1
                  FROM vehiculos v
                  INNER JOIN orden_de_trabajo o ON o.patente = v.patente
                  WHERE v.id_cliente = c.id_cliente)
ORDER BY c.apellido;
GO

SELECT p.id_proveedor, p.nombre, p.telefono, p.localidad
FROM proveedores p
WHERE p.id_proveedor IN (SELECT r.id_proveedor
                         FROM repuestos r
                         WHERE r.stock < r.stock_minimo)
ORDER BY p.nombre;
GO

SELECT p.nombre AS proveedor, r.descripcion, r.precio
FROM repuestos r
INNER JOIN proveedores p ON p.id_proveedor = r.id_proveedor
WHERE r.precio = (SELECT MAX(r2.precio)
                  FROM repuestos r2
                  WHERE r2.id_proveedor = r.id_proveedor)
ORDER BY p.nombre;
GO

SELECT o.id_orden_trabajo,
       o.patente,
       o.estado,
       dbo.fn_total_orden(o.id_orden_trabajo) AS total
FROM orden_de_trabajo o
WHERE dbo.fn_total_orden(o.id_orden_trabajo) > (SELECT AVG(CAST(dbo.fn_total_orden(x.id_orden_trabajo) AS DECIMAL(12,2)))
                                                FROM orden_de_trabajo x)
ORDER BY total DESC;
GO

SELECT m.id_mecanico,
       m.nombre,
       m.apellido,
       (SELECT COUNT(*)
        FROM empleados_grupos eg
        WHERE eg.id_mecanico = m.id_mecanico) AS grupos
FROM mecanicos m
WHERE (SELECT COUNT(*)
       FROM empleados_grupos eg
       WHERE eg.id_mecanico = m.id_mecanico) > 1
ORDER BY m.apellido;
GO

SELECT t.id_cliente, t.cliente, t.total
FROM (SELECT c.id_cliente,
             CONCAT(c.nombre, ' ', c.apellido)            AS cliente,
             SUM(dbo.fn_total_orden(o.id_orden_trabajo))  AS total
      FROM cliente c
      INNER JOIN vehiculos v        ON v.id_cliente = c.id_cliente
      INNER JOIN orden_de_trabajo o ON o.patente = v.patente
      GROUP BY c.id_cliente, c.nombre, c.apellido) t
WHERE t.total > (SELECT AVG(CAST(g.total AS DECIMAL(14,2)))
                 FROM (SELECT SUM(dbo.fn_total_orden(o2.id_orden_trabajo)) AS total
                       FROM vehiculos v2
                       INNER JOIN orden_de_trabajo o2 ON o2.patente = v2.patente
                       GROUP BY v2.id_cliente) g)
ORDER BY t.total DESC;
GO

SELECT o.id_orden_trabajo,
       o.estado,
       dbo.fn_total_orden(o.id_orden_trabajo) AS total,
       dbo.fn_saldo_orden(o.id_orden_trabajo) AS saldo
FROM orden_de_trabajo o
ORDER BY o.id_orden_trabajo;
GO

SELECT id_mecanico, nombre, apellido, telefono
FROM vw_mecanicos_publico
ORDER BY apellido, nombre;
GO

SELECT id_pedido,
       estado_pedido,
       total,
       cantidad_pagos,
       pagado,
       saldo,
       estado_pago
FROM vw_saldo_pedidos
ORDER BY id_pedido;
GO

EXEC dbo.sp_control_faltantes;
GO

-- ==========================================================================
-- SECCION 09_pruebas_error
-- ==========================================================================
USE tpDatos;
GO

IF OBJECT_ID('tempdb..#resultados') IS NOT NULL DROP TABLE #resultados;

CREATE TABLE #resultados (
    id           INT IDENTITY(1,1) PRIMARY KEY,
    prueba       VARCHAR(150) NOT NULL,
    esperado     INT NULL,
    esperado_alt INT NULL,
    obtenido     INT NULL,
    mensaje      NVARCHAR(4000) NULL
);
GO

DECLARE @prueba VARCHAR(150), @esperado INT, @alt INT;
DECLARE @c INT, @o INT, @p INT, @n INT, @txt VARCHAR(10);

SET @alt = NULL;

PRINT 'SECCION 1 - Datos invalidos y violaciones de restricciones';

SET @prueba = 'T01 Patente con formato incorrecto (RN-03)'; SET @esperado = 547;
BEGIN TRY
    INSERT INTO vehiculos (patente, marca, modelo, anio, id_cliente) VALUES ('abc123', 'Fiat', 'Uno', 2000, 1);
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido) VALUES (@prueba, @esperado, @alt, 0);
END TRY
BEGIN CATCH
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido, mensaje) VALUES (@prueba, @esperado, @alt, ERROR_NUMBER(), ERROR_MESSAGE());
END CATCH;

SET @prueba = 'T02 Año fuera de rango (RN-04)'; SET @esperado = 547;
BEGIN TRY
    INSERT INTO vehiculos (patente, marca, modelo, anio, id_cliente) VALUES ('ZZ999ZZ', 'Fiat', 'Uno', 1900, 1);
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido) VALUES (@prueba, @esperado, @alt, 0);
END TRY
BEGIN CATCH
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido, mensaje) VALUES (@prueba, @esperado, @alt, ERROR_NUMBER(), ERROR_MESSAGE());
END CATCH;

SET @prueba = 'T03 Vehículo sin dueño (RN-01)'; SET @esperado = 515;
BEGIN TRY
    INSERT INTO vehiculos (patente, marca, modelo, anio, id_cliente) VALUES ('ZZ999ZZ', 'Fiat', 'Uno', 2000, NULL);
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido) VALUES (@prueba, @esperado, @alt, 0);
END TRY
BEGIN CATCH
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido, mensaje) VALUES (@prueba, @esperado, @alt, ERROR_NUMBER(), ERROR_MESSAGE());
END CATCH;

SET @prueba = 'T04 Patente duplicada (clave primaria)'; SET @esperado = 2627;
BEGIN TRY
    INSERT INTO vehiculos (patente, marca, modelo, anio, id_cliente) VALUES ('AB123CD', 'Fiat', 'Uno', 2000, 1);
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido) VALUES (@prueba, @esperado, @alt, 0);
END TRY
BEGIN CATCH
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido, mensaje) VALUES (@prueba, @esperado, @alt, ERROR_NUMBER(), ERROR_MESSAGE());
END CATCH;

SET @prueba = 'T05 Vehículo con cliente inexistente (clave foránea)'; SET @esperado = 547;
BEGIN TRY
    INSERT INTO vehiculos (patente, marca, modelo, anio, id_cliente) VALUES ('ZZ999ZZ', 'Fiat', 'Uno', 2000, 999);
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido) VALUES (@prueba, @esperado, @alt, 0);
END TRY
BEGIN CATCH
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido, mensaje) VALUES (@prueba, @esperado, @alt, ERROR_NUMBER(), ERROR_MESSAGE());
END CATCH;

SET @prueba = 'T06 Borrar un cliente que tiene vehículos (RN-05)'; SET @esperado = 547;
BEGIN TRY
    DELETE FROM cliente WHERE id_cliente = 1;
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido) VALUES (@prueba, @esperado, @alt, 0);
END TRY
BEGIN CATCH
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido, mensaje) VALUES (@prueba, @esperado, @alt, ERROR_NUMBER(), ERROR_MESSAGE());
END CATCH;

SET @prueba = 'T07 Servicio con tipo repetido (RN-06)'; SET @esperado = 2627;
BEGIN TRY
    INSERT INTO servicios (tipo, precio) VALUES ('Cambio de batería', 1000);
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido) VALUES (@prueba, @esperado, @alt, 0);
END TRY
BEGIN CATCH
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido, mensaje) VALUES (@prueba, @esperado, @alt, ERROR_NUMBER(), ERROR_MESSAGE());
END CATCH;

SET @prueba = 'T08 Servicio con precio negativo (RN-06)'; SET @esperado = 547;
BEGIN TRY
    INSERT INTO servicios (tipo, precio) VALUES ('Servicio nuevo', -1);
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido) VALUES (@prueba, @esperado, @alt, 0);
END TRY
BEGIN CATCH
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido, mensaje) VALUES (@prueba, @esperado, @alt, ERROR_NUMBER(), ERROR_MESSAGE());
END CATCH;

SET @prueba = 'T09 Repuesto con precio negativo (RN-07)'; SET @esperado = 547;
BEGIN TRY
    INSERT INTO repuestos (descripcion, precio, stock, id_proveedor) VALUES ('Repuesto nuevo', -5, 1, 1);
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido) VALUES (@prueba, @esperado, @alt, 0);
END TRY
BEGIN CATCH
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido, mensaje) VALUES (@prueba, @esperado, @alt, ERROR_NUMBER(), ERROR_MESSAGE());
END CATCH;

SET @prueba = 'T10 Stock negativo (RN-07)'; SET @esperado = 547;
BEGIN TRY
    UPDATE repuestos SET stock = -1 WHERE id_repuesto = 1;
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido) VALUES (@prueba, @esperado, @alt, 0);
END TRY
BEGIN CATCH
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido, mensaje) VALUES (@prueba, @esperado, @alt, ERROR_NUMBER(), ERROR_MESSAGE());
END CATCH;

SET @prueba = 'T11 Tipo de proveedor no permitido (RN-09)'; SET @esperado = 547;
BEGIN TRY
    INSERT INTO proveedores (nombre, tipoproveedor) VALUES ('Proveedor nuevo', 'Mayorista');
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido) VALUES (@prueba, @esperado, @alt, 0);
END TRY
BEGIN CATCH
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido, mensaje) VALUES (@prueba, @esperado, @alt, ERROR_NUMBER(), ERROR_MESSAGE());
END CATCH;

SET @prueba = 'T12 Proveedor con nombre repetido (RN-09)'; SET @esperado = 2627;
BEGIN TRY
    INSERT INTO proveedores (nombre, tipoproveedor) VALUES ('Autopartes del Sur', 'Repuestos');
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido) VALUES (@prueba, @esperado, @alt, 0);
END TRY
BEGIN CATCH
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido, mensaje) VALUES (@prueba, @esperado, @alt, ERROR_NUMBER(), ERROR_MESSAGE());
END CATCH;

SET @prueba = 'T13 Salario igual a cero (RN-14)'; SET @esperado = 547;
BEGIN TRY
    UPDATE mecanicos SET salariomensual = 0 WHERE id_mecanico = 2;
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido) VALUES (@prueba, @esperado, @alt, 0);
END TRY
BEGIN CATCH
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido, mensaje) VALUES (@prueba, @esperado, @alt, ERROR_NUMBER(), ERROR_MESSAGE());
END CATCH;

SET @prueba = 'T14 Mecánico repetido en el mismo grupo (RN-12)'; SET @esperado = 2627;
BEGIN TRY
    INSERT INTO empleados_grupos (id_mecanico, id_grupo_de_trabajo) VALUES (1, 1);
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido) VALUES (@prueba, @esperado, @alt, 0);
END TRY
BEGIN CATCH
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido, mensaje) VALUES (@prueba, @esperado, @alt, ERROR_NUMBER(), ERROR_MESSAGE());
END CATCH;

SET @prueba = 'T15 Grupo con nombre repetido (RN-13)'; SET @esperado = 2627;
BEGIN TRY
    INSERT INTO grupos_de_trabajo (nombre) VALUES ('Motor');
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido) VALUES (@prueba, @esperado, @alt, 0);
END TRY
BEGIN CATCH
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido, mensaje) VALUES (@prueba, @esperado, @alt, ERROR_NUMBER(), ERROR_MESSAGE());
END CATCH;

SET @prueba = 'T16 Repuesto sin proveedor (RN-08)'; SET @esperado = 515;
BEGIN TRY
    INSERT INTO repuestos (descripcion, precio, id_proveedor) VALUES ('Repuesto sin proveedor', 100, NULL);
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido) VALUES (@prueba, @esperado, @alt, 0);
END TRY
BEGIN CATCH
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido, mensaje) VALUES (@prueba, @esperado, @alt, ERROR_NUMBER(), ERROR_MESSAGE());
END CATCH;

SET @prueba = 'T17 Estado de orden no permitido (RN-17)'; SET @esperado = 547;
BEGIN TRY
    INSERT INTO orden_de_trabajo (patente, estado) VALUES ('AB123CD', 'Cerrado');
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido) VALUES (@prueba, @esperado, @alt, 0);
END TRY
BEGIN CATCH
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido, mensaje) VALUES (@prueba, @esperado, @alt, ERROR_NUMBER(), ERROR_MESSAGE());
END CATCH;

SET @prueba = 'T18 Orden En progreso sin grupo (RN-18)'; SET @esperado = 547;
BEGIN TRY
    UPDATE orden_de_trabajo SET estado = 'En progreso' WHERE id_orden_trabajo = 5;
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido) VALUES (@prueba, @esperado, @alt, 0);
END TRY
BEGIN CATCH
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido, mensaje) VALUES (@prueba, @esperado, @alt, ERROR_NUMBER(), ERROR_MESSAGE());
END CATCH;

SET @prueba = 'T19 Orden Terminado sin fecha de fin (RN-19)'; SET @esperado = 547;
BEGIN TRY
    UPDATE orden_de_trabajo SET estado = 'Terminado', id_grupo_de_trabajo = 1 WHERE id_orden_trabajo = 5;
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido) VALUES (@prueba, @esperado, @alt, 0);
END TRY
BEGIN CATCH
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido, mensaje) VALUES (@prueba, @esperado, @alt, ERROR_NUMBER(), ERROR_MESSAGE());
END CATCH;

SET @prueba = 'T20 Fecha de fin anterior al ingreso (RN-19)'; SET @esperado = 547;
BEGIN TRY
    INSERT INTO orden_de_trabajo (patente, id_grupo_de_trabajo, estado, fecha_ingreso, fecha_fin)
    VALUES ('AB123CD', 1, 'Terminado', '2026-10-10', '2026-10-01');
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido) VALUES (@prueba, @esperado, @alt, 0);
END TRY
BEGIN CATCH
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido, mensaje) VALUES (@prueba, @esperado, @alt, ERROR_NUMBER(), ERROR_MESSAGE());
END CATCH;

SET @prueba = 'T21 Orden sobre un vehículo inexistente (RN-16)'; SET @esperado = 547;
BEGIN TRY
    INSERT INTO orden_de_trabajo (patente) VALUES ('ZZ000ZZ');
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido) VALUES (@prueba, @esperado, @alt, 0);
END TRY
BEGIN CATCH
    INSERT INTO #resultados (prueba, esperado, esperado_alt, obtenido, mensaje) VALUES (@prueba, @esperado, @alt, ERROR_NUMBER(), ERROR_MESSAGE());
END CATCH;
