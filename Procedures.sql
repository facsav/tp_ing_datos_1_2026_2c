-- ==========================================================================
-- SECCION 05_procedimientos
-- ==========================================================================
USE tpDatos;
GO

CREATE PROCEDURE dbo.sp_alta_cliente_vehiculo
    @nombre     VARCHAR(100) = NULL,
    @apellido   VARCHAR(100) = NULL,
    @telefono   VARCHAR(50)  = NULL,
    @patente    VARCHAR(20)  = NULL,
    @marca      VARCHAR(100) = NULL,
    @modelo     VARCHAR(100) = NULL,
    @anio       INT          = NULL,
    @id_cliente INT          = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        IF @patente IS NOT NULL
            SET @patente = UPPER(TRIM(@patente));

        IF @id_cliente IS NULL AND (@nombre IS NULL OR @apellido IS NULL)
            THROW 50001, 'Para crear un cliente hacen falta nombre y apellido.', 1;

        IF @id_cliente IS NOT NULL
           AND NOT EXISTS (SELECT 1 FROM cliente WHERE id_cliente = @id_cliente)
            THROW 50002, 'El cliente indicado no existe.', 1;

        IF @id_cliente IS NOT NULL AND @patente IS NULL
            THROW 50003, 'Falta la patente del vehículo a cargar.', 1;

        IF @patente IS NOT NULL AND (@marca IS NULL OR @modelo IS NULL)
            THROW 50004, 'Para cargar un vehículo hacen falta patente, marca y modelo.', 1;

        IF @patente IS NOT NULL
           AND EXISTS (SELECT 1 FROM vehiculos WHERE patente = @patente)
            THROW 50005, 'Ya existe un vehículo con esa patente.', 1;

        BEGIN TRANSACTION;

        IF @id_cliente IS NULL
        BEGIN
            INSERT INTO cliente (nombre, apellido, telefono)
            VALUES (@nombre, @apellido, @telefono);

            SET @id_cliente = SCOPE_IDENTITY();
        END;

        IF @patente IS NOT NULL
            INSERT INTO vehiculos (patente, marca, modelo, anio, id_cliente)
            VALUES (@patente, @marca, @modelo, @anio, @id_cliente);

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

CREATE PROCEDURE dbo.sp_abrir_orden
    @patente  VARCHAR(20),
    @id_orden INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        IF @patente IS NULL
            THROW 50010, 'Falta la patente del vehículo.', 1;

        SET @patente = UPPER(TRIM(@patente));

        IF NOT EXISTS (SELECT 1 FROM vehiculos WHERE patente = @patente)
            THROW 50011, 'El vehículo no existe.', 1;

        INSERT INTO orden_de_trabajo (patente)
        VALUES (@patente);

        SET @id_orden = SCOPE_IDENTITY();
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

CREATE PROCEDURE dbo.sp_agregar_servicio
    @id_orden    INT,
    @id_servicio INT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        IF @id_orden IS NULL
           OR NOT EXISTS (SELECT 1 FROM orden_de_trabajo WHERE id_orden_trabajo = @id_orden)
            THROW 50012, 'La orden no existe.', 1;

        IF @id_servicio IS NULL
           OR NOT EXISTS (SELECT 1 FROM servicios WHERE id_servicio = @id_servicio)
            THROW 50013, 'El servicio no existe.', 1;

        IF EXISTS (SELECT 1
                   FROM orden_servicio
                   WHERE id_orden_trabajo = @id_orden
                     AND id_servicio = @id_servicio)
            THROW 50014, 'El servicio ya está incluido en la orden.', 1;

        INSERT INTO orden_servicio (id_orden_trabajo, id_servicio, precio)
        SELECT @id_orden, id_servicio, precio
        FROM servicios
        WHERE id_servicio = @id_servicio;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

CREATE PROCEDURE dbo.sp_agregar_repuesto
    @id_orden    INT,
    @id_repuesto INT,
    @cantidad    INT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        IF @id_orden IS NULL
           OR NOT EXISTS (SELECT 1 FROM orden_de_trabajo WHERE id_orden_trabajo = @id_orden)
            THROW 50012, 'La orden no existe.', 1;

        IF @id_repuesto IS NULL
           OR NOT EXISTS (SELECT 1 FROM repuestos WHERE id_repuesto = @id_repuesto)
            THROW 50015, 'El repuesto no existe.', 1;

        IF @cantidad IS NULL OR @cantidad <= 0
            THROW 50016, 'La cantidad debe ser mayor que cero.', 1;

        IF EXISTS (SELECT 1
                   FROM orden_repuesto
                   WHERE id_orden_trabajo = @id_orden
                     AND id_repuesto = @id_repuesto)
            THROW 50017, 'El repuesto ya está incluido en la orden.', 1;

        INSERT INTO orden_repuesto (id_orden_trabajo, id_repuesto, cantidad, precio)
        SELECT @id_orden, id_repuesto, @cantidad, precio
        FROM repuestos
        WHERE id_repuesto = @id_repuesto;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

CREATE PROCEDURE dbo.sp_iniciar_orden
    @id_orden INT,
    @id_grupo INT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        IF @id_orden IS NULL
           OR NOT EXISTS (SELECT 1 FROM orden_de_trabajo WHERE id_orden_trabajo = @id_orden)
            THROW 50012, 'La orden no existe.', 1;

        IF NOT EXISTS (SELECT 1
                       FROM orden_de_trabajo
                       WHERE id_orden_trabajo = @id_orden
                         AND estado = 'Pendiente')
            THROW 50019, 'Solo se puede iniciar una orden Pendiente.', 1;

        IF @id_grupo IS NULL
           OR NOT EXISTS (SELECT 1 FROM grupos_de_trabajo WHERE id_grupo_de_trabajo = @id_grupo)
            THROW 50018, 'El grupo de trabajo no existe.', 1;

        BEGIN TRANSACTION;

        UPDATE orden_de_trabajo
        SET id_grupo_de_trabajo = @id_grupo,
            estado = 'En progreso'
        WHERE id_orden_trabajo = @id_orden;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

CREATE PROCEDURE dbo.sp_cerrar_orden
    @id_orden INT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        IF @id_orden IS NULL
           OR NOT EXISTS (SELECT 1 FROM orden_de_trabajo WHERE id_orden_trabajo = @id_orden)
            THROW 50012, 'La orden no existe.', 1;

        IF NOT EXISTS (SELECT 1
                       FROM orden_de_trabajo
                       WHERE id_orden_trabajo = @id_orden
                         AND estado = 'En progreso')
            THROW 50020, 'Solo se puede cerrar una orden En progreso.', 1;

        IF NOT EXISTS (SELECT 1 FROM orden_servicio WHERE id_orden_trabajo = @id_orden)
            THROW 50021, 'No se puede cerrar una orden sin servicios.', 1;

        BEGIN TRANSACTION;

        UPDATE orden_de_trabajo
        SET estado = 'Terminado',
            fecha_fin = CAST(GETDATE() AS DATE)
        WHERE id_orden_trabajo = @id_orden;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

CREATE PROCEDURE dbo.sp_registrar_cobro
    @id_orden INT,
    @monto    INT,
    @metodo   VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        IF @id_orden IS NULL
           OR NOT EXISTS (SELECT 1 FROM orden_de_trabajo WHERE id_orden_trabajo = @id_orden)
            THROW 50012, 'La orden no existe.', 1;

        IF @monto IS NULL OR @monto <= 0
            THROW 50022, 'El monto debe ser mayor que cero.', 1;

        BEGIN TRANSACTION;

        INSERT INTO cobros (id_orden_trabajo, monto, metodo_de_cobro)
        VALUES (@id_orden, @monto, @metodo);

        COMMIT TRANSACTION;

        SELECT dbo.fn_saldo_orden(@id_orden) AS saldo;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

CREATE PROCEDURE dbo.sp_crear_pedido
    @id_repuesto   INT,
    @cantidad      INT,
    @precio_unidad INT,
    @id_pedido     INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        IF @id_repuesto IS NULL
           OR NOT EXISTS (SELECT 1 FROM repuestos WHERE id_repuesto = @id_repuesto)
            THROW 50015, 'El repuesto no existe.', 1;

        IF @cantidad IS NULL OR @cantidad <= 0
            THROW 50016, 'La cantidad debe ser mayor que cero.', 1;

        IF @precio_unidad IS NULL OR @precio_unidad < 0
            THROW 50025, 'El costo unitario no puede ser negativo.', 1;

        INSERT INTO pedidos (id_repuesto, cantidad, precio_unidad)
        VALUES (@id_repuesto, @cantidad, @precio_unidad);

        SET @id_pedido = SCOPE_IDENTITY();
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

CREATE PROCEDURE dbo.sp_recibir_pedido
    @id_pedido INT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        IF @id_pedido IS NULL
           OR NOT EXISTS (SELECT 1 FROM pedidos WHERE id_pedido = @id_pedido)
            THROW 50026, 'El pedido no existe.', 1;

        IF NOT EXISTS (SELECT 1
                       FROM pedidos
                       WHERE id_pedido = @id_pedido
                         AND estado = 'Pendiente')
            THROW 50027, 'Solo se puede recibir un pedido Pendiente.', 1;

        BEGIN TRANSACTION;

        UPDATE pedidos
        SET estado = 'Recibido'
        WHERE id_pedido = @id_pedido;

        UPDATE repuestos
        SET stock = stock + (SELECT cantidad FROM pedidos WHERE id_pedido = @id_pedido)
        WHERE id_repuesto = (SELECT id_repuesto FROM pedidos WHERE id_pedido = @id_pedido);

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

CREATE PROCEDURE dbo.sp_cancelar_pedido
    @id_pedido INT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        IF @id_pedido IS NULL
           OR NOT EXISTS (SELECT 1 FROM pedidos WHERE id_pedido = @id_pedido)
            THROW 50026, 'El pedido no existe.', 1;

        IF NOT EXISTS (SELECT 1
                       FROM pedidos
                       WHERE id_pedido = @id_pedido
                         AND estado = 'Pendiente')
            THROW 50027, 'Solo se puede cancelar un pedido Pendiente.', 1;

        IF EXISTS (SELECT 1 FROM pagos WHERE id_pedido = @id_pedido)
            THROW 50029, 'No se puede cancelar un pedido que ya tiene pagos.', 1;

        BEGIN TRANSACTION;

        UPDATE pedidos
        SET estado = 'Cancelado'
        WHERE id_pedido = @id_pedido;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

CREATE PROCEDURE dbo.sp_registrar_pago
    @id_pedido INT,
    @monto     INT,
    @metodo    VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        IF @id_pedido IS NULL
           OR NOT EXISTS (SELECT 1 FROM pedidos WHERE id_pedido = @id_pedido)
            THROW 50026, 'El pedido no existe.', 1;

        IF @monto IS NULL OR @monto <= 0
            THROW 50022, 'El monto debe ser mayor que cero.', 1;

        BEGIN TRANSACTION;

        INSERT INTO pagos (id_pedido, monto, metodo_de_pago)
        VALUES (@id_pedido, @monto, @metodo);

        COMMIT TRANSACTION;

        SELECT saldo, estado_pago FROM dbo.vw_saldo_pedidos WHERE id_pedido = @id_pedido;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO
