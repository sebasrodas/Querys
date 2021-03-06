USE [ControlTelas]
GO
/****** Object:  StoredProcedure [dbo].[SpGetSabanasLista]    Script Date: 2021/06/03 4:34:51 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*
* =============================================
Modifica:	Carlos Alberto Correa Ortiz
Fecha:       09/14/2016
NroReqsis:	8798
Descripción: Se agrega el campo contrato y se configura el QUERY para que la información del detalle
no sólo sea la de la tabla Tbl_SabanasSeguimiento dado que el modelo permite guardar nulos los detalles de ésta tabla.
Para estos casos los detalles se traerían de las tablas asociadas a la tabla CONTRATOS de sici.   
=============================================

* SpGetSabanasLista 27930*/
ALTER PROCEDURE [dbo].[SpGetSabanasLista]
	@decIdSabana NUMERIC(18) = NULL
AS
BEGIN
	IF @decIdSabana = 0
	BEGIN
	    SELECT @decIdSabana = NULL
	END
	
	SELECT Tbl_SabanasSeguimiento.IdSabana AS Lote,
	       '' AS Contrato,
		   '' AS ContratoPadre,
	       ISNULL(TImportacion.NroImportacion, '') AS Impo,
	       UPPER(ISNULL(TTelas.Nombre,ISNULL(vTTelas.Nombre,'')))        AS Tela,
	       UPPER(ISNULL(Tbl_SabanasSeguimiento.Lavado, '')) Lavado,
	       UPPER(Sici.dbo.Clientes.Alias) AS Cliente,
	       ISNULL(Tbl_SabanasSeguimiento.Remision, '') Remision,
	       ISNULL(Tbl_SabanasSeguimiento.CantidadSabanas, 0) AS Cantidad,
	       Tbl_SabanasSeguimiento.FechaIngreso AS FechaEntrega,
	       CASE Tbl_SabanasSeguimiento.Estado
	            WHEN 0 THEN 'PENDIENTE'
	            ELSE 'TERMINADO'
	       END                          AS Estado,
	       Tbl_SabanasSeguimiento.FechaCierre AS FechaTerminado,
	       ISNULL(
	           CONVERT(
	               DECIMAL(18, 2),
	               ISNULL(Tbl_SabanasSeguimiento.FechaCierre, GETDATE()) - 
	               Tbl_SabanasSeguimiento.FechaIngreso
	           ),
	           0
	       )                            AS LeadTime,
	       ISNULL(Tbl_SabanasSeguimiento.CausasRechazo, '') CausasRechazo,
	       ISNULL(Tbl_SabanasSeguimiento.RechazoComments, '') ComentariosRechazo,
	       ISNULL(Tbl_SabanasSeguimiento.AccionesRetraso, '') AccionesRetraso,
	       ISNULL(Tbl_CausasDemoraSabanas.CausaDemora, '') AS CausaDemora,
	       ISNULL(RetrasoComments, '')     ComentariosRetraso,
	       ISNULL(Tbl_SabanasSeguimiento.Comentarios, '') AS 
	       ComentariosGenerales,
	       UPPER(ISNULL(Tbl_SabanasSeguimiento.Usuario, '')) AS Usuario,
	       '' NombreProducto,
	       '' Estilo,
	       ISNULL(Tbl_SabanasSeguimiento.ConsumoTela, 0) ConsumoTela,
	       ISNULL(Tbl_SabanasSeguimiento.TotalUnidades, 0) TotalUnidades,
	       ISNULL(Tbl_SabanasSeguimiento.ConsumoTela, 0) * ISNULL(Tbl_SabanasSeguimiento.TotalUnidades, 0) AS 
	       MetrosNecesarios,
	       CASE 
	            WHEN Tbl_SabanasSeguimiento.CausasRechazo LIKE '%Tono%' THEN 1
	            ELSE 0
	       END                          AS Tono,
	       CASE 
	            WHEN Tbl_SabanasSeguimiento.CausasRechazo LIKE '%Matiz%' THEN 1
	            ELSE 0
	       END                          AS Matiz,
	       CASE 
	            WHEN Tbl_SabanasSeguimiento.CausasRechazo LIKE '%Abrasión%' THEN 
	                 1
	            ELSE 0
	       END                          AS Abrasion,
	       CASE 
	            WHEN Tbl_SabanasSeguimiento.AccionesRetraso LIKE 
	                 '%Reformulación%' THEN 1
	            ELSE 0
	       END                          AS Reformulacion,
	       CASE 
	            WHEN Tbl_SabanasSeguimiento.AccionesRetraso LIKE 
	                 '%Proceso Adicional%' THEN 1
	            ELSE 0
	       END                          AS ProcesoAdicional,
	       CASE 
	            WHEN Tbl_SabanasSeguimiento.AccionesRetraso LIKE '%Reproceso%' THEN 
	                 1
	            ELSE 0
	       END                          AS Reproceso,
	       CASE 
	            WHEN Tbl_SabanasSeguimiento.AccionesRetraso LIKE 
	                 '%Cambio de Prioridad%' THEN 1
	            ELSE 0
	       END                          AS Prioridad,
	       CASE 
	            WHEN Tbl_SabanasSeguimiento.AccionesRetraso LIKE '%Otros%' THEN 
	                 1
	            ELSE 0
	       END                          AS Otros,
	       ISNULL(TTelas.CodigoTelaMaster,ISNULL(CAST(vTTelas.Item AS VARCHAR(50)),'')) AS CodigoTelaMaster,
	       '' EDPCliente,
	       '' TipoContrato,
	       ISNULL(Tbl_SabanasSeguimiento.Responsablewash, 0) Responsablewash,
	       Tbl_SabanasSeguimiento.NoEnviarAWash,
		   isnull(tblSabanasConsideracionesGenerales.NombreConsideracion,'') as [Consideracion General],
		   ISNULL(TPruebasLaboratorio.NombrePrueba,'') as [Tipo Analisis] ,
		   ISNULL(ltrim(rtrim(TopeRes.Nombre)) + ' '+ ltrim(rtrim(TopeRes.Apellidos)),'') AS ResponsableDigitacion,
		   ISNULL(ltrim(rtrim(ToperResAprobacion.Nombre)) + ' '+ ltrim(rtrim(ToperResAprobacion.Apellidos)),'') AS ResponsableAprobacion
	FROM   Tbl_SabanasSeguimiento
	       /*2/18/2021 dporras; añadimos la vista de telas que obtiene la informacion desde siesa*/
		   LEFT JOIN Sici.GCT008.vTTelas AS TTelas
	            ON  Tbl_SabanasSeguimiento.CodTela = TTelas.Item
				AND Tbl_SabanasSeguimiento.LogMigracionSiesa = 0
		   LEFT JOIN Sici.GCT008.vTTelas 
		        ON   CAST(vTTelas.Item AS VARCHAR(50)) = Tbl_SabanasSeguimiento.CodTela
				AND Tbl_SabanasSeguimiento.LogMigracionSiesa = 0
	       LEFT OUTER JOIN TImportacion
	            ON  Tbl_SabanasSeguimiento.Impo = TImportacion.CodigoImportacion
	       INNER JOIN Sici.dbo.Clientes
	            ON  Tbl_SabanasSeguimiento.ClienteNit = Sici.dbo.Clientes.Nit
	       LEFT OUTER JOIN Tbl_CausasDemoraSabanas
	            ON  Tbl_SabanasSeguimiento.IdCausaDemora = 
	                Tbl_CausasDemoraSabanas.IdCausaDemora
		   LEFT JOIN tblSabanasConsideracionesGenerales 
				ON tblSabanasConsideracionesGenerales.idConsideracionesGenerales = Tbl_SabanasSeguimiento.idConsideracionesGenerales
		   LEFT JOIN TPruebasLaboratorio 
				ON TPruebasLaboratorio.IdPruebaLab = Tbl_SabanasSeguimiento.idTipoAnalisis
		   LEFT JOIN ControlPiso.dbo.Toperarios TopeRes
		   ON TopeRes.IDOperario = 	Tbl_SabanasSeguimiento.idResponsableDigitacion
		   LEFT JOIN ControlPiso.dbo.Toperarios ToperResAprobacion
		   ON ToperResAprobacion.IDOperario = Tbl_SabanasSeguimiento.idResponsableAprobacion
	WHERE  (
	           LEN(Tbl_SabanasSeguimiento.Contrato) = 0
	           OR Tbl_SabanasSeguimiento.Contrato IS NULL
	       )
	       AND Tbl_SabanasSeguimiento.IdSabana = ISNULL(@decIdSabana, Tbl_SabanasSeguimiento.IdSabana)
	UNION 
	-------------------------*****************************CONTRATOS sici***************************************************************
	SELECT Tbl_SabanasSeguimiento.IdSabana AS Lote,
	       Tbl_SabanasSeguimiento.Contrato,
		   ISNULL(Tbl_SabanasSeguimiento.ContratoPadre,'') AS ContratoPadre,
	       '' AS                           Impo,
	       UPPER(ISNULL(TTelas.Nombre,ISNULL(vTTelas.Nombre,'')))         AS Tela,
	       UPPER(TLavado.Nombre)           Lavado,
	       UPPER(Clientes.Alias)        AS Cliente,
	       UPPER(ISNULL(Tbl_SabanasSeguimiento.Remision, '')) Remision,
	       ISNULL(Tbl_SabanasSeguimiento.CantidadSabanas, 0) AS Cantidad,
	       Tbl_SabanasSeguimiento.FechaIngreso AS FechaEntrega,
	       CASE Tbl_SabanasSeguimiento.Estado
	            WHEN 0 THEN 'PENDIENTE'
	            ELSE 'TERMINADO'
	       END                          AS Estado,
	       Tbl_SabanasSeguimiento.FechaCierre AS FechaTerminado,
	       ISNULL(
	           CONVERT(
	               DECIMAL(18, 2),
	               ISNULL(Tbl_SabanasSeguimiento.FechaCierre, GETDATE()) - 
	               Tbl_SabanasSeguimiento.FechaIngreso
	           ),
	           0
	       )                            AS LeadTime,
	       ISNULL(Tbl_SabanasSeguimiento.CausasRechazo, '') CausasRechazo,
	       ISNULL(Tbl_SabanasSeguimiento.RechazoComments, '') ComentariosRechazo,
	       ISNULL(Tbl_SabanasSeguimiento.AccionesRetraso, '') AccionesRetraso,
	       ISNULL(Tbl_CausasDemoraSabanas.CausaDemora, '') AS CausaDemora,
	       ISNULL(RetrasoComments, '')     ComentariosRetraso,
	       ISNULL(Tbl_SabanasSeguimiento.Comentarios, '') AS 
	       ComentariosGenerales,
	       UPPER(ISNULL(Tbl_SabanasSeguimiento.Usuario, '')) AS Usuario,
	       TProductos.NombreProducto,
	       UPPER(TEstilos.Nombre)       AS Estilo,
	       ISNULL(
	           TCIP.ConsumoTela,
	           ISNULL(Tbl_SabanasSeguimiento.ConsumoTela, 0)
	       )                               ConsumoTela,
	       ISNULL(
	           Contratos.TotalUnidades,
	           ISNULL(Tbl_SabanasSeguimiento.TotalUnidades, 0)
	       )                               TotalUnidades,
	       ISNULL(
	           TCIP.ConsumoTela,
	           ISNULL(Tbl_SabanasSeguimiento.ConsumoTela, 0)
	       ) *
	       ISNULL(
	           Contratos.TotalUnidades,
	           ISNULL(Tbl_SabanasSeguimiento.TotalUnidades, 0)
	       )                            AS MetrosNecesarios,
	       CASE 
	            WHEN Tbl_SabanasSeguimiento.CausasRechazo LIKE '%Tono%' THEN 1
	            ELSE 0
	       END                          AS Tono,
	       CASE 
	            WHEN Tbl_SabanasSeguimiento.CausasRechazo LIKE '%Matiz%' THEN 1
	            ELSE 0
	       END                          AS Matiz,
	       CASE 
	            WHEN Tbl_SabanasSeguimiento.CausasRechazo LIKE '%Abrasión%' THEN 
	                 1
	            ELSE 0
	       END                          AS Abrasion,
	       CASE 
	            WHEN Tbl_SabanasSeguimiento.AccionesRetraso LIKE 
	                 '%Reformulación%' THEN 1
	            ELSE 0
	       END                          AS Reformulacion,
	       CASE 
	            WHEN Tbl_SabanasSeguimiento.AccionesRetraso LIKE 
	                 '%Proceso Adicional%' THEN 1
	            ELSE 0
	       END                          AS ProcesoAdicional,
	       CASE 
	            WHEN Tbl_SabanasSeguimiento.AccionesRetraso LIKE '%Reproceso%' THEN 
	                 1
	            ELSE 0
	       END                          AS Reproceso,
	       CASE 
	            WHEN Tbl_SabanasSeguimiento.AccionesRetraso LIKE 
	                 '%Cambio de Prioridad%' THEN 1
	            ELSE 0
	       END                          AS Prioridad,
	       CASE 
	            WHEN Tbl_SabanasSeguimiento.AccionesRetraso LIKE '%Otros%' THEN 
	                 1
	            ELSE 0
	       END                          AS Otros,
	       ISNULL(TTelas.CodigoTelaMaster,ISNULL(CAST(vTTelas.Item AS VARCHAR(50)),'')) AS CodigoTelaMaster,
	       UPPER(TEDPCliente.Nombre)    AS EDPCliente,
	       Tbl_Contratos.TipoContrato,
	       ISNULL(Tbl_SabanasSeguimiento.Responsablewash, 0) Responsablewash,
	       Tbl_SabanasSeguimiento.NoEnviarAWash,
		   ISNULL(tblSabanasConsideracionesGenerales.NombreConsideracion,'') as  [Consideracion General],
		   ISNULL(TPruebasLaboratorio.NombrePrueba,'') as [Tipo Analisis] ,
		   ISNULL(ltrim(rtrim(TopeRes.Nombre)) + ' '+ ltrim(rtrim(TopeRes.Apellidos)),'') AS ResponsableDigitacion,
		   ISNULL(ltrim(rtrim(ToperResAprobacion.Nombre)) + ' '+ ltrim(rtrim(ToperResAprobacion.Apellidos)),'') AS ResponsableAprobacion
	FROM   Tbl_SabanasSeguimiento
	       INNER JOIN Sici.dbo.Tbl_Contratos Tbl_Contratos
	            ON  Tbl_Contratos.Contrato = Tbl_SabanasSeguimiento.Contrato
	       INNER JOIN Sici.dbo.Contratos Contratos
	            ON  Tbl_Contratos.ContratoCer = Contratos.Contrato
	       INNER JOIN Sici.dbo.TProductos TProductos
	            ON  Contratos.NroProducto = TProductos.NroProducto
		   /*2/18/2021 dporras; añadimos la vista de telas que obtiene la informacion desde siesa*/
	       --INNER JOIN TTelas
	       --     ON  TProductos.CodigoTelaMaster = TTelas.CodigoTelaMaster
		   LEFT JOIN TTelas
	            ON  TProductos.CodigoTelaMaster = TTelas.CodigoTelaMaster
				AND Tbl_SabanasSeguimiento.LogMigracionSiesa = 0
		   LEFT JOIN Sici.GCT008.vTTelas 
		        ON  TProductos.CodigoTelaMaster = CAST(vTTelas.Item AS VARCHAR(50))
				AND Tbl_SabanasSeguimiento.LogMigracionSiesa = 0
	       LEFT OUTER JOIN Tbl_CausasDemoraSabanas
	            ON  Tbl_SabanasSeguimiento.IdCausaDemora = 
	                Tbl_CausasDemoraSabanas.IdCausaDemora
	       INNER JOIN Sici.dbo.Clientes Clientes
	            ON  Contratos.Cliente_Nit = Clientes.Nit
	       INNER JOIN Sici.dbo.TEstilos TEstilos
	            ON  TProductos.CodigoEstilo = TEstilos.CodigoEstilo
	       INNER JOIN Sici.dbo.TLavado TLavado
	            ON  TProductos.CodigoLavado = TLavado.CodigoLavado
	       LEFT OUTER JOIN (
	                SELECT Insumo,
	                       NroProducto,
	                       MAX(ConsumoTela) AS ConsumoTela
	                FROM   Sici.dbo.TCIP AS TCIP_1
	                GROUP BY
	                       Insumo,
	                       NroProducto
	            )                       AS TCIP
	            ON  ISNULL(TTelas.CodigoTelaMaster,vTTelas.Item) = TCIP.Insumo
	            AND TProductos.NroProducto = TCIP.NroProducto
	       LEFT OUTER JOIN Sici.dbo.TEDPCliente TEDPCliente
	            ON  TProductos.CodigoEDPCliente = TEDPCliente.Codigo
					   LEFT JOIN tblSabanasConsideracionesGenerales 
				ON tblSabanasConsideracionesGenerales.idConsideracionesGenerales = Tbl_SabanasSeguimiento.idConsideracionesGenerales
           LEFT JOIN TPruebasLaboratorio 
				ON TPruebasLaboratorio.IdPruebaLab = Tbl_SabanasSeguimiento.idTipoAnalisis
		   LEFT JOIN ControlPiso.dbo.Toperarios TopeRes
				ON TopeRes.IDOperario = 	Tbl_SabanasSeguimiento.idResponsableDigitacion
		   LEFT JOIN ControlPiso.dbo.Toperarios ToperResAprobacion
				ON ToperResAprobacion.IDOperario = Tbl_SabanasSeguimiento.idResponsableAprobacion
	WHERE  LEN(Tbl_SabanasSeguimiento.Contrato) > 0
	       AND Tbl_SabanasSeguimiento.IdSabana = ISNULL(@decIdSabana, Tbl_SabanasSeguimiento.IdSabana)
	UNION
	-------------------------****************************************CONTRATOS PROTOS**************************************************
	/************************************************************
	* Code formatted by SoftTree SQL Assistant © v7.0.158
	* Time: 9/14/2016 2:36:28 PM
	************************************************************/
	
	SELECT Tbl_SabanasSeguimiento.IdSabana AS Lote,
	       Tbl_SabanasSeguimiento.Contrato Contrato,
		   ISNULL(Tbl_SabanasSeguimiento.ContratoPadre,'') AS ContratoPadre,
	       '' AS                            Impo,
	       UPPER(ISNULL(TTelas.Nombre,ISNULL(vTTelas.Nombre,'')))          AS Tela,
	       UPPER(Tbl_Lavados_Protos.Color) Lavado,
	       UPPER(Clientes_Protos.Alias)  AS Cliente,
	       ISNULL(Tbl_SabanasSeguimiento.Remision, '') Remision,
	       ISNULL(Tbl_SabanasSeguimiento.CantidadSabanas, 0) AS Cantidad,
	       Tbl_SabanasSeguimiento.FechaIngreso AS FechaEntrega,
	       CASE Tbl_SabanasSeguimiento.Estado
	            WHEN 0 THEN 'PENDIENTE'
	            ELSE 'TERMINADO'
	       END                           AS Estado,
	       Tbl_SabanasSeguimiento.FechaCierre AS FechaTerminado,
	       ISNULL(
	           CONVERT(
	               DECIMAL(18, 2),
	               ISNULL(Tbl_SabanasSeguimiento.FechaCierre, GETDATE()) - 
	               Tbl_SabanasSeguimiento.FechaIngreso
	           ),
	           0
	       )                             AS LeadTime,
	       ISNULL(Tbl_SabanasSeguimiento.CausasRechazo, '') CausasRechazo,
	       ISNULL(Tbl_SabanasSeguimiento.RechazoComments, '') ComentariosRechazo,
	       ISNULL(Tbl_SabanasSeguimiento.AccionesRetraso, '') AccionesRetraso,
	       ISNULL(Tbl_CausasDemoraSabanas.CausaDemora, '') AS CausaDemora,
	       ISNULL(RetrasoComments, '')      ComentariosRetraso,
	       ISNULL(Tbl_SabanasSeguimiento.Comentarios, '') AS 
	       ComentariosGenerales,
	       UPPER(ISNULL(Tbl_SabanasSeguimiento.Usuario, '')) AS Usuario,
	       '' NombreProducto,
	       UPPER(Tbl_Estilos_Protos.Style) Estilo,
	       ISNULL(Tbl_SabanasSeguimiento.ConsumoTela, 0) ConsumoTela,
	       SUM(Tbl_TelaLavadoProto.Units) AS TotalUnidades,
	       ISNULL(Tbl_SabanasSeguimiento.ConsumoTela, 0) * SUM(Tbl_TelaLavadoProto.Units) 
	       MetrosNecesarios,
	       CASE 
	            WHEN Tbl_SabanasSeguimiento.CausasRechazo LIKE '%Tono%' THEN 1
	            ELSE 0
	       END                           AS Tono,
	       CASE 
	            WHEN Tbl_SabanasSeguimiento.CausasRechazo LIKE '%Matiz%' THEN 1
	            ELSE 0
	       END                           AS Matiz,
	       CASE 
	            WHEN Tbl_SabanasSeguimiento.CausasRechazo LIKE '%Abrasión%' THEN 
	                 1
	            ELSE 0
	       END                           AS Abrasion,
	       CASE 
	            WHEN Tbl_SabanasSeguimiento.AccionesRetraso LIKE 
	                 '%Reformulación%' THEN 1
	            ELSE 0
	       END                           AS Reformulacion,
	       CASE 
	            WHEN Tbl_SabanasSeguimiento.AccionesRetraso LIKE 
	                 '%Proceso Adicional%' THEN 1
	            ELSE 0
	       END                           AS ProcesoAdicional,
	       CASE 
	            WHEN Tbl_SabanasSeguimiento.AccionesRetraso LIKE '%Reproceso%' THEN 
	                 1
	            ELSE 0
	       END                           AS Reproceso,
	       CASE 
	            WHEN Tbl_SabanasSeguimiento.AccionesRetraso LIKE 
	                 '%Cambio de Prioridad%' THEN 1
	            ELSE 0
	       END                           AS Prioridad,
	       CASE 
	            WHEN Tbl_SabanasSeguimiento.AccionesRetraso LIKE '%Otros%' THEN 
	                 1
	            ELSE 0
	       END                           AS Otros,
	       ISNULL(TTelas.CodigoTelaMaster,ISNULL(CAST(vTTelas.Item AS VARCHAR(50)),'')) AS CodigoTelaMaster,
	       UPPER(Tbl_Lavados_Protos.Color) EDPCliente,
	       '' TipoContrato,
	       ISNULL(Tbl_SabanasSeguimiento.Responsablewash, 0) Responsablewash,
	       Tbl_SabanasSeguimiento.NoEnviarAWash,
		   ISNULL(tblSabanasConsideracionesGenerales.NombreConsideracion,'') as  [Consideracion General],
		   ISNULL(TPruebasLaboratorio.NombrePrueba,'') as [Tipo Analisis] ,
		   ISNULL(ltrim(rtrim(TopeRes.Nombre)) + ' '+ ltrim(rtrim(TopeRes.Apellidos)),'') AS ResponsableDigitacion,
		   ISNULL(ltrim(rtrim(ToperResAprobacion.Nombre)) + ' '+ ltrim(rtrim(ToperResAprobacion.Apellidos)),'') AS ResponsableAprobacion
	FROM   Tbl_SabanasSeguimiento
	       LEFT OUTER JOIN Tbl_CausasDemoraSabanas
	            ON  Tbl_SabanasSeguimiento.IdCausaDemora = 
	                Tbl_CausasDemoraSabanas.IdCausaDemora
	       INNER JOIN Sici.dbo.Tbl_Protos Tbl_Protos
	            ON  Tbl_Protos.Proto = Tbl_SabanasSeguimiento.Contrato
	       INNER JOIN Sici.dbo.Tbl_TelaLavadoProto Tbl_TelaLavadoProto
	            ON  Tbl_Protos.IdProto = Tbl_TelaLavadoProto.IdProto
	       INNER JOIN Sici.dbo.Tbl_TelaProveedor_Protos 
	            Tbl_TelaProveedor_Protos
	            ON  Tbl_TelaLavadoProto.IdFabric = Tbl_TelaProveedor_Protos.IdFabric
	       --INNER JOIN TTelas
	       --     ON  Tbl_TelaProveedor_Protos.CodigoTelaMaster = TTelas.CodigoTelaMaster

		   /*2/18/2021 dporras; añadimos la vista de telas que obtiene la informacion desde siesa*/
		   LEFT JOIN TTelas
	            ON  Tbl_TelaProveedor_Protos.CodigoTelaMaster = TTelas.CodigoTelaMaster
				AND Tbl_SabanasSeguimiento.LogMigracionSiesa = 0
		   LEFT JOIN Sici.GCT008.vTTelas 
		        ON CAST(vTTelas.Item AS VARCHAR(50)) = Tbl_TelaProveedor_Protos.CodigoTelaMaster
				AND Tbl_SabanasSeguimiento.LogMigracionSiesa = 0
	       INNER JOIN Sici.dbo.Clientes_Protos Clientes_Protos
	            ON  Tbl_Protos.IdCliente = Clientes_Protos.IdCliente
	       INNER JOIN Sici.dbo.Tbl_Estilos_Protos Tbl_Estilos_Protos
	            ON  Tbl_Protos.IdStyle = Tbl_Estilos_Protos.IdStyle
	       INNER JOIN Sici.dbo.Tbl_Lavados_Protos Tbl_Lavados_Protos
	            ON  Tbl_TelaLavadoProto.IdColor = Tbl_Lavados_Protos.IdColor
		   LEFT JOIN tblSabanasConsideracionesGenerales 
				ON tblSabanasConsideracionesGenerales.idConsideracionesGenerales = Tbl_SabanasSeguimiento.idConsideracionesGenerales
           LEFT JOIN TPruebasLaboratorio 
				ON TPruebasLaboratorio.IdPruebaLab = Tbl_SabanasSeguimiento.idTipoAnalisis
		   LEFT JOIN ControlPiso.dbo.Toperarios TopeRes
		        ON TopeRes.IDOperario = 	Tbl_SabanasSeguimiento.idResponsableDigitacion
		   LEFT JOIN ControlPiso.dbo.Toperarios ToperResAprobacion
				ON ToperResAprobacion.IDOperario = Tbl_SabanasSeguimiento.idResponsableAprobacion
	WHERE  LEN(Tbl_SabanasSeguimiento.Contrato) > 0
	       AND Tbl_SabanasSeguimiento.IdSabana = ISNULL(@decIdSabana, Tbl_SabanasSeguimiento.IdSabana)
		   AND ISNULL(TTelas.CodigoTelaMaster,vTTelas.Item) IS NOT NULL
	GROUP BY
	       Tbl_SabanasSeguimiento.IdSabana,
	       Tbl_SabanasSeguimiento.Contrato,
		   UPPER(ISNULL(TTelas.Nombre,ISNULL(vTTelas.Nombre,''))),
		   ISNULL(Tbl_SabanasSeguimiento.ContratoPadre,''),
	       UPPER(ISNULL(TTelas.Nombre,ISNULL(vTTelas.Item,''))),  
	       UPPER(ISNULL(Tbl_SabanasSeguimiento.Lavado, '')),
	       UPPER(Clientes_Protos.Alias),
	       ISNULL(Tbl_SabanasSeguimiento.Remision, ''),
	       ISNULL(Tbl_SabanasSeguimiento.CantidadSabanas, 0),
	       Tbl_SabanasSeguimiento.FechaIngreso,
	       CASE Tbl_SabanasSeguimiento.Estado
	            WHEN 0 THEN 'PENDIENTE'
	            ELSE                        'TERMINADO'
	       END,
	       Tbl_SabanasSeguimiento.FechaCierre,
	       CONVERT(
	           DECIMAL(18, 2),
	           ISNULL(Tbl_SabanasSeguimiento.FechaCierre, GETDATE()) - 
	           Tbl_SabanasSeguimiento.FechaIngreso
	       ),
	       ISNULL(Tbl_SabanasSeguimiento.CausasRechazo, ''),
	       ISNULL(Tbl_SabanasSeguimiento.RechazoComments, ''),
	       ISNULL(Tbl_SabanasSeguimiento.AccionesRetraso, ''),
	       ISNULL(Tbl_CausasDemoraSabanas.CausaDemora, ''),
	       ISNULL(Tbl_SabanasSeguimiento.RetrasoComments, ''),
	       Tbl_SabanasSeguimiento.Comentarios,
	       UPPER(ISNULL(Tbl_SabanasSeguimiento.Usuario, '')),
	       UPPER(Tbl_Estilos_Protos.Style),
	       UPPER(Tbl_Lavados_Protos.Color),
	       ISNULL(Tbl_SabanasSeguimiento.ConsumoTela, 0),
	       Tbl_SabanasSeguimiento.CausasRechazo,
	       Tbl_SabanasSeguimiento.RechazoComments,
	       Tbl_SabanasSeguimiento.AccionesRetraso,
	       RetrasoComments,
	       ISNULL(TTelas.CodigoTelaMaster,ISNULL(CAST(vTTelas.Item AS VARCHAR(50)),'')),
	       ISNULL(Tbl_SabanasSeguimiento.Responsablewash, 0),
	       Tbl_SabanasSeguimiento.NoEnviarAWash,
		   ISNULL(tblSabanasConsideracionesGenerales.NombreConsideracion,''),
		   ISNULL(TPruebasLaboratorio.NombrePrueba,''),
		   ISNULL(ltrim(rtrim(TopeRes.Nombre)) + ' '+ ltrim(rtrim(TopeRes.Apellidos)),'') ,
		   ISNULL(ltrim(rtrim(ToperResAprobacion.Nombre)) + ' '+ ltrim(rtrim(ToperResAprobacion.Apellidos)),'') 
	ORDER BY
	       Tbl_SabanasSeguimiento.FechaIngreso DESC
END
