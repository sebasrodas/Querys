USE [ControlTelas]
GO
/****** Object:  StoredProcedure [dbo].[SPInsertaDetallesMovRollos]    Script Date: 2021/06/08 10:11:53 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- SPInsertaDetallesMovRollos 302918,10, '800256193989'
ALTER PROCEDURE [dbo].[SPInsertaDetallesMovRollos]
	@IdEncMvtoRollos NUMERIC(18 ,0),
	@Cantidad NUMERIC(18 ,12),
	@UPC VARCHAR(12)
	
AS
BEGIN
    
    
      BEGIN TRAN TRANSINSERDETMOV
    
    BEGIN TRY
    
    --declaración de variables
    DECLARE @IDRollo            NUMERIC(38 ,0)
           ,@TipoMovimiento     INT
           ,@UDespachadas       NUMERIC(18 ,12)
           ,@UndsEntradas       NUMERIC(18 ,12)
           ,@TipoDocumento      INT;
    --se captura el id del rollo mandandole como parametro el UPC
    SELECT @IDRollo = IDRollo
    FROM   TRollos
    WHERE  (UPC=@UPC)
    
    --captutara que tipo de movimiento es
             SELECT @TipoDocumento = td.Codigo
        FROM   TMovimientoRollos_Enc AS tre
               INNER JOIN TTipoMovimientos AS tm
                    ON  tm.Codigo = tre.CodigoTipoMovimiento
               INNER JOIN TTipoDocumentos AS td
                    ON  td.Codigo = tm.CodigoTipoDocumento
        WHERE  tre.IdEncMvtoRollos = @IdEncMvtoRollos
        
        SELECT @TipoMovimiento = tre.CodigoTipoMovimiento
        FROM   TMovimientoRollos_Enc AS tre
        WHERE  tre.IdEncMvtoRollos = @IdEncMvtoRollos
    
    
    --captura la cantidad para el movimiento de transformacion ya que el programa tenia una validacion y esta se desmonto de devoluciones parciales y no capturaba la cantidad
    IF  (@TipoMovimiento=22)
    BEGIN
    	
    	SELECT @Cantidad = t.CantEntrada
    	FROM TRollos AS t
    	WHERE t.UPC = @UPC
    	
    END
    
    IF @Cantidad>0
    BEGIN

        
        
        IF (@TipoMovimiento IN (1)) --si es tipo de movimiento compra actualiza la tabla de trollos
        BEGIN
            IF NOT EXISTS (
                   SELECT tr.IDRollo
                   FROM   TMovimientosRollos AS tr
                          INNER JOIN TMovimientoRollos_Enc AS tre
                               ON  tre.IdEncMvtoRollos = tr.IdEncMvtoRollos
                   WHERE  tr.IDRollo = @IDRollo
                          AND tre.CodigoTipoMovimiento IN (1)
               )
            BEGIN
                INSERT INTO TMovimientosRollos
                  (
                    IdEncMvtoRollos
                   ,IDRollo
                   ,Cantidad
                  )
                VALUES
                  (
                    @IdEncMvtoRollos
                   ,@IDRollo
                   ,@Cantidad
                  )	
                
                UPDATE TRollos
                SET    CantRealEntrada = @Cantidad
						,SaldoTrazo = @Cantidad
                      --,Saldo = @Cantidad
                WHERE  IDRollo = @IDRollo
                
                SELECT 1 AS SW
            END
            ELSE
                SELECT 0 AS SW
        END
		ELSE
		IF (@TipoMovimiento IN (41)) --si es tipo de movimiento compra actualiza la tabla de trollos
        BEGIN
            IF NOT EXISTS (
                   SELECT tr.IDRollo
                   FROM   TMovimientosRollos AS tr
                          INNER JOIN TMovimientoRollos_Enc AS tre
                               ON  tre.IdEncMvtoRollos = tr.IdEncMvtoRollos
                   WHERE  tr.IDRollo = @IDRollo
                          AND tre.CodigoTipoMovimiento IN (41)
               )
            BEGIN
                INSERT INTO TMovimientosRollos
                  (
                    IdEncMvtoRollos
                   ,IDRollo
                   ,Cantidad
                  )
                VALUES
                  (
                    @IdEncMvtoRollos
                   ,@IDRollo
                   ,@Cantidad
                  )	
                
                UPDATE TRollos
                SET    CantRealEntrada = @Cantidad
						,SaldoTrazo = @Cantidad
                      --,Saldo = @Cantidad
                WHERE  IDRollo = @IDRollo
                
                SELECT 1 AS SW
            END
            ELSE
                SELECT 0 AS SW
        END
        ELSE 
        IF (@TipoMovimiento=22) --devolucion de trasformación
        BEGIN
            INSERT INTO TMovimientosRollos
              (
                IdEncMvtoRollos
               ,IDRollo
               ,Cantidad
              )
            VALUES
              (
                @IdEncMvtoRollos
               ,@IDRollo
               ,@Cantidad
              )     	
            
            UPDATE TRollos
            --si la cantidarelentrada = 0 la actualiza de lo contrario no la actualiza
                SET CantRealEntrada =  CASE WHEN CantRealEntrada = 0 THEN  @Cantidad   WHEN   CantRealEntrada <> 0 THEN CantRealEntrada END
                 -- el saldo ya se recalcula con sp recalcular saldo,Saldo = @Cantidad
                  ,CantDespachada = 0-- CantRealEntrada - Saldo
            WHERE  IDRollo = @IDRollo
            
            UPDATE TRollos
            SET    CodigoEstado = CASE 
                                       WHEN Saldo=0 THEN 7 ELSE 1  END
                  ,CantUltimoMov = @Cantidad
            WHERE  IDRollo = @IDRollo
            
            SELECT 1 AS SW
        END
        ELSE 
        IF EXISTS (
               SELECT tr.IDRollo
               FROM   TMovimientoRollos_Enc AS tre
                      INNER JOIN TMovimientosRollos AS tr
                           ON  tr.IdEncMvtoRollos = tre.IdEncMvtoRollos
               WHERE  tr.IDRollo = @IDRollo
                      AND tre.CodigoTipoMovimiento IN (1 ,22 ,29)
           ) --Existe una compra, una devolución de forro o una DEVOLUCION REPROCESO
        BEGIN
            INSERT INTO TMovimientosRollos
              (
                IdEncMvtoRollos
               ,IDRollo
               ,Cantidad
              )
            VALUES
              (
                @IdEncMvtoRollos
               ,@IDRollo
               ,CASE  WHEN @TipoDocumento = 1 THEN @Cantidad WHEN @TipoDocumento = 2 THEN -1*CONVERT(DECIMAL(21 ,12) ,@Cantidad) --CANTIDAD NEGATIVA
                          
                END
              
              )
            
            SET @UndsEntradas = 0
            SET @UDespachadas = 0
            
            --Filtro todo lo que se ha Comprado y devuelto de planta a bodega de telas
            SELECT @UndsEntradas = ISNULL(SUM(tr.Cantidad) ,0)
            FROM   TMovimientoRollos_Enc AS tre
                   INNER JOIN TTipoMovimientos
                        ON  tre.CodigoTipoMovimiento = TTipoMovimientos.Codigo
                   INNER JOIN TMovimientosRollos AS tr
                        ON  tr.IdEncMvtoRollos = tre.IdEncMvtoRollos
            WHERE  (
                       tr.IDRollo=@IDRollo
                       AND TTipoMovimientos.CodigoTipoDocumento IN (1)
                   )
            
            --Filtro todo lo que ha salido de la bodega de telas y los ajustes
            SELECT @UDespachadas = ISNULL(SUM(tr.Cantidad) ,0)
            FROM   TMovimientoRollos_Enc AS tre
                   INNER JOIN TTipoMovimientos
                        ON  tre.CodigoTipoMovimiento = TTipoMovimientos.Codigo
                   INNER JOIN TMovimientosRollos AS tr
                        ON  tr.IdEncMvtoRollos = tre.IdEncMvtoRollos
            WHERE  (
                       tr.IDRollo=@IDRollo
                       AND TTipoMovimientos.CodigoTipoDocumento IN (2 ,5)
            )
         
         
         EXEC spRecalcularSaldoRollo
         	@numRollo = @IDRollo
            --como el signo de la cantentrada en el mov es negativo se convierte para que el saldo quede en 0
            --UPDATE TRollos
            --SET    Saldo = @UndsEntradas+@UDespachadas
            --WHERE  (TRollos.IDRollo=@IDRollo)
            
            UPDATE TRollos
            SET    CantDespachada = CantRealEntrada- Saldo
            WHERE  (TRollos.IDRollo=@IDRollo)
            
            UPDATE TRollos
            SET    CodigoEstado = CASE 
                                       WHEN Saldo=0 THEN 7
                                       ELSE 1
                                  END
                  ,CantUltimoMov = @Cantidad
            WHERE  IDRollo = @IDRollo
            
            SELECT 1 AS SW
        END
        ELSE
        BEGIN
            SELECT 0 AS SW
        END
    END
    
        IF @TipoMovimiento = 4
    BEGIN
        UPDATE TControlTelaRechazada
        SET    EstadoReclamo     = 6
        WHERE  IDRollo           = @IDRollo
    END
    
    
            COMMIT TRAN TRANSINSERDETMOV
    END TRY 
    BEGIN CATCH
    
    --si la transaccion falla se elimina el encabezado 
    
    DELETE FROM TMovimientoRollos_Enc
    WHERE TMovimientoRollos_Enc.IdEncMvtoRollos = @IdEncMvtoRollos

		insert into tblCorteTransaccionMvtos(MensajeTransaccion)
		SELECT 'Ocurrio un Error: SPInsertaDetallesMovRollos '+ERROR_MESSAGE()+' en la línea '+CONVERT(NVARCHAR(255) ,ERROR_LINE()) + '.'
    
        --SELECT 'Ocurrio un Error: '+ERROR_MESSAGE()+' en la línea '+CONVERT(NVARCHAR(255) ,ERROR_LINE())
        --    +'.'
        
        ROLLBACK TRAN TRANSINSERDETMOV
    END CATCH
    
END
