USE [ControlTelas]
GO
/****** Object:  StoredProcedure [dbo].[paSabanasListaPedidosAdelantados]    Script Date: 2021/06/03 4:26:27 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Aescudero>
-- Create date: <7/28/2017>
-- Description:	<lista pedidos adelantados modulo sabanas>
-- =============================================
--exec paSabanasListaPedidosAdelantados 5358,21941,'000125'
ALTER PROCEDURE [dbo].[paSabanasListaPedidosAdelantados]

	 @numCodTela NUMERIC (18,0),
	 @numIdSabana   NUMERIC (18,0),
	 @varNroImportacion varchar(50)
AS
BEGIN

declare @numCodigoEDP NUMERIC (38,0)

		SELECT      Sici.dbo.TEDPCliente.Codigo INTO #tblCodigoEDP
	FROM            Sici.dbo.Contratos INNER JOIN
							 Sici.dbo.TProductos ON Sici.dbo.Contratos.NroProducto = Sici.dbo.TProductos.NroProducto INNER JOIN
							 Sici.dbo.TEDPCliente ON Sici.dbo.TProductos.CodigoEDPCliente = Sici.dbo.TEDPCliente.Codigo INNER JOIN
							 Sici.dbo.Tbl_Contratos ON Sici.dbo.Contratos.Contrato = Sici.dbo.Tbl_Contratos.ContratoCer INNER JOIN
							 Tbl_SabanasSeguimiento ON Sici.dbo.Tbl_Contratos.Contrato = Tbl_SabanasSeguimiento.Contrato
	WHERE        (Tbl_SabanasSeguimiento.IdSabana = @numIdSabana)
	UNION ALL
	SELECT        Sici.dbo.TEDPCliente.Codigo
	FROM            Sici.dbo.TEDPCliente INNER JOIN
							 Tbl_SabanasSeguimiento ON Tbl_SabanasSeguimiento.Lavado = Sici.dbo.TEDPCliente.Nombre
	WHERE        (Tbl_SabanasSeguimiento.IdSabana = @numIdSabana)

	select  @numCodigoEDP =  #tblCodigoEDP.Codigo
	from #tblCodigoEDP

	DECLARE @tblfnPruenasLaboratorio AS TABLE (	IdRollo NUMERIC (38,0), 
												[ENCOGIMIENTO (%) U] decimal (18,2),
												[ENCOGIMIENTO (%) T] decimal (18,2),
												[% SKEW Real] decimal (18,2),
												[ENCOGIMIENTO LAVANDERIA U] decimal (18,2),
												[ENCOGIMIENTO LAVANDERIA T] decimal (18,2),
												ResultadoLaboratorio VARCHAR(1000),
												CodigoTelaMaster NUMERIC (18,0))
	INSERT INTO @tblfnPruenasLaboratorio
	(
		IdRollo,		[ENCOGIMIENTO (%) U],		[ENCOGIMIENTO (%) T],[ENCOGIMIENTO LAVANDERIA U], [ENCOGIMIENTO LAVANDERIA T],			[% SKEW Real],	ResultadoLaboratorio, CodigoTelaMaster
	)
	
	SELECT fnPruenasLaboratorio.IdRollo,
		  fnPruenasLaboratorio.[ENCOGIMIENTO (%) U] AS [Urd. Prueba Encogimiento],
		  fnPruenasLaboratorio.[ENCOGIMIENTO (%) T] AS [Trama Prueba Encogimiento],
         fnPruenasLaboratorio.[ENCOGIMIENTO LAVANDERIA U] AS [Urd. Prueba Lavanderia],
		 fnPruenasLaboratorio.[ENCOGIMIENTO LAVANDERIA T] AS [Trama. Prueba Lavanderia],
		 fnPruenasLaboratorio.[SKEW Real] Skew,
		ISNULL(fnPruenasLaboratorio.ResultadoLaboratorio, '') ResultadoLaboratorio, 
		@numCodTela
	FROM ControlTelas.dbo.fnAreaTextilTablaPruebasLaboratorio(@numCodTela,-1,@numCodigoEDP) fnPruenasLaboratorio
	
	SELECT  tr.IDRollo,
	       ti.NroImportacion [Impo/REM],
	       tr.NroRollo,
		   CAST(tr.Saldo AS NUMERIC(18, 2)) [Saldo Mtr],
	       cp.Clasificacion            Ubicacion,
	       ISNULL(CONVERT(VARCHAR, tt.[Urdimbre Minimo]) + ' a ' + CONVERT(VARCHAR, tt.[Urdimbre Maximo]),'') AS UrdimbreMaestroTela,
	       ISNULL(CONVERT(VARCHAR, tt.[Trama Minimo]) + ' a ' + CONVERT(VARCHAR, tt.[Trama Maximo]),'') AS TramaMaestroTela,
	       fnPruenasLaboratorio.[ENCOGIMIENTO (%) U] as [Urd. Prueba Encogimiento],
	        fnPruenasLaboratorio.[ENCOGIMIENTO (%) T] AS [Trama Prueba Encogimiento],
		   fnPruenasLaboratorio.[ENCOGIMIENTO LAVANDERIA U] AS [Urd. Prueba Lavanderia],
		   fnPruenasLaboratorio.[ENCOGIMIENTO LAVANDERIA T] AS [Trama. Prueba Lavanderia],
	        fnPruenasLaboratorio.[% SKEW Real] Skew,
	       ISNULL(fnPruenasLaboratorio.ResultadoLaboratorio, '') ResultadoLaboratorio
	FROM   TRollos tr
	       INNER JOIN Sici.GCT008.vTTelas AS tt
	            ON  tt.CodigoTela = tr.CodigoTela
	       INNER JOIN TImportacion  AS ti
	            ON  ti.CodigoImportacion = tr.NroImportacion
	       INNER JOIN TClasificacionProduccion cp
	            ON  cp.Codigo = tr.CodigoClasificacion
	       LEFT JOIN tblRollosXLoteSabanas
	            ON  tblRollosXLoteSabanas.IDRollo = tr.IDRollo
	            AND tblRollosXLoteSabanas.IdSabana = @numIdSabana
		    LEFT JOIN @tblfnPruenasLaboratorio AS fnPruenasLaboratorio
	            ON  fnPruenasLaboratorio.IdRollo = tr.IDRollo
            LEFT JOIN TListaEmpaque on TListaEmpaque.IDListaEmpaque = tr.IDListaEmpaque
       WHERE tr.CodigoTela = @numCodTela AND tblRollosXLoteSabanas.IDRollo IS NULL   AND (TListaEmpaque.SabanasAdelantadas = 1) 
			 AND MONTH(tr.FechaEntrada) > MONTH(GETDATE())-2 AND ti.NroImportacion = @varNroImportacion
		ORDER BY ti.NroImportacion
	

END
