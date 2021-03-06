USE [ControlTelas]
GO
/****** Object:  StoredProcedure [dbo].[SpGetRollos]    Script Date: 2021/06/01 11:33:09 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- SpGetRollos 41620, 1682
ALTER PROCEDURE [dbo].[SpGetRollos]
@IDListaEmpaque INT,
@CodigoTela NUMERIC(18, 0)
AS
BEGIN
	

	   SELECT DISTINCT
	   TRollos.IDRollo,
	   TRollos.NroRollo,
	   TImportacion.NroImportacion AS NroImportacion,
	   TRollos.UPC,
	   TRollos.NroRolloProv,
	   ISNULL(toc.NombreOrden,'') AS [Nro Orden Compra], 
	   tp.Clasificacion AS Clasificacion,		   
	   CONVERT(NUMERIC(18,3),TRollos.CantEntrada) AS CantEntrada,
	   CONVERT(NUMERIC(18,3),TRollos.CantRealEntrada) AS CantRealEntrada,
	   0.00 AS CantMts,
	   CONVERT(NUMERIC(18,3),TRollos.CantDespachada) AS CantDespachada,
	   CONVERT(NUMERIC(18,3),TRollos.Saldo) AS Saldo,
	   TRollos.Ancho,
	   TRollos.CodigoEstado AS Estado,
	   TRollos.FechaEntrada,
	   TRollos.CodigoUndMedida,
	   NroOrdenCompra,
	   TRollos.IDListaEmpaque,
	   ISNULL(TRollos.IDRolloCrudo,0) AS NroRolloCrudo,
	   ISNULL(Trollos.Lote,'') AS Lote,
	   tu.idUbicacion AS Ubicacion
FROM   TRollos
	   INNER JOIN [Sici].[GCT008].[vTTelas] TTelas ON TRollos.CodigoTela = TTelas.Item	 
	   LEFT JOIN (	SELECT Numero_documento, NombreOrden, TipoDocumento
					FROM DBO.fnOrdenCompraSiesa(NULL, NULL)
					UNION ALL
					SELECT 0, 'IMPOREMI', 'IMP'
				  ) AS toc ON toc.Numero_documento = TRollos.NroOrdenCompra
	   LEFT JOIN TEstanterias AS t ON t.IdCajon = TRollos.IdCajon
	   LEFT JOIN (
			SELECT  f155_id idUbicacion
			, f155_rowid_bodega
			,[f155_descripcion] Ubicacion
			FROM SIESASQL.UnoEE_Piloto.dbo.t155_mc_ubicacion_auxiliares
	   ) tu ON tu.idUbicacion = TRollos.idUbicacion
	   INNER JOIN TImportacion AS TImportacion ON TImportacion.CodigoImportacion = TRollos.NroImportacion
	   INNER JOIN TClasificacionProduccion AS tp ON TRollos.CodigoClasificacion = tp.Codigo
WHERE TRollos.IDListaEmpaque = @IDListaEmpaque AND TRollos.CodigoTela = @CodigoTela --CodigoEstado = 1 
ORDER BY TRollos.NroRollo
                              
END
