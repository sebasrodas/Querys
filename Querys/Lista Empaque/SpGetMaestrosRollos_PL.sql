USE [ControlTelas]
GO
/****** Object:  StoredProcedure [dbo].[SpGetMaestrosRollos_PL]    Script Date: 2021/06/01 10:58:51 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================


-- SpGetMaestrosRollos
ALTER PROCEDURE [dbo].[SpGetMaestrosRollos_PL]
@Num INT
, @varTexto VARCHAR(50) = NULL
AS
BEGIN
	
	IF (@Num =0)
	BEGIN
		--TImportacion(0)
		SELECT CodigoImportacion,NroImportacion,CodigoTipoImpoRem
		FROM TImportacion
		RETURN
    END

IF (@Num =1)
	BEGIN
		--TUbicacionesRollos(1)
		--SELECT Codigo,Ubicacion 
		--FROM TUbicacionesRollos
		--WHERE Zona_Ubicacion = 1 AND Activo = 1
		--ORDER BY Ubicacion
		--RETURN
		SELECT TOP 1 t.IdCajon,t.Estanteria
		FROM TEstanterias AS t
		WHERE t.Activo = 1
		RETURN 
		
    END

IF (@Num =2)
	BEGIN
		--TUnidadMedida(2)
		SELECT Codigo,UnidadMedida
		FROM TUnidadMedida
		WHERE Codigo IN(7,8,12)
		ORDER BY UnidadMedida
		RETURN
    END


IF (@Num =3)
	BEGIN	
		--TClasificacionProduccion(3)
		SELECT Codigo,Clasificacion
		FROM TClasificacionProduccion	
		WHERE TClasificacionProduccion.EstadoClasificacion = 1
		RETURN
    END

IF (@Num =4)
	BEGIN		
		--sici.dbo.OrdenesCompra(4)
		
		
		--SELECT Numero_documento, NombreOrden
		--FROM   sici.dbo.OrdenesCompra AS OrdenesCompra
		--WHERE OrdenesCompra.IdTipoOrden NOT IN('8','7','6', '5')
		--ORDER BY Numero_documento
		
		-- srodas 1/27/2021 se consulta las ordenes de compra directamente desde SIESA

		SELECT Numero_documento, NombreOrden, TipoDocumento
		FROM dbo.[fnOrdenCompraSiesa](@varTexto,null)
		UNION ALL
		SELECT 0, 'IMPOREMI', 'IMP'
		ORDER BY 2
		

		--SELECT DISTINCT OrdenesCompra.Numero_documento, OrdenesCompra.NombreOrden
		--FROM   sici.dbo.OrdenesCompra AS OrdenesCompra
		--INNER JOIN sici.dbo.DetalleOrdenesCompra AS doc ON doc.OrdenCompra = OrdenesCompra.Numero_documento
		--WHERE (OrdenesCompra.IdTipoOrden NOT IN('8','7','6', '5') AND doc.Estado = 0 ) OR (OrdenesCompra.IdTipoOrden NOT IN('8','7','6', '5') AND doc.Estado = 1 AND OrdenesCompra.FechaEntregaOrden > DATEADD(MONTH, -4, GETDATE()))
		--ORDER BY 1

		
		RETURN
    END

IF (@Num =5)
	BEGIN	
		--TEstados(5)
		SELECT Codigo, Estado
		FROM   TEstados
	RETURN
END

IF (@Num =6)
	BEGIN	
		--TTipoImpoRem(6)
		SELECT CodigoTipo,TipoImpoRem
		FROM   TTipoImpoRem
		WHERE CodigoTipo <>3
	RETURN
    END


IF (@Num =7)
	BEGIN	
--TListaEmpaque(7)
SELECT convert(varchar,TListaEmpaque.IDListaEmpaque)  AS IDListaEmpaque
into #tmp_TListaEmpaque
FROM   TListaEmpaque 
ORDER BY IDListaEmpaque DESC


SELECT 'NUEVA LISTA EMPAQUE' AS IDListaEmpaque
UNION ALL
SELECT *
FROM #tmp_TListaEmpaque
	RETURN
    END


IF (@Num =8)
	BEGIN	
		--TParametros(8)
		SELECT Valor
		FROM   TParametros
		WHERE CodigoParametro = 1
	RETURN
    END

IF (@Num =9)
	BEGIN	
--TParametros(9)
	SELECT LTRIM(RTRIM(Nit)) AS Nit,UPPER(LTRIM(RTRIM(Clientes.Alias))) AS Nombre
	FROM sici.dbo.Clientes Clientes
	WHERE Clientes.ClienteActivo = 1 OR LTRIM(RTRIM(Nit)) = '8002065847'
	ORDER BY Clientes.Alias
	RETURN
    END
IF (@Num = 10) -- srodas Bodegas Siesa
	BEGIN
	SELECT  f150_rowid idBodega
			,[f150_id] id
			,[f150_descripcion] Bodega
	FROM [SIESASQL].[UnoEE_Piloto].[dbo].t150_mc_bodegas
	WHERE [f150_id] LIKE 'BT%' OR [f150_id] LIKE 'BD%'
	END

IF (@Num = 11) -- srodas Ubicacion Siesa
	BEGIN
	SELECT  f155_id idUbicacion
			,[f155_descripcion] Ubicacion
	FROM SIESASQL.UnoEE_Piloto.dbo.t155_mc_ubicacion_auxiliares
	WHERE f155_rowid_bodega = @varTexto
	END

END