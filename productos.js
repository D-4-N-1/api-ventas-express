import { Router } from "express";
import { pool } from "../db.js";
const router = Router();
// endpoint get: consultar productos por nombre
router.get('/consultar', async (req, res) => {
    try {
        const {nombre} = req.query;
        //validacion de parametros obligatorios
        if (!nombre) {
            return res.status(400).json({error:'Bad Request' ,  message:'escribe bien'});
        }
        // se ejecuta el SP en BD
        const [rows] = await pool.query('Call sp_consultar_productos(?)', [nombre]);
        //enviamos la respuesta al cliente
        res.status(200).json({
            status: 'success',
            total_registros : rows[0] ? rows[0].length : 0,
            data: rows[0]
        })
    } catch (error) {
        console.log('Error en GET /ventas/consolidado', error);
        res.status(500).json({error:'Internal Server Error' ,  message:'se me chispoteo el servidor'});
    }
})
// endpoint para registrar un producto
router.post('/registrar', async (req,res) =>{
    try {const {producto, id_categoria, precio_unitario, costo_proveedor, ubicacion_pasillo} = req.body;
        //validacion de datos
        if (!producto || !id_categoria || !precio_unitario || !costo_proveedor || !ubicacion_pasillo){
            return res.status(400).json({
                error: 'bad request',
                message : 'todos los parametros son obligatorios, tonto'
        })};
        //insertar datos
        await pool.query('CALL db_registrar_producto(?,?,?,?,?)', [
            producto, id_categoria, precio_unitario, costo_proveedor, ubicacion_pasillo
        ]);
        res.status(201).json({status : 'created',
            message : 'producto registrado correctamente',
            datos_registrados: {producto, id_categoria, precio_unitario, costo_proveedor, ubicacion_pasillo}
        })
    } catch (error) {
        console.log('Error en POST /ventas/ventas', error);
        res.status(500).json({error:'Internal Server Error' ,  message:'se me chispoteo el servidor'});
    }
})
export default router;