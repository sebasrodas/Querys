USE [ControlTelas]
GO
/****** Object:  StoredProcedure [dbo].[SpUpdateMovimientosRollos]    Script Date: 2021/06/02 4:08:58 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  StoredProcedure [dbo].[SpUpdateMovimientosRollos]    Script Date: 10/13/2015 11:07:11 AM ******/

-- =============================================
-- Author:		<JMUNERA modificado por andres felipe escudero gutierrez>
-- Create date: <20150217>
-- Description:	<Se asigna la cantidad enviada por parámetro al campo CantRealEntrada y se asigna 0 al campo CantDespachada para los casos de movimiento tipo 22(DEVOLUCION TRANSFORMACION)>
-- =============================================

--EXEC SpUpdateMovimientosRollos '','',1,'005','005','005','na','aescudero'

ALTER PROCEDURE [dbo].[SpUpdateMovimientosRollos]
--@UPC VARCHAR(12),
	@Contrato VARCHAR(50),
	@Trazo VARCHAR(2),
	@CodigoTipoMovimiento INT,
	@CodigoResponsableEntrega VARCHAR(3),
	@CodigoResponsableRecibo VARCHAR(3),
	@CodigoSolicitadoPor VARCHAR(3),
	 --@Cantidad NUMERIC(18, 12),
	@Comentario VARCHAR(500),
	@Usuario VARCHAR(50),
	@Bodega VARCHAR(20),
	@Ubicacion VARCHAR(20),
	@Lote VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @CodigoUsuarioCrea     INT
           ,@IdEncabezadoRollo     INT;
    
    IF @Usuario LIKE '%JEANSSA%'
        SET @Usuario = REPLACE(REPLACE(@Usuario ,'JEANSSA\' ,'') ,'\' ,'')
    
    SELECT @CodigoUsuarioCrea = IdPersonal
    FROM   sici.dbo.Tbl_Personal
    WHERE  CuentaOutlook = @Usuario
    
    
    BEGIN TRAN InsertEnc
    
    BEGIN TRY
        INSERT INTO TMovimientoRollos_Enc
          (
            Contrato
           ,Trazo
           ,CodigoTipoMovimiento
           ,CodigoResponsableEntrega
           ,CodigoResponsableRecibo
           ,CodigoSolicitadoPor
           ,Comentario
           ,CodigoUsuario
		   ,Bodega
		   ,Ubicacion
		   ,LoteImpo
          )
        VALUES
          (
            @Contrato
           ,@Trazo
           ,@CodigoTipoMovimiento
           ,@CodigoResponsableEntrega
           ,@CodigoResponsableRecibo
           ,@CodigoSolicitadoPor
           ,@Comentario
           ,@CodigoUsuarioCrea
		   ,@Bodega
		   ,@Ubicacion
		   ,@Lote
          ) 
        
        SELECT @IdEncabezadoRollo = MAX(tre.IdEncMvtoRollos)
        FROM   TMovimientoRollos_Enc AS tre
        
        COMMIT TRAN InsertEnc
    END TRY 
    BEGIN CATCH
        --si devuelve el error el idencabezadorollo es 0 y no inserta el movimiento
        SELECT @IdEncabezadoRollo = 0;
        --SELECT 'Ocurrio un Error: '+ERROR_MESSAGE()+' en la línea '+CONVERT(NVARCHAR(255) ,ERROR_LINE())
        --    +'.'
        
        ROLLBACK TRAN InsertEnc
    END CATCH

    SELECT @IdEncabezadoRollo AS IdEncMvtoRollos
END



