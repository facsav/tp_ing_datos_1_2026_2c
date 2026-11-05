-- ==========================================================================
-- SECCION 06_cursor_faltantes
-- ==========================================================================
USE tpDatos;
GO

CREATE PROCEDURE dbo.sp_control_faltantes
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @id_orden INT, @id_repuesto INT, @cantidad INT, @stock INT;

    BEGIN TRY
        BEGIN TRANSACTION;

        DELETE FROM alertas_stock;

        DECLARE cur_pendientes CURSOR LOCAL FOR
            SELECT orp.id_orden_trabajo, orp.id_repuesto, orp.cantidad, r.stock
            FROM orden_repuesto orp
            INNER JOIN orden_de_trabajo o ON o.id_orden_trabajo = orp.id_orden_trabajo
            INNER JOIN repuestos r        ON r.id_repuesto = orp.id_repuesto
            WHERE o.estado = 'Pendiente';

        OPEN cur_pendientes;
        FETCH NEXT FROM cur_pendientes INTO @id_orden, @id_repuesto, @cantidad, @stock;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            IF @stock < @cantidad
                INSERT INTO alertas_stock (id_orden_trabajo, id_repuesto, requerido, disponible)
                VALUES (@id_orden, @id_repuesto, @cantidad, @stock);

            FETCH NEXT FROM cur_pendientes INTO @id_orden, @id_repuesto, @cantidad, @stock;
        END;

        CLOSE cur_pendientes;
        DEALLOCATE cur_pendientes;

        COMMIT TRANSACTION;

        SELECT id_repuesto, descripcion, stock, stock_minimo, faltante, proveedor
        FROM vw_stock_critico
        ORDER BY faltante DESC;

        SELECT a.id_orden_trabajo, o.patente, r.descripcion AS repuesto, a.requerido, a.disponible
        FROM alertas_stock a
        INNER JOIN orden_de_trabajo o ON o.id_orden_trabajo = a.id_orden_trabajo
        INNER JOIN repuestos r        ON r.id_repuesto = a.id_repuesto
        ORDER BY a.id_orden_trabajo;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

-- ==========================================================================
-- SECCION 07_seguridad
-- ==========================================================================
USE tpDatos;
GO

DROP USER IF EXISTS usr_admin;
DROP USER IF EXISTS usr_recepcion;
DROP USER IF EXISTS usr_compras;
DROP USER IF EXISTS usr_mecanico;
DROP USER IF EXISTS usr_auditor;

DROP ROLE IF EXISTS rol_administrador;
DROP ROLE IF EXISTS rol_recepcion;
DROP ROLE IF EXISTS rol_compras;
DROP ROLE IF EXISTS rol_mecanico;
DROP ROLE IF EXISTS rol_auditor;
GO

USE master;
GO

IF SUSER_ID('lg_admin') IS NOT NULL DROP LOGIN lg_admin;
IF SUSER_ID('lg_recepcion') IS NOT NULL DROP LOGIN lg_recepcion;
IF SUSER_ID('lg_compras') IS NOT NULL DROP LOGIN lg_compras;
IF SUSER_ID('lg_mecanico') IS NOT NULL DROP LOGIN lg_mecanico;
IF SUSER_ID('lg_auditor') IS NOT NULL DROP LOGIN lg_auditor;
GO

CREATE LOGIN lg_admin     WITH PASSWORD = 'Taller#Admin2026';
CREATE LOGIN lg_recepcion WITH PASSWORD = 'Taller#Recep2026';
CREATE LOGIN lg_compras   WITH PASSWORD = 'Taller#Compra2026';
CREATE LOGIN lg_mecanico  WITH PASSWORD = 'Taller#Mecan2026';
CREATE LOGIN lg_auditor   WITH PASSWORD = 'Taller#Audit2026';
GO

USE tpDatos;
GO

CREATE ROLE rol_administrador;
CREATE ROLE rol_recepcion;
CREATE ROLE rol_compras;
CREATE ROLE rol_mecanico;
CREATE ROLE rol_auditor;
GO

CREATE USER usr_admin     FOR LOGIN lg_admin;
CREATE USER usr_recepcion FOR LOGIN lg_recepcion;
CREATE USER usr_compras   FOR LOGIN lg_compras;
CREATE USER usr_mecanico  FOR LOGIN lg_mecanico;
CREATE USER usr_auditor   FOR LOGIN lg_auditor;
GO

ALTER ROLE rol_administrador ADD MEMBER usr_admin;
ALTER ROLE rol_recepcion     ADD MEMBER usr_recepcion;
ALTER ROLE rol_compras       ADD MEMBER usr_compras;
ALTER ROLE rol_mecanico      ADD MEMBER usr_mecanico;
ALTER ROLE rol_auditor       ADD MEMBER usr_auditor;
GO

CREATE VIEW dbo.vw_mecanicos_publico AS
SELECT id_mecanico, nombre, apellido, telefono
FROM mecanicos;
GO

GRANT SELECT, INSERT, UPDATE, DELETE, EXECUTE ON SCHEMA::dbo TO rol_administrador;
DENY UPDATE, DELETE ON dbo.auditoria_precios TO rol_administrador;
DENY UPDATE, DELETE ON dbo.alertas_stock TO rol_administrador;
GO

GRANT SELECT ON dbo.cliente            TO rol_recepcion;
GRANT SELECT ON dbo.vehiculos          TO rol_recepcion;
GRANT SELECT ON dbo.servicios          TO rol_recepcion;
GRANT SELECT ON dbo.repuestos          TO rol_recepcion;
GRANT SELECT ON dbo.grupos_de_trabajo  TO rol_recepcion;
GRANT SELECT ON dbo.orden_de_trabajo   TO rol_recepcion;
GRANT SELECT ON dbo.orden_servicio     TO rol_recepcion;
GRANT SELECT ON dbo.orden_repuesto     TO rol_recepcion;
GRANT SELECT ON dbo.cobros             TO rol_recepcion;
GRANT SELECT ON dbo.vw_saldo_ordenes   TO rol_recepcion;
GRANT EXECUTE ON dbo.sp_alta_cliente_vehiculo TO rol_recepcion;
GRANT EXECUTE ON dbo.sp_abrir_orden           TO rol_recepcion;
GRANT EXECUTE ON dbo.sp_agregar_servicio      TO rol_recepcion;
GRANT EXECUTE ON dbo.sp_agregar_repuesto      TO rol_recepcion;
GRANT EXECUTE ON dbo.sp_iniciar_orden         TO rol_recepcion;
GRANT EXECUTE ON dbo.sp_cerrar_orden          TO rol_recepcion;
GRANT EXECUTE ON dbo.sp_registrar_cobro       TO rol_recepcion;
GO

GRANT SELECT ON dbo.repuestos          TO rol_compras;
GRANT SELECT ON dbo.proveedores        TO rol_compras;
GRANT SELECT ON dbo.pedidos            TO rol_compras;
GRANT SELECT ON dbo.pagos              TO rol_compras;
GRANT SELECT ON dbo.alertas_stock      TO rol_compras;
GRANT SELECT ON dbo.vw_stock_critico   TO rol_compras;
GRANT SELECT ON dbo.vw_saldo_pedidos   TO rol_compras;
GRANT EXECUTE ON dbo.sp_crear_pedido      TO rol_compras;
GRANT EXECUTE ON dbo.sp_recibir_pedido    TO rol_compras;
GRANT EXECUTE ON dbo.sp_cancelar_pedido   TO rol_compras;
GRANT EXECUTE ON dbo.sp_registrar_pago    TO rol_compras;
GRANT EXECUTE ON dbo.sp_control_faltantes TO rol_compras;
GO

GRANT SELECT ON dbo.vehiculos          TO rol_mecanico;
GRANT SELECT ON dbo.servicios          TO rol_mecanico;
GRANT SELECT ON dbo.grupos_de_trabajo  TO rol_mecanico;
GRANT SELECT ON dbo.empleados_grupos   TO rol_mecanico;
GRANT SELECT ON dbo.orden_de_trabajo   TO rol_mecanico;
GRANT SELECT ON dbo.orden_servicio     TO rol_mecanico;
GRANT SELECT ON dbo.orden_repuesto     TO rol_mecanico;
GO

GRANT SELECT ON SCHEMA::dbo TO rol_auditor;
GO

GRANT SELECT ON dbo.vw_mecanicos_publico TO rol_recepcion, rol_compras, rol_mecanico, rol_auditor;
GO

DENY SELECT ON dbo.mecanicos (salariomensual) TO rol_recepcion, rol_compras, rol_mecanico, rol_auditor;
GO

DENY INSERT, UPDATE, DELETE ON SCHEMA::dbo TO rol_recepcion, rol_compras, rol_mecanico, rol_auditor;
DENY EXECUTE ON SCHEMA::dbo TO rol_mecanico, rol_auditor;
GO

SELECT dp.name        AS rol,
       pr.permission_name AS permiso,
       pr.state_desc  AS estado,
       pr.class_desc  AS nivel,
       CASE WHEN pr.class_desc = 'SCHEMA' THEN SCHEMA_NAME(pr.major_id)
            ELSE OBJECT_NAME(pr.major_id) END AS objeto
FROM sys.database_permissions pr
INNER JOIN sys.database_principals dp ON dp.principal_id = pr.grantee_principal_id
WHERE dp.name LIKE 'rol[_]%'
ORDER BY dp.name, pr.state_desc, pr.permission_name;
GO

-- ==========================================================================
-- SECCION 09_consultas
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
