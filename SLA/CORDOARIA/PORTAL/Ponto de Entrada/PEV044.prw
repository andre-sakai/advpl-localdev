User Function PEV044()

Local cParam := PARAMIXB[1]
Local aReturn := {} 


Do Case
     Case cParam == 1 //cabeГalho
//зддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд©
//Ё Campos a serem mostrados                      Ё
//юддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддды    
        aAdd( aReturn, { 'ORDERID', 'D' } )
//     aAdd( aReturn, 'CUSTOMERCODE')
        aAdd( aReturn, { 'CUSTOMERCODE', 'N', { 'BRWCUSTOMER', ;
                  { 'CCUSTOMERCODE', 'CCODE' }, ; 
                  { 'CCUSTOMERUNIT', 'CUNIT' } ;
                  }, ;
                  { 'CCODE', 'CUNIT', 'CDESCRIPTION' } } )
        aAdd( aReturn, 'CUSTOMERUNIT' )
        aAdd( aReturn, { 'DELIVERYCUSTOMER', 'N' } )
        aAdd( aReturn, { 'DELIVERYUNITCODE', 'N' } )

		// Transportadora
	    aAdd( aReturn, { 'CARRIERCODE', 'N', { 'GETCARRIER', ;
                           { 'CCARRIERCODE', 'CCODE' } ;
                                 }, ;
                          { 'CCODE', 'CDESCRIPTION' } } )             
                          
		//Redespacho		
		AAdd( aReturn, { "REDELIVERYCARRIERCODE", "N", { "GETCARRIER", ;
						 { 'REDELIVERYCARRIERCODE', 'CCODE' } ;
													}, ;
                          { 'CCODE', 'CDESCRIPTION' } } )
	   

        aAdd( aReturn, { 'PAYMENTPLANCODE', 'N', { 'BRWPAYMENTPLAN', ;
                 { 'CPAYMENTPLANCODE', 'CPAYMENTPLANCODE' } ;
               }, ;
               { 'CPAYMENTPLANCODE', 'CDESCRIPTIONPAYMENTPLAN' } } )
     aAdd( aReturn, { 'PAYMENTPLANCODE', 'D', { 'BRWPAYMENTPLAN', ;
                                   { 'CPAYMENTPLANCODE', 'CPAYMENTPLANCODE' } ;
                                   }, ;
                                   { 'CPAYMENTPLANCODE', 'CDESCRIPTIONPAYMENTPLAN' } } )
//     aAdd( aReturn, { 'PRICELISTCODE', 'N' } )
//     aAdd( aReturn, { 'DISCOUNT1', 'D' } )
//     aAdd( aReturn, { 'DISCOUNT2', 'D' } )
//     aAdd( aReturn, { 'DISCOUNT3', 'D' } )
//     aAdd( aReturn, { 'DISCOUNT4', 'D' } )
//     aAdd( aReturn, { 'BANKCODE' , 'D' } )
//     aAdd( aReturn, { 'FINANCIALDISCOUNT', 'D' } )
     aAdd( aReturn, { 'REGISTERDATE', 'D' } )
//     aAdd( aReturn, { 'BIDNUMBER', 'D'} )
//     aAdd( aReturn, { 'FREIGHTVALUE', 'D' } )
     aAdd( aReturn, { 'INSURANCEVALUE', 'D' } )
     aAdd( aReturn, { 'ADDITIONALEXPENSEVALUE', 'D' } )
     aAdd( aReturn, { 'INDEPENDENTFREIGHT', 'D' } )
     aAdd( aReturn, { 'ADJUSTMENTTYPE', 'D' } )
//     aAdd( aReturn, { 'SALESORDERCURRENCY', 'D' } )
//     aAdd( aReturn, { 'NETWEIGHT', 'D' } )
//     aAdd( aReturn, { 'GROSSWEIGHT', 'D' } )
//     aAdd( aReturn, { 'REDELIVERYCARRIERCODE', 'D' } )
//     aAdd( aReturn, { 'FINANCIALINCREASE', 'D' } )
     aAdd( aReturn, { 'INVOICEMESSAGE', 'N' } ) 
//     aAdd( aReturn, { 'STANDARDMESSAGE1', 'D' } )
//     aAdd( aReturn, { 'INDEMNITYVALUE', 'D' } )
//     aAdd( aReturn, { 'INDEMNITYPERCENTAGE', 'D' } )
	
// Campos Arteplas
	 aAdd( aReturn, { 'C5_OBS', 'N' } )        
	 aAdd( aReturn, { 'C5_TIPOENT', 'N' } )    
     
Case cParam == 2
     //зддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддд©
     //Ё Campos a serem mostrados                      Ё
     //юддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддддды
     aAdd( aReturn, { 'PRODUCTID', 'N', { 'GETCATALOG' , ;
                             { 'CPRODUCTID', 'CPRODUCTCODE' } ;
                             }, ;   
                             { 'CPRODUCTCODE', 'CDESCRIPTION' }, 13 } )
     aAdd( aReturn, { 'PRODUCTDESCRIPTION', 'N', 0, .F. } )
     aAdd( aReturn, { 'QUANTITY', 'N', 10 } )
     aAdd( aReturn, { 'NETUNITPRICE', 'N',0, .T. } )
     aAdd( aReturn, { 'ORDERITEM','D',1} ) 
     aAdd( aReturn, { 'NETTOTAL', 'N', 0, .F. } )
               
        
     aAdd( aReturn, {'ITEMOUTFLOWTYPE','N', { 'BRWOUTFLOWTYPE',;
                    {'CITEMOUTFLOWTYPE', 'CITEMOUTFLOWTYPE'};
                    },;
                    {'CITEMOUTFLOWTYPE'}})    
     
     aAdd( aReturn, 'DELIVERYDATE' )    


   
EndCase

Return aReturn
