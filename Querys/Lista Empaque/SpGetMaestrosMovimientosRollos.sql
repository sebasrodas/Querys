USE [ControlTelas]
GO
/****** Object:  StoredProcedure [dbo].[SpGetMaestrosMovimientosRollos]    Script Date: 2021/06/02 3:20:27 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
 *  * =============================================
Modifica:	Carlos Alberto Correa Ortiz
Fecha:       09/22/2017
NroReqsis:	9188
Descripción: Incluimos upper en los nombres de los responsables.
Agregamos código para que se puedan cargar los protos que viene desde tbl_Contratos.
=============================================
 */
   --	SpGetMaestrosMovimientosRollos 1
ALTER PROCEDURE [dbo].[SpGetMaestrosMovimientosRollos]
	@PerfilUsuario VARCHAR(10)
AS
BEGIN
	--TTipoDocumentos(0)
	IF (@PerfilUsuario IN ('20')) --Si es el jefe de corte
	BEGIN
	    SELECT Codigo,
	           TipoDocumento
	    FROM   TTipoDocumentos
		WHERE Codigo IN (1,2) --srodas 1/27/2021 se agrega filtro para traer solo entradas/ salidas
	END
	ELSE
	BEGIN
	    SELECT Codigo,
	           TipoDocumento
	    FROM   TTipoDocumentos
	    --WHERE  Codigo <> 5
	    WHERE Codigo IN (1,2) --srodas 1/27/2021 se agrega filtro para traer solo entradas/ salidas
	END
	
	--TTipoMovimientos(1)
	
	IF (@PerfilUsuario IN ('20', '284','4','1'))--SI ES JEFE DE CORTE VE TODOS LOS MOVIMIENTOS
	BEGIN
	    SELECT Codigo,
	           TipoMovimiento,
	           CodigoTipoDocumento,
	           ActualizaLeoncio,
	           TipoDocumento
	    FROM   TTipoMovimientos
	    WHERE  Activo = 1 
		AND  Codigo in (1,3,19,41) -- srodas 1/27/2021 se agrega filtro para traer solo entradas
	END
	ELSE
	BEGIN
	    SELECT Codigo,
	           TipoMovimiento,
	           CodigoTipoDocumento,
	           ActualizaLeoncio,
	           TipoDocumento
	    FROM   TTipoMovimientos
	    WHERE  TTipoMovimientos.Activo = 1
	           --AND TTipoMovimientos.Codigo <> 24
	           --AND TTipoMovimientos.Codigo <> 31
			   AND  Codigo in (1,3,19,41)-- srodas 1/27/2021 se agrega filtro para traer solo entradas
	END
	
	--TResponsables(2)
	SELECT Codigo,
	       UPPER(Responsable) Responsable
	FROM   TResponsables
	WHERE  Codigo <> '005'
	       AND Activo = 1
	ORDER BY
	       Responsable
	
	--TResponsables(3)
	SELECT Codigo,
	       UPPER(Responsable) Responsable
	FROM   TResponsables
	WHERE  Codigo <> '005'
	       AND Activo = 1
	ORDER BY
	       Responsable
	
	--TSolicitadoPor(4)
	SELECT Codigo,
	       UPPER(Responsable) AS Nombre
	FROM   TResponsables
	WHERE  Codigo <> '005'
	       AND Activo = 1
	ORDER BY
	       Responsable
	
	--Tbl_Contratos(5)
	SELECT LTRIM(RTRIM(Tbl_Contratos.Contrato)) AS Contrato,
	       CASE 
	            WHEN LTRIM(RTRIM(Tbl_Contratos.Contrato)) LIKE 'PCR%' THEN 'PCR'
	            WHEN LTRIM(RTRIM(Tbl_Contratos.Contrato)) LIKE 'TOP%' THEN --acorrea;04/05/2018;Para el tema de Movimientos de Rollos a los TOP y APS los manejamos como PCR
	                 'PCR'
	                       WHEN LTRIM(RTRIM(Tbl_Contratos.Contrato)) LIKE 'APS%' THEN 
	                 'PCR'
	            WHEN LTRIM(RTRIM(Tbl_Contratos.Contrato)) LIKE 'PRE%' THEN 
	                 'PROTO'
	            WHEN LTRIM(RTRIM(Tbl_Contratos.Contrato)) LIKE 'MW%' THEN 
	                 'MUESTRA'
	            ELSE 'CONTRATO'
	       END                 AS TipoProduccion
	FROM   sici.dbo.Contratos  AS Contratos
	       INNER JOIN sici.dbo.Tbl_Contratos AS Tbl_Contratos
	            ON  Tbl_Contratos.ContratoCer = Contratos.Contrato
	WHERE  (Contratos.Estado = 0)
	UNION ALL
	SELECT LTRIM(RTRIM(Contratos.Contrato)) AS Contrato,
	       CASE 
	            WHEN LTRIM(RTRIM(Contratos.Contrato)) LIKE '%PCR%' THEN 'PCR'
	            ELSE 'CONTRATO'
	       END                 AS TipoProduccion
	FROM   sici.dbo.Contratos  AS Contratos
	       LEFT JOIN sici.dbo.Tbl_Contratos AS Tbl_Contratos
	            ON  Tbl_Contratos.ContratoCer = Contratos.Contrato
	WHERE  (
	           Contratos.Contrato LIKE '%CX'
	           AND Contratos.Estado = 0
	           AND Contratos.Contrato NOT LIKE '%PCR%'
	           AND Contratos.Contrato NOT LIKE('PRE%')
	           AND Contratos.Contrato NOT LIKE('MW%')
	       ) 
	UNION ALL
	SELECT Proto,
	       CASE 
	            WHEN LEFT(Proto, 2) = 'MW' THEN 'MUESTRA'
	            ELSE 'PROTO'
	       END
	FROM   sici.dbo.Tbl_Protos
	WHERE  estado NOT IN ('Cancelado', 'Finalizado')
	UNION ALL
	SELECT Bota,
	       'BOTAS'
	FROM   sici.dbo.Tbl_Botas
	--WHERE  estado = 0 ;acorrea;04/02/2018;Las botas finalizadas también deben salir aquí.
	UNION ALL
	SELECT LTRIM(RTRIM(Tbl_Contratos.Contrato)) AS Contrato,
	       CASE WHEN LEFT(LTRIM(RTRIM(Tbl_Contratos.Contrato)), 3) = 'PCR' THEN 'PCR' ELSE 'CONTRATO' END AS TipoProduccion
	FROM   sici.dbo.Contratos AS Contratos
	       left JOIN sici.dbo.Tbl_Contratos AS Tbl_Contratos ON  Tbl_Contratos.ContratoCer = Contratos.Contrato
	WHERE  (Tbl_Contratos.Contrato IN ('XXXX'))	
	UNION ALL 
	SELECT '000SABANAS','SABANAS'
	ORDER BY 2,1
	
	--Tbl_TrazoContrato(6)
	SELECT Tbl_Contratos.Contrato,
	       CONVERT(INT, Tbl_TrazoContrato.Trazo) AS Trazo
	FROM   sici.dbo.Tbl_Contratos AS Tbl_Contratos
	       INNER JOIN sici.dbo.Contratos AS Contratos
	            ON  Tbl_Contratos.ContratoCer = Contratos.Contrato
	       INNER JOIN sici.dbo.Tbl_TrazoContrato AS Tbl_TrazoContrato
	            ON  Tbl_Contratos.Contrato = Tbl_TrazoContrato.Contrato
	ORDER BY
	       Tbl_Contratos.Contrato,
	       CONVERT(INT, Tbl_TrazoContrato.Trazo)
	
	--TUbicacionesRollos(7)
	--SELECT Codigo
	--      ,Ubicacion
	--FROM   TUbicacionesRollos
	--WHERE  Zona_Ubicacion = 1
	--       AND Activo = 1
	--ORDER BY
	--       Ubicacion
	SELECT TOP 1 t.IdCajon,
	       t.Estanteria
	FROM   TEstanterias AS t
	WHERE  t.Activo = 1
	
	--TProgramacionExtendida(8)
	SELECT TProgramacionExtendida.NroProgramacion AS NroProg,
	       TProgramacionExtendida.Contrato,
	       TTelas.CodigoTela,
	       '' AS CodigoTelaProveedor,
	       --TTelas.CodigoTelaProveedor,
	       TTelas.Nombre
	FROM   TProgramacionExtendida
	       INNER JOIN Sici.GCT008.vTTelas AS TTelas -- srodas 1/27/2021
	            ON  TProgramacionExtendida.CodigoTela = TTelas.Item
	ORDER BY
	       NroProg DESC
	
	--Operadores(9)
	SELECT Codigo,
	       Responsable AS Nombre
	FROM   TResponsables
	WHERE  Codigo <> '005'
	       AND Activo = 1
	ORDER BY
	       Responsable
	
	--TTipoImpoRem(10)
	SELECT CodigoTipo,
	       TipoImpoRem
	FROM   TTipoImpoRem
	
	-- srodas 1/27/2021 se cambia fuente de consulta de la orden de compra
	SELECT Numero_documento, NombreOrden, TipoDocumento
	FROM dbo.[fnOrdenCompraSiesa](null,NULL)
	ORDER BY Numero_documento

	--sici.dbo.OrdenesCompra(11)
	--SELECT Numero_documento,
	--       NombreOrden
	--FROM   sici.dbo.OrdenesCompra AS OrdenesCompra
	--ORDER BY
	--       Numero_documento
	
	--TProcedencias(12)
	SELECT Codigo,
	       Procedencia
	FROM   TProcedencias

	--Bodegas (13)
	SELECT  f152_rowid_bodega idBodega
			,[f152_id_grupo_bodega]
	FROM [SIESASQL].[UnoEE_Piloto].[dbo].[t152_mc_bodega_grupo_bodega]

	-- TiposDocumentoso Movimiento (14)
		SELECT -1 Codigo
				,'TODOS' TipoMovimiento
		UNION ALL
	    SELECT Codigo,
	           TipoMovimiento
	    FROM   TTipoMovimientos
	    WHERE  Activo = 1 
		AND  Codigo in (1,3,19,41) -- srodas 1/27/2021 se agrega filtro para traer tipos de documentos para la consulta de movimientos
END


