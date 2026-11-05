-- ==========================================================================
-- SECCION 04_triggers
-- ==========================================================================
USE tpDatos;
GO

CREATE TRIGGER dbo.trg_servicios_auditoria
ON servicios
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF UPDATE(precio)
        INSERT INTO auditoria_precios (tabla_origen, id_registro, precio_anterior, precio_nuevo, usuario, fecha)
        SELECT 'servicios', d.id_servicio, d.precio, i.precio, SUSER_SNAME(), GETDATE()
        FROM deleted d
        INNER JOIN inserted i ON i.id_servicio = d.id_servicio
        WHERE d.precio <> i.precio;
END;
GO

CREATE TRIGGER dbo.trg_repuestos_auditoria
ON repuestos
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF UPDATE(precio)
        INSERT INTO auditoria_precios (tabla_origen, id_registro, precio_anterior, precio_nuevo, usuario, fecha)
        SELECT 'repuestos', d.id_repuesto, d.precio, i.precio, SUSER_SNAME(), GETDATE()
        FROM deleted d
        INNER JOIN inserted i ON i.id_repuesto = d.id_repuesto
        WHERE d.precio <> i.precio;
END;
GO

CREATE TRIGGER dbo.trg_orden_transicion
ON orden_de_trabajo
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF UPDATE(estado)
       AND EXISTS (SELECT 1
                   FROM inserted i
                   INNER JOIN deleted d ON d.id_orden_trabajo = i.id_orden_trabajo
                   WHERE i.estado <> d.estado
                     AND NOT ((d.estado = 'Pendiente' AND i.estado = 'En progreso')
                           OR (d.estado = 'En progreso' AND i.estado = 'Terminado')))
    BEGIN
        ROLLBACK TRANSACTION;
        THROW 50030, 'El estado de la orden solo avanza en orden: Pendiente, En progreso, Terminado.', 1;
    END;
END;
GO

CREATE TRIGGER dbo.trg_orden_inicio_descuenta
ON orden_de_trabajo
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @necesarios TABLE (id_repuesto INT, cantidad INT);

    IF UPDATE(estado)
    BEGIN
        INSERT INTO @necesarios (id_repuesto, cantidad)
        SELECT orp.id_repuesto, SUM(orp.cantidad)
        FROM orden_repuesto orp
        INNER JOIN inserted i ON i.id_orden_trabajo = orp.id_orden_trabajo
        INNER JOIN deleted d  ON d.id_orden_trabajo = i.id_orden_trabajo
        WHERE i.estado = 'En progreso'
          AND d.estado = 'Pendiente'
        GROUP BY orp.id_repuesto;

        IF EXISTS (SELECT 1
                   FROM @necesarios n
                   INNER JOIN repuestos r ON r.id_repuesto = n.id_repuesto
                   WHERE r.stock < n.cantidad)
        BEGIN
            ROLLBACK TRANSACTION;
            THROW 50031, 'Stock insuficiente para iniciar la orden.', 1;
        END;

        UPDATE repuestos
        SET stock = stock - (SELECT n.cantidad FROM @necesarios n WHERE n.id_repuesto = repuestos.id_repuesto)
        WHERE id_repuesto IN (SELECT id_repuesto FROM @necesarios);
    END;
END;
GO

CREATE TRIGGER dbo.trg_orden_repuesto_descuenta
ON orden_repuesto
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @necesarios TABLE (id_repuesto INT, cantidad INT);

    INSERT INTO @necesarios (id_repuesto, cantidad)
    SELECT i.id_repuesto, SUM(i.cantidad)
    FROM inserted i
    INNER JOIN orden_de_trabajo o ON o.id_orden_trabajo = i.id_orden_trabajo
    WHERE o.estado = 'En progreso'
    GROUP BY i.id_repuesto;

    IF EXISTS (SELECT 1
               FROM @necesarios n
               INNER JOIN repuestos r ON r.id_repuesto = n.id_repuesto
               WHERE r.stock < n.cantidad)
    BEGIN
        ROLLBACK TRANSACTION;
        THROW 50031, 'Stock insuficiente para agregar el repuesto a la orden.', 1;
    END;

    UPDATE repuestos
    SET stock = stock - (SELECT n.cantidad FROM @necesarios n WHERE n.id_repuesto = repuestos.id_repuesto)
    WHERE id_repuesto IN (SELECT id_repuesto FROM @necesarios);
END;
GO

CREATE TRIGGER dbo.trg_orden_repuesto_bloqueo
ON orden_repuesto
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (SELECT 1
               FROM orden_de_trabajo o
               WHERE o.estado = 'Terminado'
                 AND (o.id_orden_trabajo IN (SELECT id_orden_trabajo FROM inserted)
                   OR o.id_orden_trabajo IN (SELECT id_orden_trabajo FROM deleted)))
    BEGIN
        ROLLBACK TRANSACTION;
        THROW 50032, 'Una orden Terminado no admite cambios en sus servicios ni en sus repuestos.', 1;
    END;

    IF EXISTS (SELECT 1
               FROM deleted d
               INNER JOIN orden_de_trabajo o ON o.id_orden_trabajo = d.id_orden_trabajo
               WHERE o.estado = 'En progreso')
    BEGIN
        ROLLBACK TRANSACTION;
        THROW 50036, 'Los repuestos de una orden En progreso ya descontaron stock y no se modifican.', 1;
    END;
END;
GO

CREATE TRIGGER dbo.trg_orden_servicio_bloqueo
ON orden_servicio
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (SELECT 1
               FROM orden_de_trabajo o
               WHERE o.estado = 'Terminado'
                 AND (o.id_orden_trabajo IN (SELECT id_orden_trabajo FROM inserted)
                   OR o.id_orden_trabajo IN (SELECT id_orden_trabajo FROM deleted)))
    BEGIN
        ROLLBACK TRANSACTION;
        THROW 50032, 'Una orden Terminado no admite cambios en sus servicios ni en sus repuestos.', 1;
    END;
END;
GO

CREATE TRIGGER dbo.trg_cobros_tope
ON cobros
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (SELECT 1
               FROM orden_de_trabajo o
               WHERE o.id_orden_trabajo IN (SELECT id_orden_trabajo FROM inserted)
                 AND dbo.fn_saldo_orden(o.id_orden_trabajo) < 0)
    BEGIN
        ROLLBACK TRANSACTION;
        THROW 50033, 'La suma de los cobros no puede superar el total de la orden.', 1;
    END;
END;
GO

CREATE TRIGGER dbo.trg_pagos_tope
ON pagos
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (SELECT 1
               FROM inserted i
               INNER JOIN pedidos p ON p.id_pedido = i.id_pedido
               WHERE p.estado = 'Cancelado')
    BEGIN
        ROLLBACK TRANSACTION;
        THROW 50035, 'Un pedido Cancelado no se puede pagar.', 1;
    END;

    IF EXISTS (SELECT 1
               FROM pedidos p
               WHERE p.id_pedido IN (SELECT id_pedido FROM inserted)
                 AND p.cantidad * p.precio_unidad < (SELECT SUM(pg.monto)
                                                     FROM pagos pg
                                                     WHERE pg.id_pedido = p.id_pedido))
    BEGIN
        ROLLBACK TRANSACTION;
        THROW 50034, 'La suma de los pagos no puede superar el total del pedido.', 1;
    END;
END;
GO

CREATE TRIGGER dbo.trg_pedidos_transicion
ON pedidos
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF UPDATE(estado)
       AND EXISTS (SELECT 1
                   FROM inserted i
                   INNER JOIN deleted d ON d.id_pedido = i.id_pedido
                   WHERE d.estado <> 'Pendiente'
                     AND i.estado <> d.estado)
    BEGIN
        ROLLBACK TRANSACTION;
        THROW 50037, 'Un pedido Recibido o Cancelado no puede cambiar de estado.', 1;
    END;
END;
GO