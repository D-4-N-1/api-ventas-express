CREATE DATABASE IF NOT EXISTS db_ventas_tech;
USE db_ventas_tech;

-- 1. Tabla Categorías
CREATE TABLE categorias (
    id_categoria INT AUTO_INCREMENT PRIMARY KEY,
    nombre_categoria VARCHAR(50) NOT NULL,
    descripcion_tecnica TEXT
);

-- 2. Tabla Productos 
CREATE TABLE productos (
    id_producto INT AUTO_INCREMENT PRIMARY KEY,
    id_categoria INT NOT NULL,
    nombre_producto VARCHAR(100) NOT NULL,
    precio_unitario INT NOT NULL,
    costo_proveedor INT NOT NULL, 
    ubicacion_pasillo VARCHAR(10),
    FOREIGN KEY (id_categoria) REFERENCES categorias(id_categoria)
);

-- 3. Tabla Clientes
CREATE TABLE clientes (
    id_cliente INT AUTO_INCREMENT PRIMARY KEY,
    rut_cliente VARCHAR(12) NOT NULL,
    nombre_completo VARCHAR(100) NOT NULL,
    estado_membresia ENUM('Activo', 'Suspendido', 'Cancelado') DEFAULT 'Activo', 
    tipo_cliente ENUM('Normal', 'Premium') DEFAULT 'Normal',
    telefono VARCHAR(15),
    direccion_despacho VARCHAR(150)
);

-- 4. Tabla Ventas
CREATE TABLE ventas (
    id_venta INT AUTO_INCREMENT PRIMARY KEY,
    id_cliente INT NOT NULL,
    id_producto INT NOT NULL,
    cantidad INT NOT NULL,
    fecha_venta DATE NOT NULL, 
    codigo_seguimiento VARCHAR(50),
    FOREIGN KEY (id_cliente) REFERENCES clientes(id_cliente),
    FOREIGN KEY (id_producto) REFERENCES productos(id_producto)
);

ALTER TABLE ventas
ADD COLUMN sucursal INT NOT NULL,
ADD FOREIGN KEY (sucursal) REFERENCES sucursales(id_sucursal);

CREATE TABLE sucursales (
    id_sucursal INT AUTO_INCREMENT PRIMARY KEY,
    nombre_sucursal VARCHAR(50) NOT NULL,
    direccion_sucursal VARCHAR(150) NOT NULL
);

-- =================================================================
-- POBLAMIENTO DE DATOS
-- =================================================================

INSERT INTO categorias (nombre_categoria, descripcion_tecnica) VALUES 
('Computación', 'Laptops, desktops y accesorios de PC'),
('Telefonía', 'Smartphones y accesorios móviles'),
('Audio', 'Audífonos, parlantes y barras de sonido');

INSERT INTO productos (id_categoria, nombre_producto, precio_unitario, costo_proveedor, ubicacion_pasillo) VALUES 
(1, 'Notebook Gamer RTX 3060', 850000, 600000, 'A1'),
(1, 'Mouse Inalámbrico', 15000, 5000, 'A2'),
(2, 'Smartphone Pro Max', 950000, 700000, 'B1'),
(3, 'Audífonos Bluetooth', 120000, 80000, 'C1'),
(3, 'Parlante Portátil', 45000, 20000, 'C2');

INSERT INTO clientes (rut_cliente, nombre_completo, estado_membresia, tipo_cliente, telefono, direccion_despacho) VALUES 
('11111111-1', 'Juan Pérez', 'Activo', 'Premium', '+56911111111', 'Calle Falsa 123, Santiago'),
('22222222-2', 'María González', 'Activo', 'Normal', '+56922222222', 'Avenida Central 456, Valparaíso'),
('33333333-3', 'Carlos Soto', 'Suspendido', 'Premium', '+56933333333', 'Pasaje Sur 789, Concepción'),
('44444444-4', 'Ana Silva', 'Activo', 'Premium', '+56944444444', 'Los Leones 100, Providencia');

-- Inserción de Ventas 
INSERT INTO ventas (id_cliente, id_producto, cantidad, fecha_venta, codigo_seguimiento, sucursal) VALUES 
(1, 1, 1, '2023-11-15', 'TRK-001', 1),
(1, 4, 2, '2024-02-10', 'TRK-002', 1), 
(2, 3, 1, '2024-02-15', 'TRK-003', 2), 
(3, 2, 5, '2024-03-01', 'TRK-004', 3),
(4, 5, 3, '2024-03-20', 'TRK-005', 1), 
(4, 1, 1, '2024-03-25', 'TRK-006', 1); 

INSERT INTO sucursales (nombre_sucursal, direccion_sucursal) VALUES 
('Sucursal Santiago', 'Av. Providencia 1234, Santiago'),
('Sucursal Valparaíso', 'Calle Condell 567, Valparaíso'),
('Sucursal Concepción', 'Av. O’Higgins 890, Concepción');


CREATE Function fn_calcular_total(p_cantidad INT, p_precio INT, p_tipo_cliente VARCHAR(15))
 RETURNS DECIMAL(10,2) DETERMINISTIC
 BEGIN
    DECLARE v_subtotal DECIMAL(10,2);
    DECLARE v_total DECIMAL(10,2);

    SET v_subtotal = p_cantidad * p_precio;

    IF p_tipo_cliente = 'Premium' THEN
        SET v_total = v_subtotal * 0.85; -- 15% de descuento para clientes Premium
    ELSE
        SET v_total = v_subtotal;
    END IF;

    RETURN v_total;
 END;

DELIMITER $$

CREATE PROCEDURE sp_reporte_ventas_year(IN p_year INT)
BEGIN
    SELECT
        c.nombre_completo AS "Nombre Cliente",
        c.tipo_cliente AS "Tipo Cliente",
        ca.nombre_categoria AS "Nombre Categoría",
        p.nombre_producto AS "Nombre Producto",
        v.cantidad AS "Cantidad",
        fn_calcular_total(
            v.cantidad,
            p.precio_unitario,
            c.tipo_cliente
        ) AS "Total a Pagar"
    FROM ventas v
        INNER JOIN clientes c
            ON v.id_cliente = c.id_cliente
        INNER JOIN productos p
            ON v.id_producto = p.id_producto
        INNER JOIN categorias ca
            ON p.id_categoria = ca.id_categoria
    WHERE YEAR(v.fecha_venta) = p_year
      AND c.estado_membresia = 'Activo'
    ORDER BY v.fecha_venta;
END$$

DELIMITER ;

delimiter $$

DELIMITER $$

DELIMITER $$

CREATE PROCEDURE db_ventas_tech(
    IN p_sucursal INT,
    IN p_year INT
)
BEGIN

    SELECT
        c.nombre_completo AS "Nombre Cliente",
        c.tipo_cliente AS "Tipo Cliente",
        ca.nombre_categoria AS "Nombre Categoría",
        p.nombre_producto AS "Nombre Producto",
        v.cantidad AS "Cantidad",
        fn_calcular_total(
            v.cantidad,
            p.precio_unitario,
            c.tipo_cliente
        ) AS "Total a Pagar"

    FROM ventas v

        INNER JOIN clientes c
            ON v.id_cliente = c.id_cliente

        INNER JOIN productos p
            ON v.id_producto = p.id_producto

        INNER JOIN categorias ca
            ON p.id_categoria = ca.id_categoria

    WHERE c.estado_membresia = 'Activo'

        AND IF(p_year = 0 OR YEAR(v.fecha_venta) = p_year)

        AND IF(p_sucursal = 0, v.sucursal is not null, v.sucursal = p_sucursal)

    ORDER BY v.fecha_venta;

END $$

DELIMITER ;

DELIMITER ;

CALL sp_reporte_ventas_year(2024);

call db_ventas_tech(1, 2024);