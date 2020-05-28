#include 'protheus.ch'
#include 'parmtype.ch'
#include "Fileio.ch"


user function CEKA002()

Local _aProdutos := {}

If(Select("SX2")=0)
	RpcSetType(3)          
	RpcSetEnv("01" ,"0101", "","","","",{"SB1","SBM"})   	    	  
	_lPrepEnv := .T.
EndIf


dbselectarea('SB1')
dbsetorder(1)


_aProdutos := {'ADE0000      ',;
'CEK041BRA    ',;
'CEK041MRH    ',;
'CEK041PRM    ',;
'CEK041PTC    ',;
'CEK041PTS    ',;
'CEK041VDB    ',;
'CEK041VMC    ',;
'CEK041VMT    ',;
'CEK110AZI    ',;
'CEK110BRC    ',;
'CEK110CZI    ',;
'CEK110CZN    ',;
'CEK110MRT    ',;
'CEK110PRC    ',;
'CEK110PRS    ',;
'CEK110PRV    ',;
'CEK110PTF    ',;
'CEK110PTM    ',;
'CEK111AZI    ',;
'CEK111BRC    ',;
'CEK111CZI    ',;
'CEK111MRT    ',;
'CEK111PRS    ',;
'CEK111PRV    ',;
'CEK111PTM    ',;
'CEK175BRE    ',;
'CEK175CZH    ',;
'CEK175PRE    ',;
'CEK175PTE    ',;
'CEK176BRA    ',;
'CEK176PRR    ',;
'CEK176PTO    ',;
'CEK177BRA    ',;
'CEK177CZL    ',;
'CEK177PRC    ',;
'CEK177PRR    ',;
'CEK177PRT    ',;
'CEK177PTF    ',;
'CEK177PTO    ',;
'CEK177VMR    ',;
'CEK178BRA    ',;
'CEK178PRR    ',;
'CEK178PTO    ',;
'CEK179BRP    ',;
'CEK179PRC    ',;
'CEK179PTO    ',;
'CEK180BRP    ',;
'CEK180PRC    ',;
'CEK180PTO    ',;
'CEK210BRA    ',;
'CEK210PRE    ',;
'CEK210PTE    ',;
'CEK211BRA    ',;
'CEK211BRV    ',;
'CEK211PRE    ',;
'CEK211PRR    ',;
'CEK211PTE    ',;
'CEK211PTF    ',;
'CEK211VMA    ',;
'CEK244BRG    ',;
'CEK244PRB    ',;
'CEK244PTP    ',;
'CEK244VDA    ',;
'CEK273AZA    ',;
'CEK273BRA    ',;
'CEK273BRS    ',;
'CEK273CZU    ',;
'CEK273PRA    ',;
'CEK273PRG    ',;
'CEK273PTG    ',;
'CEK273VMB    ',;
'CEK275AZM    ',;
'CEK275BRA    ',;
'CEK275CZM    ',;
'CEK275PMR    ',;
'CEK275PRE    ',;
'CEK275PRG    ',;
'CEK275PRV    ',;
'CEK275PTF    ',;
'CEK275PTG    ',;
'CEK275VMB    ',;
'CEK275VMT    ',;
'CEK276AZM    ',;
'CEK276BRA    ',;
'CEK276CZM    ',;
'CEK276PMR    ',;
'CEK276PRE    ',;
'CEK276PRG    ',;
'CEK276PRV    ',;
'CEK276PTG    ',;
'CEK276VMB    ',;
'CEK276VMT    ',;
'CEK280BRD    ',;
'CEK280PRC    ',;
'CEK280PTE    ',;
'CEK281BRD    ',;
'CEK281CZU    ',;
'CEK281PRC    ',;
'CEK281PRE    ',;
'CEK281PTE    ',;
'CEK300BRC    ',;
'CEK300BRW    ',;
'CEK300CZC    ',;
'CEK300CZM    ',;
'CEK300PRC    ',;
'CEK300PRM    ',;
'CEK300PTE    ',;
'CEK305BRP    ',;
'CEK305BRV    ',;
'CEK305BRW    ',;
'CEK305CZC    ',;
'CEK305PRM    ',;
'CEK305PTE    ',;
'CEK308PTO    ',;
'CEK310BRL    ',;
'CEK310PRL    ',;
'CEK310PTE    ',;
'CEK311BRC    ',;
'CEK311BRL    ',;
'CEK311PRL    ',;
'CEK311PTE    ',;
'CEK312BRL    ',;
'CEK312PRL    ',;
'CEK312PTE    ',;
'CEK320BRA    ',;
'CEK320PRG    ',;
'CEK320PTM    ',;
'CEK320VMP    ',;
'CEK344BRS    ',;
'CEK344CZS    ',;
'CEK344GRM    ',;
'CEK344PRM    ',;
'CEK344PTP    ',;
'CEK344VMF    ',;
'CEK410PRN    ',;
'CEK410PTM    ',;
'CEK450BRG    ',;
'CEK450CZA    ',;
'CEK450MRS    ',;
'CEK450PRE    ',;
'CEK450PTN    ',;
'CEK450VMV    ',;
'CEK451BRN    ',;
'CEK451CZA    ',;
'CEK451MRS    ',;
'CEK451PRE    ',;
'CEK451PTN    ',;
'CEK451VMF    ',;
'CEK451VMV    ',;
'CEK540BRW    ',;
'CEK540PRS    ',;
'CEK540PTC    ',;
'CEK550BRW    ',;
'CEK550PRS    ',;
'CEK550PTC    ',;
'CEK551BRW    ',;
'CEK551PRS    ',;
'CEK551PTC    ',;
'CEK552BRW    ',;
'CEK552PRS    ',;
'CEK552PTC    ',;
'CEK560BRW    ',;
'CEK560PRS    ',;
'CEK560PTC    ',;
'CEK561BRW    ',;
'CEK561PRS    ',;
'CEK561PTC    ',;
'CEK562AZM    ',;
'CEK562BRN    ',;
'CEK562PRB    ',;
'CEK562PRM    ',;
'CEK562PTC    ',;
'CEK562VMI    ',;
'CEK623AZM    ',;
'CEK623BRS    ',;
'CEK623BRV    ',;
'CEK623CZA    ',;
'CEK623CZM    ',;
'CEK623PRS    ',;
'CEK623PTC    ',;
'CEK623PTF    ',;
'CEK625BRM    ',;
'CEK625PRS    ',;
'CEK625PTC    ',;
'CEK625PTF    ',;
'CEK625VMC    ',;
'CEK630AZP    ',;
'CEK630BRM    ',;
'CEK630CZA    ',;
'CEK630PRP    ',;
'CEK630PTC    ',;
'CEK630PTL    ',;
'CEK630PTS    ',;
'CEK630VDG    ',;
'CEK631BRM    ',;
'CEK631PRP    ',;
'CEK631PTC    ',;
'CEK632AZB    ',;
'CEK632BRM    ',;
'CEK632BRS    ',;
'CEK632CZC    ',;
'CEK632CZE    ',;
'CEK632CZG    ',;
'CEK632PRS    ',;
'CEK632PTO    ',;
'CEK632VMC    ',;
'CEK633BRS    ',;
'CEK633PRS    ',;
'CEK634BRM    ',;
'CEK634PTL    ',;
'CEK635BRS    ',;
'CEK635CZG    ',;
'CEK635PRS    ',;
'CEK635PTF    ',;
'CEK635PTO    ',;
'CEK635VMC    ',;
'CEK635VME    ',;
'CEK643BRP    ',;
'CEK643PRN    ',;
'CEK643PTA    ',;
'CEK645BGA    ',;
'CEK645BRC    ',;
'CEK645BRP    ',;
'CEK645CZG    ',;
'CEK645PRR    ',;
'CEK645PTS    ',;
'CEK646BGA    ',;
'CEK646BRC    ',;
'CEK646BRP    ',;
'CEK646CZG    ',;
'CEK646PRR    ',;
'CEK646PTS    ',;
'CEK647BRP    ',;
'CEK647CZG    ',;
'CEK647PRN    ',;
'CEK647PTA    ',;
'CEK647VMV    ',;
'CEK648BRP    ',;
'CEK648CZG    ',;
'CEK648PRN    ',;
'CEK648PTA    ',;
'CEK648VMV    ',;
'CEK650BRP    ',;
'CEK650PRM    ',;
'CEK650PTE    ',;
'CEK731BRT    ',;
'CEK731CZB    ',;
'CEK731CZC    ',;
'CEK731CZI    ',;
'CEK731MRJ    ',;
'CEK731PRG    ',;
'CEK731PRP    ',;
'CEK731PTC    ',;
'CEK731PTF    ',;
'CEK731VMM    ',;
'CEK732BRW    ',;
'CEK732PRS    ',;
'CEK732PTP    ',;
'CEK750AZL    ',;
'CEK750BRF    ',;
'CEK750BRY    ',;
'CEK750CZC    ',;
'CEK750PRI    ',;
'CEK750PTS    ',;
'CEK750VDA    ',;
'CEK750VMF    ',;
'CEK777BRC    ',;
'CEK777PRS    ',;
'CEK777PTC    ',;
'CEK910BRA    ',;
'CEK910LJA    ',;
'CEK910PRM    ',;
'CEK910PTC    ',;
'CEK910PTF    ',;
'CEK910VDC    ',;
'CEK910VMC    ',;
'CEKC273BRS   ',;
'CEKC645BRP   ',;
'CEKC646BRP   ',;
'CEKC950PRF   ',;
'CEKE000      ',;
'CK000AN      ',;
'CK000PT      ',;
'CK041AN      ',;
'CK041PT      ',;
'CK042AN      ',;
'CK042PT      ',;
'CK043AN      ',;
'CK043PT      ',;
'CK044AN      ',;
'CK044PT      ',;
'CK045AN      ',;
'CK045PT      ',;
'CK110AN      ',;
'CK110PT      ',;
'CK110PT01LD  ',;
'CK111AN      ',;
'CK111PT      ',;
'CK174AN      ',;
'CK174PT      ',;
'CK175AN      ',;
'CK175PT      ',;
'CK176AN      ',;
'CK176PT      ',;
'CK177AN      ',;
'CK177PT      ',;
'CK178AN      ',;
'CK178PT      ',;
'CK179AN      ',;
'CK179PT      ',;
'CK180AN      ',;
'CK180PT      ',;
'CK181AN      ',;
'CK181PT      ',;
'CK210AN      ',;
'CK210PT      ',;
'CK211AN      ',;
'CK211PT      ',;
'CK244AN      ',;
'CK244PT      ',;
'CK245AN      ',;
'CK245PT      ',;
'CK247AN      ',;
'CK247PT      ',;
'CK273AN      ',;
'CK273PT      ',;
'CK274AN      ',;
'CK274PT      ',;
'CK275AN      ',;
'CK275PT      ',;
'CK276AN      ',;
'CK276PT      ',;
'CK280AN      ',;
'CK280PT      ',;
'CK281AN      ',;
'CK281PT      ',;
'CK300AN      ',;
'CK300PT      ',;
'CK302AN      ',;
'CK305AN      ',;
'CK305PT      ',;
'CK308AN      ',;
'CK308PT      ',;
'CK310AN      ',;
'CK310PT      ',;
'CK311AN      ',;
'CK311PT      ',;
'CK312AN      ',;
'CK312PT      ',;
'CK315AN      ',;
'CK315PT      ',;
'CK320AN      ',;
'CK320PT      ',;
'CK330AN      ',;
'CK330PT      ',;
'CK332AN      ',;
'CK332PT      ',;
'CK344AN      ',;
'CK344PT      ',;
'CK351AN      ',;
'CK351PT      ',;
'CK352AN      ',;
'CK352PT      ',;
'CK410AN      ',;
'CK410PT      ',;
'CK411AN      ',;
'CK411PT      ',;
'CK450AN      ',;
'CK450PT      ',;
'CK451AN      ',;
'CK451PT      ',;
'CK452AN      ',;
'CK452PT      ',;
'CK453AN      ',;
'CK453PT      ',;
'CK454AN      ',;
'CK454PT      ',;
'CK457AN      ',;
'CK457PT      ',;
'CK540AN      ',;
'CK540PT      ',;
'CK550AN      ',;
'CK550PT      ',;
'CK551AN      ',;
'CK551PT      ',;
'CK552AN      ',;
'CK552PT      ',;
'CK560AN      ',;
'CK560PT      ',;
'CK561AN      ',;
'CK561PT      ',;
'CK562AN      ',;
'CK562PT      ',;
'CK623AN      ',;
'CK623PT      ',;
'CK625AN      ',;
'CK625PT      ',;
'CK630AN      ',;
'CK630PT      ',;
'CK631AN      ',;
'CK631PT      ',;
'CK632AN      ',;
'CK632PT      ',;
'CK633AN      ',;
'CK633PT      ',;
'CK634AN      ',;
'CK634PT      ',;
'CK635AN      ',;
'CK635PT      ',;
'CK636AN      ',;
'CK636PT      ',;
'CK638AN      ',;
'CK638PT      ',;
'CK643AN      ',;
'CK643PT      ',;
'CK645AN      ',;
'CK645PT      ',;
'CK646AN      ',;
'CK646PT      ',;
'CK647AN      ',;
'CK647PT      ',;
'CK648AN      ',;
'CK648PT      ',;
'CK649AN      ',;
'CK649PT      ',;
'CK650AN      ',;
'CK650PT      ',;
'CK732AN      ',;
'CK732PT      ',;
'CK750AN      ',;
'CK750PT      ',;
'CK777AN      ',;
'CK777PT      ',;
'CK850AN      ',;
'CK850PT      ',;
'CK851AN      ',;
'CK851PT      ',;
'CK910AN      ',;
'CK910PT      ',;
'CK950AN      ',;
'CK950PT      ',;
'CKA010BLB    ',;
'CKA010BLN    ',;
'CKA010GRA    ',;
'CKA010GRG    ',;
'CKA010GRM    ',;
'CKA010HYC    ',;
'CKA010PLN    ',;
'CKA010PMR    ',;
'CKA010RGR    ',;
'CKA020AMI    ',;
'CKA020AZB    ',;
'CKA020AZN    ',;
'CKA020BRC    ',;
'CKA020CZA    ',;
'CKA020CZP    ',;
'CKA020CZQ    ',;
'CKA020CZV    ',;
'CKA020LJA    ',;
'CKA020LJS    ',;
'CKA020PMR    ',;
'CKA020PRE    ',;
'CKA020PRF    ',;
'CKA020PRR    ',;
'CKA020PRS    ',;
'CKA020PRT    ',;
'CKA020PTM    ',;
'CKA020PTN    ',;
'CKA020PTY    ',;
'CKA020VMO    ',;
'CKA020VMT    ',;
'CKA030AMS    ',;
'CKA030BRA    ',;
'CKA030LJF    ',;
'CKA030PMR    ',;
'CKA030PRI    ',;
'CKA030PTC    ',;
'CKA030VDA    ',;
'CKA030VMR    ',;
'CKA178BRA    ',;
'CKA178CZL    ',;
'CKA178PMR    ',;
'CKA178PRC    ',;
'CKA178PRR    ',;
'CKA178PRT    ',;
'CKA178PTO    ',;
'CKA178VDF    ',;
'CKA178VDP    ',;
'CKA178VMM    ',;
'CKA210AZB    ',;
'CKA210AZR    ',;
'CKA210BRA    ',;
'CKA210BRV    ',;
'CKA210CZC    ',;
'CKA210CZM    ',;
'CKA210LJS    ',;
'CKA210PMR    ',;
'CKA210PRD    ',;
'CKA210PRE    ',;
'CKA210PRR    ',;
'CKA210PTB    ',;
'CKA210PTE    ',;
'CKA210PTF    ',;
'CKA210VMA    ',;
'CKA210VMM    ',;
'CKA211BRA    ',;
'CKA211BRV    ',;
'CKA211CZC    ',;
'CKA211CZM    ',;
'CKA211LJS    ',;
'CKA211PMR    ',;
'CKA211PRD    ',;
'CKA211PRE    ',;
'CKA211PRR    ',;
'CKA211PTB    ',;
'CKA211PTE    ',;
'CKA211VMA    ',;
'CKA211VMM    ',;
'CKA623AZB    ',;
'CKA623AZM    ',;
'CKA623BGP    ',;
'CKA623BRV    ',;
'CKA623CZA    ',;
'CKA623CZG    ',;
'CKA623PMR    ',;
'CKA623PRS    ',;
'CKA623PTC    ',;
'CKA623PTO    ',;
'CKA710AMD    ',;
'CKA710AZM    ',;
'CKA710BRD    ',;
'CKA710CZL    ',;
'CKA710LJN    ',;
'CKA710PMR    ',;
'CKA710PRG    ',;
'CKA710PTM    ',;
'CKA710VDG    ',;
'CKA710VDM    ',;
'CKA710VMA    ',;
'CKA777BRM    ',;
'CKA777MRB    ',;
'CKA777PMR    ',;
'CKA777PRI    ',;
'CKA777PRR    ',;
'CKA777PTE    ',;
'CKAD068VM    ',;
'CKAD211CR    ',;
'CKAD211TR    ',;
'CKAD275BR    ',;
'CKAD275CZ    ',;
'CKAD275PT    ',;
'CKAD710VM    ',;
'CKAL041TAN   ',;
'CKAL041TPT   ',;
'CKAL042AN    ',;
'CKAL042CB    ',;
'CKAL042PT    ',;
'CKAL043AN    ',;
'CKAL043CB    ',;
'CKAL043PT    ',;
'CKAL044AN    ',;
'CKAL044CB    ',;
'CKAL044PT    ',;
'CKAL1100CB   ',;
'CKAL1220CB   ',;
'CKAL1260AN   ',;
'CKAL1260PT   ',;
'CKAL1261AN   ',;
'CKAL1261PT   ',;
'CKAL1320CB   ',;
'CKAL1350CB   ',;
'CKAL1380AN   ',;
'CKAL1380PT   ',;
'CKAL1415CB   ',;
'CKAL1430CB   ',;
'CKAL1440CB   ',;
'CKAL1480AN   ',;
'CKAL1480PT   ',;
'CKAL1490CB   ',;
'CKAL1510CB   ',;
'CKAL1520CB   ',;
'CKAL1521CB   ',;
'CKAL1530CB   ',;
'CKAL1540CB   ',;
'CKAL1541CB   ',;
'CKAL1550CB   ',;
'CKAL1555CB   ',;
'CKAL1565CB   ',;
'CKAL1570AN   ',;
'CKAL1570PT   ',;
'CKAL1595CB   ',;
'CKAL1610CB   ',;
'CKAL1615AN   ',;
'CKAL1615PT   ',;
'CKAL1655CB   ',;
'CKAL1660CB   ',;
'CKAL1680CB   ',;
'CKAL1700AN   ',;
'CKAL1700PT   ',;
'CKAL1701AN   ',;
'CKAL1701PT   ',;
'CKAL1730AN   ',;
'CKAL1730PT   ',;
'CKAL1780CB   ',;
'CKAL1781CB   ',;
'CKAL1820AN   ',;
'CKAL1820PT   ',;
'CKAL1840CB   ',;
'CKAL1841CB   ',;
'CKAL1895AN   ',;
'CKAL1895PT   ',;
'CKAL1896AN   ',;
'CKAL1896PT   ',;
'CKAL1940CB   ',;
'CKAL1960AN   ',;
'CKAL1960PT   ',;
'CKAL2100AN   ',;
'CKAL2100PT   ',;
'CKAL275OR-1  ',;
'CKAL351AN    ',;
'CKAL351PT    ',;
'CKAL352AN    ',;
'CKAL352PT    ',;
'CKAL451TAN   ',;
'CKAL452AN    ',;
'CKAL452CB    ',;
'CKAL452PT    ',;
'CKAL453AN    ',;
'CKAL453PT    ',;
'CKAL454AN    ',;
'CKAL454PT    ',;
'CKAL630TAN   ',;
'CKAL630TPT   ',;
'CKAL632OP    ',;
'CKAL632OR    ',;
'CKAL632OR-1  ',;
'CKAL632TAN   ',;
'CKAL632TPT   ',;
'CKAL647OP    ',;
'CKAL647OR    ',;
'CKAL647OR-1  ',;
'CKAL850AN    ',;
'CKAL850CB    ',;
'CKAL850PT    ',;
'CKAL851AN    ',;
'CKAL851PT    ',;
'CKBTS0000MT  ',;
'CKCM632      ',;
'CKEC041      ',;
'CKENG950     ',;
'CKF950PRM    ',;
'CKFR450CZ    ',;
'CKGF632      ',;
'CKLC000      ',;
'CKM211       ',;
'CKM632       ',;
'CKM731       ',;
'CKO275SI     ',;
'CKO632SI     ',;
'CKO647SI     ',;
'CKP273BRS    ',;
'CKP274BRS    ',;
'CKP630PRS    ',;
'CKP631PRS    ',;
'CKP632PRP    ',;
'CKP645BRP    ',;
'CKP646BRP    ',;
'CKPMS110PTF  ',;
'CKPMS110VMC  ',;
'CKPMS245PTF  ',;
'CKPMS245VMC  ',;
'CKPMS275PTF  ',;
'CKPMS275VMC  ',;
'CKPMS632APTF ',;
'CKPMS632AVMC ',;
'CKPMS632NPTF ',;
'CKPMS632NVMC ',;
'CKPMS647PTF  ',;
'CKPMS647VMC  ',;
'CKPS000      ',;
'CKPS0115     ',;
'CKPS0128     ',;
'CKPS0129     ',;
'CKPS0130     ',;
'CKPS0131     ',;
'CKPS0132     ',;
'CKPS0133     ',;
'CKPS0134     ',;
'CKPS0135     ',;
'CKPS0136     ',;
'CKPS0137     ',;
'CKPS0138     ',;
'CKPS0139     ',;
'CKPS0140     ',;
'CKPS0141     ',;
'CKPS0142     ',;
'CKPS0143     ',;
'CKPS0144     ',;
'CKQM710CZC   ',;
'CKRE000      ',;
'CKS632AZB    ',;
'CKS632BRS    ',;
'CKS632CZA    ',;
'CKS632CZC    ',;
'CKS632CZG    ',;
'CKS632PMR    ',;
'CKS632PRP    ',;
'CKS632PRS    ',;
'CKS632PTC    ',;
'CKS632PTO    ',;
'CKS632VDD    ',;
'CKS632VMC    ',;
'CKS632VME    ',;
'CKSA632BRS   ',;
'CKSA632CZG   ',;
'CKSA632PTO   ',;
'CKSH041AN    ',;
'CKSH041PT    ',;
'CKSH110AN    ',;
'CKSH110PT    ',;
'CKSH111AN    ',;
'CKSH111PT    ',;
'CKSH130AN    ',;
'CKSH130PT    ',;
'CKSH174AN    ',;
'CKSH174PT    ',;
'CKSH175AN    ',;
'CKSH175PT    ',;
'CKSH176AN    ',;
'CKSH176PT    ',;
'CKSH177AN    ',;
'CKSH177PT    ',;
'CKSH178AN    ',;
'CKSH178PT    ',;
'CKSH179AN    ',;
'CKSH179PT    ',;
'CKSH180AN    ',;
'CKSH180PT    ',;
'CKSH210AN    ',;
'CKSH210PT    ',;
'CKSH211AN    ',;
'CKSH211PT    ',;
'CKSH244AN    ',;
'CKSH244PT    ',;
'CKSH245AN    ',;
'CKSH245PT    ',;
'CKSH247AN    ',;
'CKSH247PT    ',;
'CKSH273AN    ',;
'CKSH273PT    ',;
'CKSH274AN    ',;
'CKSH274PT    ',;
'CKSH275AN    ',;
'CKSH275PT    ',;
'CKSH276AN    ',;
'CKSH276PT    ',;
'CKSH280AN    ',;
'CKSH280PT    ',;
'CKSH281AN    ',;
'CKSH281PT    ',;
'CKSH300AN    ',;
'CKSH300PT    ',;
'CKSH302AN    ',;
'CKSH302PT    ',;
'CKSH305AN    ',;
'CKSH305PT    ',;
'CKSH308AN    ',;
'CKSH308PT    ',;
'CKSH310AN    ',;
'CKSH310PT    ',;
'CKSH311AN    ',;
'CKSH311PT    ',;
'CKSH312AN    ',;
'CKSH312PT    ',;
'CKSH315AN    ',;
'CKSH315PT    ',;
'CKSH320AN    ',;
'CKSH320PT    ',;
'CKSH332AN    ',;
'CKSH332PT    ',;
'CKSH344AN    ',;
'CKSH344PT    ',;
'CKSH345AN    ',;
'CKSH345PT    ',;
'CKSH410AN    ',;
'CKSH410PT    ',;
'CKSH412AN    ',;
'CKSH412PT    ',;
'CKSH413AN    ',;
'CKSH413PT    ',;
'CKSH450AN    ',;
'CKSH450PT    ',;
'CKSH451AN    ',;
'CKSH451PT    ',;
'CKSH457AN    ',;
'CKSH457PT    ',;
'CKSH540AN    ',;
'CKSH540PT    ',;
'CKSH550AN    ',;
'CKSH550PT    ',;
'CKSH551AN    ',;
'CKSH551PT    ',;
'CKSH552AN    ',;
'CKSH552PT    ',;
'CKSH560AN    ',;
'CKSH560PT    ',;
'CKSH561AN    ',;
'CKSH561PT    ',;
'CKSH562AN    ',;
'CKSH562PT    ',;
'CKSH623AN    ',;
'CKSH623PT    ',;
'CKSH625AN    ',;
'CKSH625PT    ',;
'CKSH630AN    ',;
'CKSH630PT    ',;
'CKSH631AN    ',;
'CKSH631PT    ',;
'CKSH632AN    ',;
'CKSH632PT    ',;
'CKSH633AN    ',;
'CKSH633PT    ',;
'CKSH634AN    ',;
'CKSH634PT    ',;
'CKSH635AN    ',;
'CKSH635PT    ',;
'CKSH636AN    ',;
'CKSH636PT    ',;
'CKSH638AN    ',;
'CKSH638PT    ',;
'CKSH643AN    ',;
'CKSH643PT    ',;
'CKSH645AN    ',;
'CKSH645PT    ',;
'CKSH646AN    ',;
'CKSH646PT    ',;
'CKSH647AN    ',;
'CKSH647PT    ',;
'CKSH648AN    ',;
'CKSH648PT    ',;
'CKSH649AN    ',;
'CKSH649PT    ',;
'CKSH650AN    ',;
'CKSH650PT    ',;
'CKSH731AN    ',;
'CKSH731PT    ',;
'CKSH732AN    ',;
'CKSH732PT    ',;
'CKSH750AN    ',;
'CKSH750PT    ',;
'CKSH777AN    ',;
'CKSH777PT    ',;
'CKSH910AN    ',;
'CKSH910PT    ',;
'CKSH950AN    ',;
'CKSH950PT    ',;
'CKSI110      ',;
'CKSI211      ',;
'CKSI245      ',;
'CKSI275      ',;
'CKSI632      ',;
'CKSI647      ',;
'CKSI731      ',;
'CKSP0001     ',;
'CKSP0002     ',;
'CKSP0003     ',;
'CKSP0004     ',;
'CKSP0005     ',;
'CKSP0006     ',;
'CKSP0007     ',;
'CKSP0008     ',;
'CKSP0009     ',;
'CKSP0010     ',;
'CKSP0011     ',;
'CKSP0012     ',;
'CKSP0013     ',;
'CKSP0014     ',;
'CKSP0015     ',;
'CKSP0016     ',;
'CKSP0017     ',;
'CKSP0018     ',;
'CKSP0019     ',;
'CKSP0020     ',;
'CKSP0021     ',;
'CKSP0022     ',;
'CKSP0023     ',;
'CKSP0024     ',;
'CKSP0025     ',;
'CKSP0026     ',;
'CKSP0027     ',;
'CKSP0028     ',;
'CKSP0029     ',;
'CKSP0030     ',;
'CKSP0031     ',;
'CKSP0032     ',;
'CKSP0033     ',;
'CKSP0034     ',;
'CKSP0035     ',;
'CKSP0036     ',;
'CKSP0037     ',;
'CKSP0038     ',;
'CKSP0039     ',;
'CKSP0040     ',;
'CKSP0041     ',;
'CKSP0042     ',;
'CKSP0043     ',;
'CKSP0044     ',;
'CKSP0045     ',;
'CKSP0046     ',;
'CKSP0047     ',;
'CKSP0048     ',;
'CKSP0049     ',;
'CKSP0050     ',;
'CKSP0051     ',;
'CKSP0052     ',;
'CKSP0053     ',;
'CKSP0054     ',;
'CKSP0055     ',;
'CKSP0056     ',;
'CKSP0057     ',;
'CKSP0058     ',;
'CKSP0059     ',;
'CKSP0060     ',;
'CKSP0061     ',;
'CKSP0062     ',;
'CKSP0063     ',;
'CKSP0064     ',;
'CKSP0065     ',;
'CKSP0066     ',;
'CKSP0067     ',;
'CKSP0068     ',;
'CKSP0069     ',;
'CKSP0070     ',;
'CKSP0071     ',;
'CKSP0072     ',;
'CKSP0073     ',;
'CKSP0074     ',;
'CKSP0075     ',;
'CKSP0076     ',;
'CKSP0079     ',;
'CKSP0080     ',;
'CKSP0081     ',;
'CKSP0082     ',;
'CKSP0083     ',;
'CKSP0084     ',;
'CKSP0085     ',;
'CKSP0086     ',;
'CKSP0087     ',;
'CKSP0088     ',;
'CKSP0089     ',;
'CKSP0090     ',;
'CKSP0091     ',;
'CKSP0092     ',;
'CKSP0093     ',;
'CKSP0094     ',;
'CKSP0095     ',;
'CKSP0096     ',;
'CKSP0097     ',;
'CKSP0098     ',;
'CKSP0099     ',;
'CKSP0100     ',;
'CKSP0101     ',;
'CKSP0102     ',;
'CKSP0103     ',;
'CKSP0104     ',;
'CKSP0105     ',;
'CKSP0106     ',;
'CKSP0107     ',;
'CKSP0108     ',;
'CKSP0109     ',;
'CKSP0110     ',;
'CKSP0111     ',;
'CKSP0112     ',;
'CKSP0113     ',;
'CKSP0114     ',;
'CKSP0116     ',;
'CKSP0117     ',;
'CKSP0118     ',;
'CKSP0119     ',;
'CKSP0120     ',;
'CKSP0121     ',;
'CKSP0122     ',;
'CKSP0123     ',;
'CKSP0124     ',;
'CKSP0125     ',;
'CKSP0126     ',;
'CKSP0127     ',;
'CKSP0128     ',;
'CKSP0129     ',;
'CKSP0130     ',;
'CKSP0131     ',;
'CKSP0132     ',;
'CKSP0133     ',;
'CKSP0134     ',;
'CKSP0135     ',;
'CKSP0136     ',;
'CKSP0137     ',;
'CKSP0138     ',;
'CKSP0139     ',;
'CKSP0140     ',;
'CKSP0141     ',;
'CKSP0142     ',;
'CKSP0143     ',;
'CKSP0144     ',;
'CKSP0145     ',;
'CKSP0146     ',;
'CKSP0147     ',;
'CKSP0148     ',;
'CKSP0149     ',;
'CKSP0150     ',;
'CKSP0151     ',;
'CKSP0152     ',;
'CKSP0153     ',;
'CKSP0154     ',;
'CKSP0155     ',;
'CKSP0156     ',;
'CKSP0157     ',;
'CKSP0158     ',;
'CKSP0159     ',;
'CKSP0160     ',;
'CKSP0161     ',;
'CKSP0162     ',;
'CKSP0163     ',;
'CKSP0164     ',;
'CKSP0165     ',;
'CKSP0166     ',;
'CKSP0167     ',;
'CKSP0168     ',;
'CKSP0169     ',;
'CKSP0170     ',;
'CKSP0171     ',;
'CKSP0172     ',;
'CKSP0173     ',;
'CKSP0174     ',;
'CKSP0175     ',;
'CKSP0176     ',;
'CKSP0177     ',;
'CKSP0178     ',;
'CKSP0179     ',;
'CKSP0180     ',;
'CKSP0181     ',;
'CKSP0182     ',;
'CKSP0183     ',;
'CKSP0184     ',;
'CKSP0185     ',;
'CKSP0186     ',;
'CKSP0187     ',;
'CKSP0188     ',;
'CKSP0189     ',;
'CKSP0190     ',;
'CKSP0191     ',;
'CKSP0192     ',;
'CKSR632AZB   ',;
'CKSR632BRS   ',;
'CKSR632CZA   ',;
'CKSR632CZC   ',;
'CKSR632CZG   ',;
'CKSR632PMR   ',;
'CKSR632PRP   ',;
'CKSR632PRS   ',;
'CKSR632PTC   ',;
'CKSR632PTO   ',;
'CKSR632VDD   ',;
'CKSR632VMC   ',;
'CKSR632VME   ',;
'CKT041AN     ',;
'CKT041PT     ',;
'CKTXS110     ',;
'CKTXS111     ',;
'CKTXS177     ',;
'CKTXS275     ',;
'CKTXS276     ',;
'CKTXS281     ',;
'CKTXS630     ',;
'CKTXS631     ',;
'CKTXS632     ',;
'CKTXS633     ',;
'CKTXS645     ',;
'CKTXS646     ',;
'CKTXS647     ',;
'CKTXS648     ',;
'CLPM245VMC   ',;
'COMB0000     ',;
'COMB0001     ',;
'CPED041PTF   ',;
'CPED632BRS   ',;
'CPED646BRP   ',;
'CPEE041PTF   ',;
'CPEE110BRC   ',;
'CPET630PRP   ',;
'EXMU0006     ',;
'EXMU0007     ',;
'EXMU0008     ',;
'EXMU0011     ',;
'EXPCEK       ',;
'FF174F       ',;
'FF207F       ',;
'LRO207P      ',;
'MIN1000      ',;
'REP000       ',;
'T275067      '}

_aProdutos := {'ADE0000        ',;
'CEK041BRA      ',;
'CEK041MRH      ',;
'CEK041PRM      ',;
'CEK041PTC      ',;
'CEK041PTS      ',;
'CEK041VDB      ',;
'CEK041VMC      ',;
'CEK041VMT      ',;
'CEK110AZI      ',;
'CEK110BRC      ',;
'CEK110CZI      ',;
'CEK110CZN      ',;
'CEK110MRT      ',;
'CEK110PRC      ',;
'CEK110PRS      ',;
'CEK110PRV      ',;
'CEK110PTF      ',;
'CEK110PTM      ',;
'CEK111AZI      ',;
'CEK111BRC      ',;
'CEK111CZI      ',;
'CEK111MRT      ',;
'CEK111PRS      ',;
'CEK111PRV      ',;
'CEK111PTM      ',;
'CEK175BRE      ',;
'CEK175CZH      ',;
'CEK175PRE      ',;
'CEK175PTE      ',;
'CEK176BRA      ',;
'CEK176PRR      ',;
'CEK176PTO      ',;
'CEK177BRA      ',;
'CEK177CZL      ',;
'CEK177PRC      ',;
'CEK177PRR      ',;
'CEK177PRT      ',;
'CEK177PTF      ',;
'CEK177PTO      ',;
'CEK177VMR      ',;
'CEK178BRA      ',;
'CEK178PRR      ',;
'CEK178PTO      ',;
'CEK179BRP      ',;
'CEK179PRC      ',;
'CEK179PTO      ',;
'CEK180BRP      ',;
'CEK180PRC      ',;
'CEK180PTO      ',;
'CEK210BRA      ',;
'CEK210PRE      ',;
'CEK210PTE      ',;
'CEK211BRA      ',;
'CEK211BRV      ',;
'CEK211PRE      ',;
'CEK211PRR      ',;
'CEK211PTE      ',;
'CEK211PTF      ',;
'CEK211VMA      ',;
'CEK244BRG      ',;
'CEK244PRB      ',;
'CEK244PTP      ',;
'CEK244VDA      ',;
'CEK273AZA      ',;
'CEK273BRA      ',;
'CEK273BRS      ',;
'CEK273CZU      ',;
'CEK273PRA      ',;
'CEK273PRG      ',;
'CEK273PTG      ',;
'CEK273VMB      ',;
'CEK275AZM      ',;
'CEK275BRA      ',;
'CEK275CZM      ',;
'CEK275PMR      ',;
'CEK275PRE      ',;
'CEK275PRG      ',;
'CEK275PRV      ',;
'CEK275PTF      ',;
'CEK275PTG      ',;
'CEK275VMB      ',;
'CEK275VMT      ',;
'CEK276AZM      ',;
'CEK276BRA      ',;
'CEK276CZM      ',;
'CEK276PMR      ',;
'CEK276PRE      ',;
'CEK276PRG      ',;
'CEK276PRV      ',;
'CEK276PTG      ',;
'CEK276VMB      ',;
'CEK276VMT      ',;
'CEK280BRD      ',;
'CEK280PRC      ',;
'CEK280PTE      ',;
'CEK281BRD      ',;
'CEK281CZU      ',;
'CEK281PRC      ',;
'CEK281PRE      ',;
'CEK281PTE      ',;
'CEK300BRC      ',;
'CEK300BRW      ',;
'CEK300CZC      ',;
'CEK300CZM      ',;
'CEK300PRC      ',;
'CEK300PRM      ',;
'CEK300PTE      ',;
'CEK305BRP      ',;
'CEK305BRV      ',;
'CEK305BRW      ',;
'CEK305CZC      ',;
'CEK305PRM      ',;
'CEK305PTE      ',;
'CEK308PTO      ',;
'CEK310BRL      ',;
'CEK310PRL      ',;
'CEK310PTE      ',;
'CEK311BRC      ',;
'CEK311BRL      ',;
'CEK311PRL      ',;
'CEK311PTE      ',;
'CEK312BRL      ',;
'CEK312PRL      ',;
'CEK312PTE      ',;
'CEK320BRA      ',;
'CEK320PRG      ',;
'CEK320PTM      ',;
'CEK320VMP      ',;
'CEK344BRS      ',;
'CEK344CZS      ',;
'CEK344GRM      ',;
'CEK344PRM      ',;
'CEK344PTP      ',;
'CEK344VMF      ',;
'CEK410PRN      ',;
'CEK410PTM      ',;
'CEK450BRG      ',;
'CEK450CZA      ',;
'CEK450MRS      ',;
'CEK450PRE      ',;
'CEK450PTN      ',;
'CEK450VMV      ',;
'CEK451BRN      ',;
'CEK451CZA      ',;
'CEK451MRS      ',;
'CEK451PRE      ',;
'CEK451PTN      ',;
'CEK451VMF      ',;
'CEK451VMV      ',;
'CEK540BRW      ',;
'CEK540PRS      ',;
'CEK540PTC      ',;
'CEK550BRW      ',;
'CEK550PRS      ',;
'CEK550PTC      ',;
'CEK551BRW      ',;
'CEK551PRS      ',;
'CEK551PTC      ',;
'CEK552BRW      ',;
'CEK552PRS      ',;
'CEK552PTC      ',;
'CEK560BRW      ',;
'CEK560PRS      ',;
'CEK560PTC      ',;
'CEK561BRW      ',;
'CEK561PRS      ',;
'CEK561PTC      ',;
'CEK562AZM      ',;
'CEK562BRN      ',;
'CEK562PRB      ',;
'CEK562PRM      ',;
'CEK562PTC      ',;
'CEK562VMI      ',;
'CEK623AZM      ',;
'CEK623BRS      ',;
'CEK623BRV      ',;
'CEK623CZA      ',;
'CEK623CZM      ',;
'CEK623PRS      ',;
'CEK623PTC      ',;
'CEK623PTF      ',;
'CEK625BRM      ',;
'CEK625PRS      ',;
'CEK625PTC      ',;
'CEK625PTF      ',;
'CEK625VMC      ',;
'CEK630AZP      ',;
'CEK630BRM      ',;
'CEK630CZA      ',;
'CEK630PRP      ',;
'CEK630PTC      ',;
'CEK630PTL      ',;
'CEK630PTS      ',;
'CEK630VDG      ',;
'CEK631BRM      ',;
'CEK631PRP      ',;
'CEK631PTC      ',;
'CEK632AZB      ',;
'CEK632BRM      ',;
'CEK632BRS      ',;
'CEK632CZC      ',;
'CEK632CZE      ',;
'CEK632CZG      ',;
'CEK632PRS      ',;
'CEK632PTO      ',;
'CEK632VMC      ',;
'CEK633BRS      ',;
'CEK633PRS      ',;
'CEK634BRM      ',;
'CEK634PTL      ',;
'CEK635BRS      ',;
'CEK635CZG      ',;
'CEK635PRS      ',;
'CEK635PTF      ',;
'CEK635PTO      ',;
'CEK635VMC      ',;
'CEK635VME      ',;
'CEK643BRP      ',;
'CEK643PRN      ',;
'CEK643PTA      ',;
'CEK645BGA      ',;
'CEK645BRC      ',;
'CEK645BRP      ',;
'CEK645CZG      ',;
'CEK645PRR      ',;
'CEK645PTS      ',;
'CEK646BGA      ',;
'CEK646BRC      ',;
'CEK646BRP      ',;
'CEK646CZG      ',;
'CEK646PRR      ',;
'CEK646PTS      ',;
'CEK647BRP      ',;
'CEK647CZG      ',;
'CEK647PRN      ',;
'CEK647PTA      ',;
'CEK647VMV      ',;
'CEK648BRP      ',;
'CEK648CZG      ',;
'CEK648PRN      ',;
'CEK648PTA      ',;
'CEK648VMV      ',;
'CEK650BRP      ',;
'CEK650PRM      ',;
'CEK650PTE      ',;
'CEK731BRT      ',;
'CEK731CZB      ',;
'CEK731CZC      ',;
'CEK731CZI      ',;
'CEK731MRJ      ',;
'CEK731PRG      ',;
'CEK731PRP      ',;
'CEK731PTC      ',;
'CEK731PTF      ',;
'CEK731VMM      ',;
'CEK732BRW      ',;
'CEK732PRS      ',;
'CEK732PTP      ',;
'CEK750AZL      ',;
'CEK750BRF      ',;
'CEK750BRY      ',;
'CEK750CZC      ',;
'CEK750PRI      ',;
'CEK750PTS      ',;
'CEK750VDA      ',;
'CEK750VMF      ',;
'CEK777BRC      ',;
'CEK777PRS      ',;
'CEK777PTC      ',;
'CEK910BRA      ',;
'CEK910LJA      ',;
'CEK910PRM      ',;
'CEK910PTC      ',;
'CEK910PTF      ',;
'CEK910VDC      ',;
'CEK910VMC      ',;
'CEKC000        ',;
'CEKC273BRS     ',;
'CEKC275PRGLD   ',;
'CEKC645BRP     ',;
'CEKC646BRP     ',;
'CEKC950PRF     ',;
'CEKE000        ',;
'CEKE344E       ',;
'CEKE632E       ',;
'CEKE910E       ',;
'CEKE950E       ',;
'CEVO000        ',;
'CEVO001        ',;
'CEVO041BRALE   ',;
'CEVO041PTF01LD ',;
'CEVO041VMC01LD ',;
'CEVO110CZI01LD ',;
'CEVO110CZILE   ',;
'CEVO457PTF01LD ',;
'CEVO950PTF01LD ',;
'CEVO950PTF01LDK',;
'CK000AN        ',;
'CK000PT        ',;
'CK041AN        ',;
'CK041PT        ',;
'CK042AN        ',;
'CK042PT        ',;
'CK043AN        ',;
'CK043PT        ',;
'CK044AN        ',;
'CK044PT        ',;
'CK045AN        ',;
'CK045PT        ',;
'CK110AN        ',;
'CK110PT        ',;
'CK110PT01LD    ',;
'CK111AN        ',;
'CK111PT        ',;
'CK174AN        ',;
'CK174PT        ',;
'CK175AN        ',;
'CK175PT        ',;
'CK176AN        ',;
'CK176PT        ',;
'CK177AN        ',;
'CK177PT        ',;
'CK178AN        ',;
'CK178PT        ',;
'CK179AN        ',;
'CK179PT        ',;
'CK180AN        ',;
'CK180PT        ',;
'CK181AN        ',;
'CK181PT        ',;
'CK210AN        ',;
'CK210PT        ',;
'CK211AN        ',;
'CK211PT        ',;
'CK244AN        ',;
'CK244PT        ',;
'CK245AN        ',;
'CK245PT        ',;
'CK247AN        ',;
'CK247PT        ',;
'CK273AN        ',;
'CK273PT        ',;
'CK274AN        ',;
'CK274PT        ',;
'CK275AN        ',;
'CK275PT        ',;
'CK276AN        ',;
'CK276PT        ',;
'CK280AN        ',;
'CK280PT        ',;
'CK281AN        ',;
'CK281PT        ',;
'CK300AN        ',;
'CK300PT        ',;
'CK302AN        ',;
'CK305AN        ',;
'CK305PT        ',;
'CK308AN        ',;
'CK308PT        ',;
'CK310AN        ',;
'CK310PT        ',;
'CK311AN        ',;
'CK311PT        ',;
'CK312AN        ',;
'CK312PT        ',;
'CK315AN        ',;
'CK315PT        ',;
'CK320AN        ',;
'CK320PT        ',;
'CK330AN        ',;
'CK330PT        ',;
'CK332AN        ',;
'CK332PT        ',;
'CK344AN        ',;
'CK344PT        ',;
'CK351AN        ',;
'CK351PT        ',;
'CK352AN        ',;
'CK352PT        ',;
'CK410AN        ',;
'CK410PT        ',;
'CK411AN        ',;
'CK411PT        ',;
'CK450AN        ',;
'CK450PT        ',;
'CK451AN        ',;
'CK451PT        ',;
'CK452AN        ',;
'CK452PT        ',;
'CK453AN        ',;
'CK453PT        ',;
'CK454AN        ',;
'CK454PT        ',;
'CK457AN        ',;
'CK457PT        ',;
'CK540AN        ',;
'CK540PT        ',;
'CK550AN        ',;
'CK550PT        ',;
'CK551AN        ',;
'CK551PT        ',;
'CK552AN        ',;
'CK552PT        ',;
'CK560AN        ',;
'CK560PT        ',;
'CK561AN        ',;
'CK561PT        ',;
'CK562AN        ',;
'CK562PT        ',;
'CK623AN        ',;
'CK623PT        ',;
'CK625AN        ',;
'CK625PT        ',;
'CK630AN        ',;
'CK630PT        ',;
'CK631AN        ',;
'CK631PT        ',;
'CK632AN        ',;
'CK632PT        ',;
'CK633AN        ',;
'CK633PT        ',;
'CK634AN        ',;
'CK634PT        ',;
'CK635AN        ',;
'CK635PT        ',;
'CK636AN        ',;
'CK636PT        ',;
'CK638AN        ',;
'CK638PT        ',;
'CK643AN        ',;
'CK643PT        ',;
'CK645AN        ',;
'CK645PT        ',;
'CK646AN        ',;
'CK646PT        ',;
'CK647AN        ',;
'CK647PT        ',;
'CK648AN        ',;
'CK648PT        ',;
'CK649AN        ',;
'CK649PT        ',;
'CK650AN        ',;
'CK650PT        ',;
'CK732AN        ',;
'CK732PT        ',;
'CK750AN        ',;
'CK750PT        ',;
'CK777AN        ',;
'CK777PT        ',;
'CK850AN        ',;
'CK850PT        ',;
'CK851AN        ',;
'CK851PT        ',;
'CK910AN        ',;
'CK910PT        ',;
'CK950AN        ',;
'CK950PT        ',;
'CKA010BLB      ',;
'CKA010BLN      ',;
'CKA010GRA      ',;
'CKA010GRG      ',;
'CKA010GRM      ',;
'CKA010HYC      ',;
'CKA010PLN      ',;
'CKA010PMR      ',;
'CKA010RGR      ',;
'CKA020AMI      ',;
'CKA020AZB      ',;
'CKA020AZN      ',;
'CKA020BRC      ',;
'CKA020CZA      ',;
'CKA020CZP      ',;
'CKA020CZQ      ',;
'CKA020CZV      ',;
'CKA020LJA      ',;
'CKA020LJS      ',;
'CKA020PMR      ',;
'CKA020PRE      ',;
'CKA020PRF      ',;
'CKA020PRR      ',;
'CKA020PRS      ',;
'CKA020PRT      ',;
'CKA020PTM      ',;
'CKA020PTN      ',;
'CKA020PTY      ',;
'CKA020VMO      ',;
'CKA020VMT      ',;
'CKA030AMS      ',;
'CKA030BRA      ',;
'CKA030LJF      ',;
'CKA030PMR      ',;
'CKA030PRI      ',;
'CKA030PTC      ',;
'CKA030VDA      ',;
'CKA030VMR      ',;
'CKA178BRA      ',;
'CKA178CZL      ',;
'CKA178PMR      ',;
'CKA178PRC      ',;
'CKA178PRR      ',;
'CKA178PRT      ',;
'CKA178PTO      ',;
'CKA178VDF      ',;
'CKA178VDP      ',;
'CKA178VMM      ',;
'CKA210AZB      ',;
'CKA210AZR      ',;
'CKA210BRA      ',;
'CKA210BRV      ',;
'CKA210CZC      ',;
'CKA210CZM      ',;
'CKA210LJS      ',;
'CKA210PMR      ',;
'CKA210PRD      ',;
'CKA210PRE      ',;
'CKA210PRR      ',;
'CKA210PTB      ',;
'CKA210PTE      ',;
'CKA210PTF      ',;
'CKA210VMA      ',;
'CKA210VMM      ',;
'CKA211BRA      ',;
'CKA211BRV      ',;
'CKA211CZC      ',;
'CKA211CZM      ',;
'CKA211LJS      ',;
'CKA211PMR      ',;
'CKA211PRD      ',;
'CKA211PRE      ',;
'CKA211PRR      ',;
'CKA211PTB      ',;
'CKA211PTE      ',;
'CKA211VMA      ',;
'CKA211VMM      ',;
'CKA623AZB      ',;
'CKA623AZM      ',;
'CKA623BGP      ',;
'CKA623BRV      ',;
'CKA623CZA      ',;
'CKA623CZG      ',;
'CKA623PMR      ',;
'CKA623PRS      ',;
'CKA623PTC      ',;
'CKA623PTO      ',;
'CKA710AMD      ',;
'CKA710AZM      ',;
'CKA710BRD      ',;
'CKA710CZL      ',;
'CKA710LJN      ',;
'CKA710PMR      ',;
'CKA710PRG      ',;
'CKA710PTM      ',;
'CKA710VDG      ',;
'CKA710VDM      ',;
'CKA710VMA      ',;
'CKA777BRM      ',;
'CKA777MRB      ',;
'CKA777PMR      ',;
'CKA777PRI      ',;
'CKA777PRR      ',;
'CKA777PTE      ',;
'CKAD068VM      ',;
'CKAD211CR      ',;
'CKAD211TR      ',;
'CKAD275BR      ',;
'CKAD275CZ      ',;
'CKAD275PT      ',;
'CKAD710VM      ',;
'CKAL041TAN     ',;
'CKAL041TPT     ',;
'CKAL042AN      ',;
'CKAL042CB      ',;
'CKAL042PT      ',;
'CKAL043AN      ',;
'CKAL043CB      ',;
'CKAL043PT      ',;
'CKAL044AN      ',;
'CKAL044CB      ',;
'CKAL044PT      ',;
'CKAL1100CB     ',;
'CKAL1220CB     ',;
'CKAL1260AN     ',;
'CKAL1260PT     ',;
'CKAL1261AN     ',;
'CKAL1261PT     ',;
'CKAL1320CB     ',;
'CKAL1350CB     ',;
'CKAL1380AN     ',;
'CKAL1380PT     ',;
'CKAL1415CB     ',;
'CKAL1430CB     ',;
'CKAL1440CB     ',;
'CKAL1480AN     ',;
'CKAL1480PT     ',;
'CKAL1490CB     ',;
'CKAL1510CB     ',;
'CKAL1520CB     ',;
'CKAL1521CB     ',;
'CKAL1530CB     ',;
'CKAL1540CB     ',;
'CKAL1541CB     ',;
'CKAL1550CB     ',;
'CKAL1555CB     ',;
'CKAL1565CB     ',;
'CKAL1570AN     ',;
'CKAL1570PT     ',;
'CKAL1595CB     ',;
'CKAL1610CB     ',;
'CKAL1615AN     ',;
'CKAL1615PT     ',;
'CKAL1655CB     ',;
'CKAL1660CB     ',;
'CKAL1680CB     ',;
'CKAL1700AN     ',;
'CKAL1700PT     ',;
'CKAL1701AN     ',;
'CKAL1701PT     ',;
'CKAL1730AN     ',;
'CKAL1730PT     ',;
'CKAL1780CB     ',;
'CKAL1781CB     ',;
'CKAL1820AN     ',;
'CKAL1820PT     ',;
'CKAL1840CB     ',;
'CKAL1841CB     ',;
'CKAL1895AN     ',;
'CKAL1895PT     ',;
'CKAL1896AN     ',;
'CKAL1896PT     ',;
'CKAL1940CB     ',;
'CKAL1960AN     ',;
'CKAL1960PT     ',;
'CKAL2100AN     ',;
'CKAL2100PT     ',;
'CKAL275OR-1    ',;
'CKAL351AN      ',;
'CKAL351PT      ',;
'CKAL352AN      ',;
'CKAL352PT      ',;
'CKAL451TAN     ',;
'CKAL452AN      ',;
'CKAL452CB      ',;
'CKAL452PT      ',;
'CKAL453AN      ',;
'CKAL453PT      ',;
'CKAL454AN      ',;
'CKAL454PT      ',;
'CKAL630TAN     ',;
'CKAL630TPT     ',;
'CKAL632OP      ',;
'CKAL632OR      ',;
'CKAL632OR-1    ',;
'CKAL632TAN     ',;
'CKAL632TPT     ',;
'CKAL647OP      ',;
'CKAL647OR      ',;
'CKAL647OR-1    ',;
'CKAL850AN      ',;
'CKAL850CB      ',;
'CKAL850PT      ',;
'CKAL851AN      ',;
'CKAL851PT      ',;
'CKBTS0000MT    ',;
'CKCM632        ',;
'CKCP275BRA01LE ',;
'CKCP275PTE01LD ',;
'CKEC041        ',;
'CKENG950       ',;
'CKF041E        ',;
'CKF110A        ',;
'CKF110E        ',;
'CKF110W        ',;
'CKF211CL       ',;
'CKF245A        ',;
'CKF275A        ',;
'CKF275E        ',;
'CKF275W        ',;
'CKF457I        ',;
'CKF632A        ',;
'CKF632E        ',;
'CKF632TX       ',;
'CKF632W        ',;
'CKF647A        ',;
'CKF950PRM      ',;
'CKFR450CZ      ',;
'CKFS041        ',;
'CKFS910        ',;
'CKGF632        ',;
'CKI140I        ',;
'CKI275WTB      ',;
'CKI320NL       ',;
'CKI450NL       ',;
'CKI645NL       ',;
'CKI731NL       ',;
'CKI732NL       ',;
'CKI910NL       ',;
'CKIAL632       ',;
'CKIAP320       ',;
'CKIAP632       ',;
'CKLC000        ',;
'CKM211         ',;
'CKM632         ',;
'CKM731         ',;
'CKN280AN01LD   ',;
'CKO110         ',;
'CKO245         ',;
'CKO275         ',;
'CKO275 01 LADO ',;
'CKO275SI       ',;
'CKO632         ',;
'CKO632 01 LADO ',;
'CKO632 01LD KIT',;
'CKO632M        ',;
'CKO632SI       ',;
'CKO643         ',;
'CKO647         ',;
'CKO647 01 LADO ',;
'CKO647 01LD KIT',;
'CKO647M        ',;
'CKO647SI       ',;
'CKO731B        ',;
'CKOP275 01 LADO',;
'CKOP275W       ',;
'CKOP632 01 LADO',;
'CKOP632 01LDKIT',;
'CKOP647 01 LADO',;
'CKOP64701LDKIT ',;
'CKP000         ',;
'CKP000BRC      ',;
'CKP000BRM      ',;
'CKP000BRS      ',;
'CKP000PRI      ',;
'CKP000PRP      ',;
'CKP000PRS      ',;
'CKP000PTF      ',;
'CKP000PTL      ',;
'CKP000PTO      ',;
'CKP000PTS      ',;
'CKP001         ',;
'CKP001TD       ',;
'CKP001TE       ',;
'CKP041BRA      ',;
'CKP041MRH      ',;
'CKP041PRM      ',;
'CKP041PTC      ',;
'CKP041PTS      ',;
'CKP041VDB      ',;
'CKP041VMC      ',;
'CKP041VMT      ',;
'CKP042BRB      ',;
'CKP042CZS      ',;
'CKP042PRB      ',;
'CKP042PTV      ',;
'CKP043BRB      ',;
'CKP043CZS      ',;
'CKP043PRB      ',;
'CKP043PTV      ',;
'CKP044BRB      ',;
'CKP044CZS      ',;
'CKP044PRB      ',;
'CKP044PTV      ',;
'CKP110AZI      ',;
'CKP110BRC      ',;
'CKP110CZI      ',;
'CKP110CZN      ',;
'CKP110MRT      ',;
'CKP110PRS      ',;
'CKP110PRV      ',;
'CKP110PTM      ',;
'CKP111AZI      ',;
'CKP111BRC      ',;
'CKP111CZI      ',;
'CKP111MRT      ',;
'CKP111PRS      ',;
'CKP111PRV      ',;
'CKP111PTM      ',;
'CKP130AZN      ',;
'CKP130BRP      ',;
'CKP130BZN      ',;
'CKP130CZP      ',;
'CKP130PRS      ',;
'CKP130VMC      ',;
'CKP175BRE      ',;
'CKP175CZH      ',;
'CKP175PRE      ',;
'CKP175PTE      ',;
'CKP177BRA      ',;
'CKP177CZL      ',;
'CKP177PRC      ',;
'CKP177PRR      ',;
'CKP177PRT      ',;
'CKP177PTF      ',;
'CKP177PTO      ',;
'CKP177VMR      ',;
'CKP178BRA      ',;
'CKP178PRR      ',;
'CKP178PTO      ',;
'CKP179BRP      ',;
'CKP179PRC      ',;
'CKP179PTO      ',;
'CKP181AZP      ',;
'CKP181BRA      ',;
'CKP181BRF      ',;
'CKP181CZL      ',;
'CKP181MRC      ',;
'CKP181PRC      ',;
'CKP181PRR      ',;
'CKP181PTF      ',;
'CKP181PTO      ',;
'CKP181VMR      ',;
'CKP210BRA      ',;
'CKP210PRE      ',;
'CKP210PTE      ',;
'CKP211BRA      ',;
'CKP211BRV      ',;
'CKP211PRE      ',;
'CKP211PRR      ',;
'CKP211PTE      ',;
'CKP211PTF      ',;
'CKP211VMA      ',;
'CKP244BRG      ',;
'CKP244PRB      ',;
'CKP244PTP      ',;
'CKP244VDA      ',;
'CKP245BRA      ',;
'CKP245CZG      ',;
'CKP245LJI      ',;
'CKP245PRC      ',;
'CKP245PTP      ',;
'CKP245VMA      ',;
'CKP273AZA      ',;
'CKP273BRA      ',;
'CKP273BRS      ',;
'CKP273CZU      ',;
'CKP273PRA      ',;
'CKP273PRG      ',;
'CKP273PTG      ',;
'CKP273VMB      ',;
'CKP274AZA      ',;
'CKP274BRA      ',;
'CKP274BRS      ',;
'CKP274CZU      ',;
'CKP274PRA      ',;
'CKP274PRG      ',;
'CKP274PTE      ',;
'CKP274PTG      ',;
'CKP274VMB      ',;
'CKP275AZM      ',;
'CKP275BRA      ',;
'CKP275CZM      ',;
'CKP275PMR      ',;
'CKP275PRE      ',;
'CKP275PRG      ',;
'CKP275PRV      ',;
'CKP275PTF      ',;
'CKP275PTG      ',;
'CKP275VMB      ',;
'CKP275VMT      ',;
'CKP276AZM      ',;
'CKP276BRA      ',;
'CKP276CZM      ',;
'CKP276PMR      ',;
'CKP276PRE      ',;
'CKP276PRG      ',;
'CKP276PRV      ',;
'CKP276PTG      ',;
'CKP276VMB      ',;
'CKP276VMT      ',;
'CKP300BRC      ',;
'CKP300BRM      ',;
'CKP300BRW      ',;
'CKP300CZC      ',;
'CKP300CZM      ',;
'CKP300PRC      ',;
'CKP300PTE      ',;
'CKP305BRM      ',;
'CKP305BRP      ',;
'CKP305BRV      ',;
'CKP305BRW      ',;
'CKP305CZC      ',;
'CKP305PRM      ',;
'CKP305PTE      ',;
'CKP308AZS      ',;
'CKP308BRP      ',;
'CKP308BZT      ',;
'CKP308CZT      ',;
'CKP308PRL      ',;
'CKP308PRM      ',;
'CKP308PRS      ',;
'CKP308PTO      ',;
'CKP308VDF      ',;
'CKP308VMC      ',;
'CKP310BRC      ',;
'CKP310PRL      ',;
'CKP310PTE      ',;
'CKP320BRA      ',;
'CKP320PRG      ',;
'CKP320PTM      ',;
'CKP320VMP      ',;
'CKP410BRM      ',;
'CKP410PRN      ',;
'CKP410PTM      ',;
'CKP412DGR      ',;
'CKP412MWH      ',;
'CKP412PAS      ',;
'CKP412PTF      ',;
'CKP412PTS      ',;
'CKP413ADB      ',;
'CKP413AOB      ',;
'CKP413BRP      ',;
'CKP413CZM      ',;
'CKP413PTF      ',;
'CKP413PTM      ',;
'CKP450BRG      ',;
'CKP450CZA      ',;
'CKP450MRS      ',;
'CKP450PRE      ',;
'CKP450PTN      ',;
'CKP450VMV      ',;
'CKP452BRG      ',;
'CKP452CZA      ',;
'CKP452PRE      ',;
'CKP452PTN      ',;
'CKP540BRW      ',;
'CKP540PRS      ',;
'CKP540PTC      ',;
'CKP550BRW      ',;
'CKP550PRS      ',;
'CKP550PTC      ',;
'CKP551BRW      ',;
'CKP551PRS      ',;
'CKP551PTC      ',;
'CKP552BRW      ',;
'CKP552PRS      ',;
'CKP552PTC      ',;
'CKP560BRW      ',;
'CKP560PRS      ',;
'CKP560PTC      ',;
'CKP561BRW      ',;
'CKP561PRS      ',;
'CKP561PTC      ',;
'CKP623AZM      ',;
'CKP623BRS      ',;
'CKP623BRV      ',;
'CKP623CZA      ',;
'CKP623PRS      ',;
'CKP623PTC      ',;
'CKP623PTF      ',;
'CKP625BRM      ',;
'CKP625PRS      ',;
'CKP625PTC      ',;
'CKP625PTF      ',;
'CKP625VMC      ',;
'CKP630AZP      ',;
'CKP630BRM      ',;
'CKP630CZA      ',;
'CKP630PRP      ',;
'CKP630PRS      ',;
'CKP630PTC      ',;
'CKP630PTF      ',;
'CKP630PTS      ',;
'CKP630VDG      ',;
'CKP631BRM      ',;
'CKP631PRP      ',;
'CKP631PRS      ',;
'CKP631PTC      ',;
'CKP631PTL      ',;
'CKP632AZB      ',;
'CKP632BRM      ',;
'CKP632BRS      ',;
'CKP632CZC      ',;
'CKP632CZE      ',;
'CKP632CZG      ',;
'CKP632PRP      ',;
'CKP632PRS      ',;
'CKP632PTO      ',;
'CKP632VMC      ',;
'CKP633BRS      ',;
'CKP633PRS      ',;
'CKP633PTO      ',;
'CKP636BRS      ',;
'CKP636PRS      ',;
'CKP636PTO      ',;
'CKP638BRS      ',;
'CKP638PRS      ',;
'CKP638PTG      ',;
'CKP643BRP      ',;
'CKP643PRN      ',;
'CKP643PTA      ',;
'CKP645BGA      ',;
'CKP645BRC      ',;
'CKP645BRP      ',;
'CKP645CZG      ',;
'CKP645PRM      ',;
'CKP645PRN      ',;
'CKP645PRR      ',;
'CKP645PTS      ',;
'CKP646BGA      ',;
'CKP646BRC      ',;
'CKP646BRP      ',;
'CKP646CZG      ',;
'CKP646PRR      ',;
'CKP646PTS      ',;
'CKP647BRP      ',;
'CKP647CZG      ',;
'CKP647PRN      ',;
'CKP647PTA      ',;
'CKP647VMV      ',;
'CKP648BRP      ',;
'CKP648CZG      ',;
'CKP648PRN      ',;
'CKP648PTA      ',;
'CKP648VMV      ',;
'CKP649BRP      ',;
'CKP649PRM      ',;
'CKP649PTE      ',;
'CKP650BRP      ',;
'CKP650PRM      ',;
'CKP650PTE      ',;
'CKP731BRT      ',;
'CKP731CZB      ',;
'CKP731CZC      ',;
'CKP731CZI      ',;
'CKP731MRJ      ',;
'CKP731PRG      ',;
'CKP731PRP      ',;
'CKP731PTC      ',;
'CKP731PTF      ',;
'CKP731VMM      ',;
'CKP732BRW      ',;
'CKP732PRS      ',;
'CKP732PTP      ',;
'CKP777BRC      ',;
'CKP777PRS      ',;
'CKP777PTC      ',;
'CKP850BRA      ',;
'CKP850PRB      ',;
'CKP850PTC      ',;
'CKP910BRA      ',;
'CKP910LJA      ',;
'CKP910PRM      ',;
'CKP910PTC      ',;
'CKP910PTF      ',;
'CKP910VDC      ',;
'CKP910VMC      ',;
'CKP950BPE      ',;
'CKP950BRA      ',;
'CKP950BRP      ',;
'CKP950CZA      ',;
'CKP950PBL      ',;
'CKP950PRM      ',;
'CKP950PTC      ',;
'CKP950PTF      ',;
'CKP950VMT      ',;
'CKPC710        ',;
'CKPC710AMS     ',;
'CKPC710PTF     ',;
'CKPC710VMS     ',;
'CKPL632        ',;
'CKPMS110PTF    ',;
'CKPMS110VMC    ',;
'CKPMS245PTF    ',;
'CKPMS245VMC    ',;
'CKPMS275PTF    ',;
'CKPMS275VMC    ',;
'CKPMS632APTF   ',;
'CKPMS632AVMC   ',;
'CKPMS632NPTF   ',;
'CKPMS632NVMC   ',;
'CKPMS647PTF    ',;
'CKPMS647VMC    ',;
'CKPN003        ',;
'CKPN004        ',;
'CKPP211PTF     ',;
'CKPP630BRM     ',;
'CKPP630PRP     ',;
'CKPP630PTL     ',;
'CKPS000        ',;
'CKPS0115       ',;
'CKPS0128       ',;
'CKPS0129       ',;
'CKPS0130       ',;
'CKPS0131       ',;
'CKPS0132       ',;
'CKPS0133       ',;
'CKPS0134       ',;
'CKPS0135       ',;
'CKPS0136       ',;
'CKPS0137       ',;
'CKPS0138       ',;
'CKPS0139       ',;
'CKPS0140       ',;
'CKPS0141       ',;
'CKPS0142       ',;
'CKPS0143       ',;
'CKPS0144       ',;
'CKQM710CZC     ',;
'CKR910R        ',;
'CKRE000        ',;
'CKS632AZB      ',;
'CKS632BRS      ',;
'CKS632CZA      ',;
'CKS632CZC      ',;
'CKS632CZG      ',;
'CKS632PMR      ',;
'CKS632PRP      ',;
'CKS632PRS      ',;
'CKS632PTC      ',;
'CKS632PTO      ',;
'CKS632VDD      ',;
'CKS632VMC      ',;
'CKS632VME      ',;
'CKSA632BRS     ',;
'CKSA632CZG     ',;
'CKSA632PTO     ',;
'CKSC000PTF     ',;
'CKSC041CZC     ',;
'CKSH041AN      ',;
'CKSH041PT      ',;
'CKSH110AN      ',;
'CKSH110PT      ',;
'CKSH111AN      ',;
'CKSH111PT      ',;
'CKSH130AN      ',;
'CKSH130PT      ',;
'CKSH174AN      ',;
'CKSH174PT      ',;
'CKSH175AN      ',;
'CKSH175PT      ',;
'CKSH176AN      ',;
'CKSH176PT      ',;
'CKSH177AN      ',;
'CKSH177PT      ',;
'CKSH178AN      ',;
'CKSH178PT      ',;
'CKSH179AN      ',;
'CKSH179PT      ',;
'CKSH180AN      ',;
'CKSH180PT      ',;
'CKSH210AN      ',;
'CKSH210PT      ',;
'CKSH211AN      ',;
'CKSH211PT      ',;
'CKSH244AN      ',;
'CKSH244PT      ',;
'CKSH245AN      ',;
'CKSH245PT      ',;
'CKSH247AN      ',;
'CKSH247PT      ',;
'CKSH273AN      ',;
'CKSH273PT      ',;
'CKSH274AN      ',;
'CKSH274PT      ',;
'CKSH275AN      ',;
'CKSH275PT      ',;
'CKSH276AN      ',;
'CKSH276PT      ',;
'CKSH280AN      ',;
'CKSH280PT      ',;
'CKSH281AN      ',;
'CKSH281PT      ',;
'CKSH300AN      ',;
'CKSH300PT      ',;
'CKSH302AN      ',;
'CKSH302PT      ',;
'CKSH305AN      ',;
'CKSH305PT      ',;
'CKSH308AN      ',;
'CKSH308PT      ',;
'CKSH310AN      ',;
'CKSH310PT      ',;
'CKSH311AN      ',;
'CKSH311PT      ',;
'CKSH312AN      ',;
'CKSH312PT      ',;
'CKSH315AN      ',;
'CKSH315PT      ',;
'CKSH320AN      ',;
'CKSH320PT      ',;
'CKSH332AN      ',;
'CKSH332PT      ',;
'CKSH344AN      ',;
'CKSH344PT      ',;
'CKSH345AN      ',;
'CKSH345PT      ',;
'CKSH410AN      ',;
'CKSH410PT      ',;
'CKSH412AN      ',;
'CKSH412PT      ',;
'CKSH413AN      ',;
'CKSH413PT      ',;
'CKSH450AN      ',;
'CKSH450PT      ',;
'CKSH451AN      ',;
'CKSH451PT      ',;
'CKSH457AN      ',;
'CKSH457PT      ',;
'CKSH540AN      ',;
'CKSH540PT      ',;
'CKSH550AN      ',;
'CKSH550PT      ',;
'CKSH551AN      ',;
'CKSH551PT      ',;
'CKSH552AN      ',;
'CKSH552PT      ',;
'CKSH560AN      ',;
'CKSH560PT      ',;
'CKSH561AN      ',;
'CKSH561PT      ',;
'CKSH562AN      ',;
'CKSH562PT      ',;
'CKSH623AN      ',;
'CKSH623PT      ',;
'CKSH625AN      ',;
'CKSH625PT      ',;
'CKSH630AN      ',;
'CKSH630PT      ',;
'CKSH631AN      ',;
'CKSH631PT      ',;
'CKSH632AN      ',;
'CKSH632PT      ',;
'CKSH633AN      ',;
'CKSH633PT      ',;
'CKSH634AN      ',;
'CKSH634PT      ',;
'CKSH635AN      ',;
'CKSH635PT      ',;
'CKSH636AN      ',;
'CKSH636PT      ',;
'CKSH638AN      ',;
'CKSH638PT      ',;
'CKSH643AN      ',;
'CKSH643PT      ',;
'CKSH645AN      ',;
'CKSH645PT      ',;
'CKSH646AN      ',;
'CKSH646PT      ',;
'CKSH647AN      ',;
'CKSH647PT      ',;
'CKSH648AN      ',;
'CKSH648PT      ',;
'CKSH649AN      ',;
'CKSH649PT      ',;
'CKSH650AN      ',;
'CKSH650PT      ',;
'CKSH731AN      ',;
'CKSH731PT      ',;
'CKSH732AN      ',;
'CKSH732PT      ',;
'CKSH750AN      ',;
'CKSH750PT      ',;
'CKSH777AN      ',;
'CKSH777PT      ',;
'CKSH910AN      ',;
'CKSH910PT      ',;
'CKSH950AN      ',;
'CKSH950PT      ',;
'CKSI110        ',;
'CKSI211        ',;
'CKSI245        ',;
'CKSI275        ',;
'CKSI632        ',;
'CKSI647        ',;
'CKSI731        ',;
'CKSP0001       ',;
'CKSP0002       ',;
'CKSP0003       ',;
'CKSP0004       ',;
'CKSP0005       ',;
'CKSP0006       ',;
'CKSP0007       ',;
'CKSP0008       ',;
'CKSP0009       ',;
'CKSP0010       ',;
'CKSP0011       ',;
'CKSP0012       ',;
'CKSP0013       ',;
'CKSP0014       ',;
'CKSP0015       ',;
'CKSP0016       ',;
'CKSP0017       ',;
'CKSP0018       ',;
'CKSP0019       ',;
'CKSP0020       ',;
'CKSP0021       ',;
'CKSP0022       ',;
'CKSP0023       ',;
'CKSP0024       ',;
'CKSP0025       ',;
'CKSP0026       ',;
'CKSP0027       ',;
'CKSP0028       ',;
'CKSP0029       ',;
'CKSP0030       ',;
'CKSP0031       ',;
'CKSP0032       ',;
'CKSP0033       ',;
'CKSP0034       ',;
'CKSP0035       ',;
'CKSP0036       ',;
'CKSP0037       ',;
'CKSP0038       ',;
'CKSP0039       ',;
'CKSP0040       ',;
'CKSP0041       ',;
'CKSP0042       ',;
'CKSP0043       ',;
'CKSP0044       ',;
'CKSP0045       ',;
'CKSP0046       ',;
'CKSP0047       ',;
'CKSP0048       ',;
'CKSP0049       ',;
'CKSP0050       ',;
'CKSP0051       ',;
'CKSP0052       ',;
'CKSP0053       ',;
'CKSP0054       ',;
'CKSP0055       ',;
'CKSP0056       ',;
'CKSP0057       ',;
'CKSP0058       ',;
'CKSP0059       ',;
'CKSP0060       ',;
'CKSP0061       ',;
'CKSP0062       ',;
'CKSP0063       ',;
'CKSP0064       ',;
'CKSP0065       ',;
'CKSP0066       ',;
'CKSP0067       ',;
'CKSP0068       ',;
'CKSP0069       ',;
'CKSP0070       ',;
'CKSP0071       ',;
'CKSP0072       ',;
'CKSP0073       ',;
'CKSP0074       ',;
'CKSP0075       ',;
'CKSP0076       ',;
'CKSP0079       ',;
'CKSP0080       ',;
'CKSP0081       ',;
'CKSP0082       ',;
'CKSP0083       ',;
'CKSP0084       ',;
'CKSP0085       ',;
'CKSP0086       ',;
'CKSP0087       ',;
'CKSP0088       ',;
'CKSP0089       ',;
'CKSP0090       ',;
'CKSP0091       ',;
'CKSP0092       ',;
'CKSP0093       ',;
'CKSP0094       ',;
'CKSP0095       ',;
'CKSP0096       ',;
'CKSP0097       ',;
'CKSP0098       ',;
'CKSP0099       ',;
'CKSP0100       ',;
'CKSP0101       ',;
'CKSP0102       ',;
'CKSP0103       ',;
'CKSP0104       ',;
'CKSP0105       ',;
'CKSP0106       ',;
'CKSP0107       ',;
'CKSP0108       ',;
'CKSP0109       ',;
'CKSP0110       ',;
'CKSP0111       ',;
'CKSP0112       ',;
'CKSP0113       ',;
'CKSP0114       ',;
'CKSP0116       ',;
'CKSP0117       ',;
'CKSP0118       ',;
'CKSP0119       ',;
'CKSP0120       ',;
'CKSP0121       ',;
'CKSP0122       ',;
'CKSP0123       ',;
'CKSP0124       ',;
'CKSP0125       ',;
'CKSP0126       ',;
'CKSP0127       ',;
'CKSP0128       ',;
'CKSP0129       ',;
'CKSP0130       ',;
'CKSP0131       ',;
'CKSP0132       ',;
'CKSP0133       ',;
'CKSP0134       ',;
'CKSP0135       ',;
'CKSP0136       ',;
'CKSP0137       ',;
'CKSP0138       ',;
'CKSP0139       ',;
'CKSP0140       ',;
'CKSP0141       ',;
'CKSP0142       ',;
'CKSP0143       ',;
'CKSP0144       ',;
'CKSP0145       ',;
'CKSP0146       ',;
'CKSP0147       ',;
'CKSP0148       ',;
'CKSP0149       ',;
'CKSP0150       ',;
'CKSP0151       ',;
'CKSP0152       ',;
'CKSP0153       ',;
'CKSP0154       ',;
'CKSP0155       ',;
'CKSP0156       ',;
'CKSP0157       ',;
'CKSP0158       ',;
'CKSP0159       ',;
'CKSP0160       ',;
'CKSP0161       ',;
'CKSP0162       ',;
'CKSP0163       ',;
'CKSP0164       ',;
'CKSP0165       ',;
'CKSP0166       ',;
'CKSP0167       ',;
'CKSP0168       ',;
'CKSP0169       ',;
'CKSP0170       ',;
'CKSP0171       ',;
'CKSP0172       ',;
'CKSP0173       ',;
'CKSP0174       ',;
'CKSP0175       ',;
'CKSP0176       ',;
'CKSP0177       ',;
'CKSP0178       ',;
'CKSP0179       ',;
'CKSP0180       ',;
'CKSP0181       ',;
'CKSP0182       ',;
'CKSP0183       ',;
'CKSP0184       ',;
'CKSP0185       ',;
'CKSP0186       ',;
'CKSP0187       ',;
'CKSP0188       ',;
'CKSP0189       ',;
'CKSP0190       ',;
'CKSP0191       ',;
'CKSP0192       ',;
'CKST651MT      ',;
'CKSTS647MT     ',;
'CKT041AN       ',;
'CKT041PT       ',;
'CKT631AN       ',;
'CKT631PT       ',;
'CKTX000        ',;
'CKTX190        ',;
'CKTX260        ',;
'CKTX273        ',;
'CKTX274        ',;
'CKTX280        ',;
'CKTX345        ',;
'CKTX630        ',;
'CKTX631        ',;
'CKTX651        ',;
'CKTX660        ',;
'CKTX670        ',;
'CKTXS110       ',;
'CKTXS111       ',;
'CKTXS177       ',;
'CKTXS275       ',;
'CKTXS276       ',;
'CKTXS281       ',;
'CKTXS630       ',;
'CKTXS631       ',;
'CKTXS632       ',;
'CKTXS633       ',;
'CKTXS645       ',;
'CKTXS646       ',;
'CKTXS647       ',;
'CKTXS648       ',;
'CKU275PRG      ',;
'CKW275PRG      ',;
'CLPM245VMC     ',;
'CMD041PRM      ',;
'CMD041PTF      ',;
'CMD041PTS      ',;
'CMD041VMT      ',;
'CMD110BRC      ',;
'CMD110CZI      ',;
'CMD110PRC      ',;
'CMD110PRS      ',;
'CMD110PTM      ',;
'CMD179BRW      ',;
'CMD181BRF      ',;
'CMD181PRC      ',;
'CMD275BRA      ',;
'CMD275CZM      ',;
'CMD275PRG      ',;
'CMD275VMT      ',;
'CMD308PRS      ',;
'CMD562PTF      ',;
'CMD630BRM      ',;
'CMD630PRP      ',;
'CMD630PTL      ',;
'CMD632BRS      ',;
'CMD632PRS      ',;
'CMD632VMC      ',;
'CMD633PTF      ',;
'CMD645BRP      ',;
'CMD645PRM      ',;
'CMD910PTF      ',;
'CMD950PTF      ',;
'CMT041PRM      ',;
'CMT041PTF      ',;
'CMT041VMT      ',;
'CMT110BRC      ',;
'CMT110CZI      ',;
'CMT110PRC      ',;
'CMT110PRS      ',;
'CMT110PTM      ',;
'CMT111PRC      ',;
'CMT179BRW      ',;
'CMT181BRF      ',;
'CMT181PRC      ',;
'CMT245PRC      ',;
'CMT245PTP      ',;
'CMT275BRA      ',;
'CMT275CZM      ',;
'CMT275PRG      ',;
'CMT275PTG      ',;
'CMT308PRS      ',;
'CMT308PTF      ',;
'CMT310PTF      ',;
'CMT412PTF      ',;
'CMT551PTF      ',;
'CMT552PTF      ',;
'CMT562CZA      ',;
'CMT562PTF      ',;
'CMT630BRM      ',;
'CMT630PRP      ',;
'CMT630PTL      ',;
'CMT632BRS      ',;
'CMT632PRS      ',;
'CMT632PTF      ',;
'CMT632VMC      ',;
'CMT645BRP      ',;
'CMT645PRM      ',;
'CMT652PTF      ',;
'CMT910PTF      ',;
'CMT950PTF      ',;
'COMB0000       ',;
'COMB0001       ',;
'CPAD000        ',;
'CPAE000        ',;
'CPD041BRA      ',;
'CPD041PRM      ',;
'CPD041PTF      ',;
'CPD041VMT      ',;
'CPD110BRC      ',;
'CPD110CZI      ',;
'CPD110PRS      ',;
'CPD110PTM      ',;
'CPD179BRW      ',;
'CPD181BRF      ',;
'CPD181PRC      ',;
'CPD275BRA      ',;
'CPD275CZM      ',;
'CPD275PRG      ',;
'CPD275VMB      ',;
'CPD275VMT      ',;
'CPD450BRG      ',;
'CPD562PTF      ',;
'CPD630BRM      ',;
'CPD630PRP      ',;
'CPD630PTL      ',;
'CPD632BRS      ',;
'CPD632PRS      ',;
'CPD632VDD      ',;
'CPD632VMC      ',;
'CPD645BRP      ',;
'CPD645PRM      ',;
'CPD910PTF      ',;
'CPD950PTF      ',;
'CPDD110BRC     ',;
'CPDD110PRS     ',;
'CPDD211PRR     ',;
'CPDD275BRA     ',;
'CPDD275CZM     ',;
'CPDD275PTF     ',;
'CPDD630BRM     ',;
'CPDD630PRP     ',;
'CPDD630PTC     ',;
'CPDD630PTL     ',;
'CPDD632BRS     ',;
'CPDD645PRR     ',;
'CPDD645PTS     ',;
'CPDD647PRN     ',;
'CPDD910VMC     ',;
'CPDE110BRC     ',;
'CPDE110CZI     ',;
'CPDE110PRS     ',;
'CPDE110PTM     ',;
'CPDE275BRA     ',;
'CPDE275VMT     ',;
'CPDE630BRM     ',;
'CPDE630PRP     ',;
'CPDE630PTC     ',;
'CPDE630PTL     ',;
'CPDE632BRS     ',;
'CPDE645PTS     ',;
'CPDE647PTA     ',;
'CPDT110BRA     ',;
'CPDT275BRA     ',;
'CPDT630PRP     ',;
'CPED041PTF     ',;
'CPED632BRS     ',;
'CPED646BRP     ',;
'CPEE041PTF     ',;
'CPEE110BRC     ',;
'CPET630PRP     ',;
'CPT041BRA      ',;
'CPT041CZA      ',;
'CPT041PRM      ',;
'CPT041PTF      ',;
'CPT041VMT      ',;
'CPT042PTF      ',;
'CPT110BRC      ',;
'CPT110CZI      ',;
'CPT110PRS      ',;
'CPT110PTM      ',;
'CPT111PRC      ',;
'CPT179BRW      ',;
'CPT179PTM      ',;
'CPT181BRF      ',;
'CPT181PRC      ',;
'CPT211PTF      ',;
'CPT245PRC      ',;
'CPT245PTP      ',;
'CPT275BRA      ',;
'CPT275CZM      ',;
'CPT275PRG      ',;
'CPT275VMB      ',;
'CPT308PRS      ',;
'CPT308PTF      ',;
'CPT330PTF      ',;
'CPT412PTF      ',;
'CPT413PRM      ',;
'CPT450BRG      ',;
'CPT552PTF      ',;
'CPT562CZA      ',;
'CPT562PTF      ',;
'CPT630BRM      ',;
'CPT630PRP      ',;
'CPT630PTL      ',;
'CPT632         ',;
'CPT632BRS      ',;
'CPT632PRS      ',;
'CPT632PTF      ',;
'CPT632VMC      ',;
'CPT636PTF      ',;
'CPT645BRP      ',;
'CPT645PRM      ',;
'CPT652PTF      ',;
'CPT910BRA      ',;
'CPT910PTF      ',;
'CPT950PTF      ',;
'CPTD000PRS     ',;
'CPTD000PTF     ',;
'CPTD110BRC     ',;
'CPTD110CZN     ',;
'CPTD110PRS     ',;
'CPTD110PTM     ',;
'CPTD177BRA     ',;
'CPTD181BRF     ',;
'CPTD244PRB     ',;
'CPTD275CZM     ',;
'CPTD450BRG     ',;
'CPTD630BRM     ',;
'CPTD630PRP     ',;
'CPTD630PTL     ',;
'CPTD632BRS     ',;
'CPTD632PTL     ',;
'CPTD647BRP     ',;
'CPTD910VMC     ',;
'CPTE000PTF     ',;
'CPTE041PTF     ',;
'CPTE041PTS     ',;
'CPTE110BRC     ',;
'CPTE110CZN     ',;
'CPTE110PRS     ',;
'CPTE110PTM     ',;
'CPTE177BRA     ',;
'CPTE179PRC     ',;
'CPTE450BRG     ',;
'CPTE540CZT     ',;
'CPTE623PRS     ',;
'CPTE630BRM     ',;
'CPTE630PRP     ',;
'CPTE630PTC     ',;
'CPTE630PTL     ',;
'CPTE632BRS     ',;
'CPTE632PRS     ',;
'CPTE632PTL     ',;
'CPTE632PTO     ',;
'CPTE643BRP     ',;
'CPTE645BRP     ',;
'CPTE645PRR     ',;
'CPTE647BRP     ',;
'CPTE647PRN     ',;
'CPTE732BRP     ',;
'EXMU0006       ',;
'EXMU0007       ',;
'EXMU0008       ',;
'EXMU0011       ',;
'FF174F         ',;
'FF207F         ',;
'LRO207P        ',;
'MIN1000        ',;
'REP000         ',;
'T275067        '}


_Nok := 0
for _nI :=1 to len( _aProdutos)
	IF(SB1->(DBSEEK(XFILIAL('SB1')+PADR(_aProdutos[_nI],tamsx3('B1_COD')[1]))))

	
			RECLOCK('SB1',.F.)
				SB1->B1_WSDTALT :=DTOS(DATE())+STRTRAN(TIME(),':','')
				SB1->B1_GRUPO :='0062'
			SB1->(MSUNLOCK())

		_nOk++
	ENDIF
next

if(_nOk =len(_aProdutos) )
	msgalert('todos os produtos encontrados')
else
	msgalert('foram encontrados '+cvaltochar(_nOk)+' de '+cvaltochar(len(_aProdutos))+' ')
endif


return


user function CEKA002L()

Local _aTabela := {}
Local nHandle, _nHdl
Local _nL :=0, _nLastRec, _nReg := 0, _nProds := 0
Local _aFHeader, _aFLinha,_cCab
Local _cCodPro, _nValor


Local aLinha := {}
Local nY := 0
Local lOk := .T.
PRIVATE aCabec := {}
PRIVATE aItens := {}
PRIVATE lMsErroAuto := .F.

If(Select("SX2")=0)
	RpcSetType(3)          
	RpcSetEnv("01" ,"0101", "","","","",{"SB1","SBM","DA0","DA1"})   	    	  
	_lPrepEnv := .T.
EndIf
//log

_nHdl := FT_FUse('c:\temp\cek\tabela.csv')
if(_nHdl <= 0)
	msginfo('Arquivo c:\temp\cek\tabela.csv nao encontrado.')
	return 
endif

_nLastRec := FT_FLastRec()

SA1->(DBSETORDER(1))
_nL := 0
_nReg := 0
if(_nHdl > 0)
	FT_FGOTOP()
	_cCab := FT_FREADLN()
	_aFHeader := StrTokArr2(_cCab,';')
	FT_FSKIP()		
	_cLinha := FT_FREADLN()
	_aFLinha := StrTokArr2(_cLinha,';')
	_cCodTab  	:= _aFLinha[1]
	IF(!DA0->(DBSEEK(XFILIAL('DA0')+_cCodTab)))
		MSGINFO('TABELA '+_cCodTab+' NAO ENCONTRADA!')
		RETURN
	ENDIF
	
	nHandle := FCREATE("C:\ETIQUETA\LISTA_PRECO_"+_cCodTab+"_"+DTOS(DATE())+'_'+STRTRAN(STRTRAN(TIME(),':','')," ","")+".CSV")
	FWrite(nHandle, 'LISTA: '+ _cCodTab+ CRLF)
	FWrite(nHandle, "TABELA;PRODUTO;PRECO"+CRLF)
	
	/*/
		_oModel := FWLoadModel("OMSA010")
		_cModel := "DA0MASTER"
		
		DA0->(DBSetOrder(1))
		
		_oModel:SetOperation(MODEL_OPERATION_UPDATE)
		_oModel:Activate()	

		
		_nI := 1

		oModel:SetValue(_cModel,_aValidCo[_nI][5],_cForFil)
		oModel:SetValue(_cModel,"DA0_CODTAB" 	,DA0->DA0_CODTAB,Nil})
		oModel:SetValue(_cModel,"DA0_DESCRI" 	,DA0->DA0_DESCRI,Nil})
		oModel:SetValue(_cModel,"DA0_DATDE"	,DA0->DA0_DATDE,Nil})
		oModel:SetValue(_cModel,"DA0_DATATE" 	,DA0->DA0_DATATE,Nil})
		oModel:SetValue(_cModel,"DA0_HORADE" 	,DA0->DA0_HORADE,Nil})
		oModel:SetValue(_cModel,"DA0_HORATE" 	,DA0->DA0_HORATE,Nil})
		oModel:SetValue(_cModel,"DA0_TPHORA" 	,DA0->DA0_TPHORA,Nil})
		oModel:SetValue(_cModel,"DA0_ATIVO"	,DA0->DA0_ATIVO,Nil})

	
		If _oModel:VldData()		
			_oModel:CommitData()	
			_cContent := '"Cadastro de Fornecedor Realizado"'
			
			_lRet := .T.
		Else	
			_lRet := .F.
			_cContent := '{Erro: '
			_cContent += _oModel:GetErrorMessage()[6]
			_cContent += '"}'
		EndIf	
			
		_oModel:DeActivate()
		_oModel:Destroy()
		_oModel:= nil
		
		//::SetResponse('["mensagem":')	
		::SetResponse(_cContent)
	Else
		If(Len(_aRetError)>0)
			Return {.f.,500,U_WS002RET(_aRetError)}
		EndIf
		
	EndIf	
	
	/*/
	
	
	
	
	
	aCabec := {}
	aadd(aCabec,{"DA0_FILIAL" 	,DA0->DA0_FILIAL,Nil})
	aadd(aCabec,{"DA0_CODTAB" 	,DA0->DA0_CODTAB,Nil})
	aadd(aCabec,{"DA0_DESCRI" 	,DA0->DA0_DESCRI,Nil})
	aadd(aCabec,{"DA0_DATDE"	,DA0->DA0_DATDE,Nil})
	aadd(aCabec,{"DA0_DATATE" 	,DA0->DA0_DATATE,Nil})
	aadd(aCabec,{"DA0_HORADE" 	,DA0->DA0_HORADE,Nil})
	aadd(aCabec,{"DA0_HORATE" 	,DA0->DA0_HORATE,Nil})
	aadd(aCabec,{"DA0_TPHORA" 	,DA0->DA0_TPHORA,Nil})
	aadd(aCabec,{"DA0_ATIVO"	,DA0->DA0_ATIVO,Nil})
	_nProds := 0
	aItens := {}
	SB1->(DBSETORDER(1))
	While !FT_FEOF()
		_cLinha := FT_FREADLN()
		_aFLinha := StrTokArr2(_cLinha,';')
		if(!Empty(_cLinha))
			_nL++
			_cCodTab  	:= _aFLinha[1]
			_cCodPro 	:= ALLTRIM(_aFLinha[2])
			_nValor 	:= VAL(_aFLinha[3])
			_cChave		:=  xFilial("SB1")+_cCodPro
			IF(SB1->(DBSEEK(xFilial("SB1")+_cCodPro)))
				_nReg++						
				WHILE (!SB1->(EOF()) .AND. _cCodPro $ SB1->B1_COD .AND. !eMPTY(_cCodPro))
		/*()*/
					FWrite(nHandle, DA0->DA0_CODTAB+";"+SB1->B1_COD+';'+CVALTOCHAR(_nValor)+CRLF)
					
					If(SB1->B1_MSBLQL <> "1").AND. _nValor > 0 
						_nProds ++
						CONOUT(CVALTOCHAR(_nL)+';'+STRZERO(_nProds,TAMSX3('DA1_ITEM')[1])+';'+_cCodPro+';'+SB1->B1_COD)
						aLinha := {}
						aadd(aLinha,{"DA1_FILIAL",DA0->DA0_FILIAL,NIL})
						aadd(aLinha,{"DA1_CODTAB",DA0->DA0_CODTAB})
						aadd(aLinha,{"DA1_ITEM",STRZERO(_nProds,TAMSX3('DA1_ITEM')[1])})
						aadd(aLinha,{"DA1_CODPRO",SB1->B1_COD})
						//aadd(aLinha,{"DA1_GRUPO",SB1->B1_GRUPO})
						aadd(aLinha,{"DA1_PRCVEN",_nValor,Nil})
						aadd(aLinha,{"DA1_ATIVO","1",Nil})
						aadd(aLinha,{"DA1_TPOPER","4",Nil})
						aadd(aLinha,{"DA1_QTDLOT",999999.99,Nil})
						aadd(aLinha,{"DA1_MOEDA",1,Nil})
						if(DA1->(FIELDPOS("DA1_WSDTAL"))>0)
							aadd(aLinha,{"DA1_WSDTAL",DTOS(DATE())+STRTRAN(TIME(),':',''),Nil})
						ENDIF
						aadd(aLinha,{"AUTDELETA","N",Nil})
						
						aadd(aItens,aLinha)
					Else
						IF(_nValor = 0)
							CONOUT(CVALTOCHAR(_nL)+';preço 0 - '+SB1->B1_COD+';')
							FWrite(nHandle, DA0->DA0_CODTAB+";"+SB1->B1_COD+';'+CVALTOCHAR(_nValor)+CRLF)
						ELSE
							CONOUT(CVALTOCHAR(_nL)+';produto bloqueado - '+SB1->B1_COD+';')
							FWrite(nHandle, DA0->DA0_CODTAB+";"+SB1->B1_COD+';'+CVALTOCHAR(_nValor)+';PRODUTO BLOQUEADO'+CRLF)
						ENDIF
					ENDIF	
					SB1->(DBSKIP())
				ENDDO

							/**/
			Else
				CONOUT(CVALTOCHAR(_nL)+';produto não encontrado - '+_cCodPro+';')
				FWrite(nHandle, DA0->DA0_CODTAB+";"+_cCodPro+';'+CVALTOCHAR(_nValor)+';PRODUTO NAO ENCONTRADO'+CRLF)
			ENDIF
		endif
		FT_FSKIP()
	EndDo
	
	IF(LEN(aCabec)>0 .AND. LEN(aItens)>0)
	
		//CONOUT(VARINFO('_aP',aItens))
		lMsErroAuto := .F.		
		MSExecAuto({|x,y,z| Omsa010(x,y,z)},aCabec,aItens,4)
		IF(lMsErroAuto)
			
			MOSTRAERRO()
		ELSE
			MSGINFO('TABELA ATUALIZADA')
		ENDIF
	ENDIF
	FClose(nHandle)
	FT_FUSE()
endif

if(_nReg =_nL)
	msgalert('todos os produtos encontrados')
else
	msgalert('foram encontrados '+cvaltochar(_nReg)+' - ('+cvaltochar(_nProds)+') de '+cvaltochar(_nL)+' ')
endif

return

user function CEKA002C()

Local _aClientes := {}
Local _nHdl, _cCab, _nL :=0, _nLastRec, _nReg := 0
Local _aFHeader
Local _cCofCli, _cCodLoja
If(Select("SX2")=0)
	RpcSetType(3)          
	RpcSetEnv("01" ,"0101", "","","","",{"SB1","SBM"})   	    	  
	_lPrepEnv := .T.
EndIf

_nHdl := FT_FUse('c:\temp\cek\clientes.csv')
if(_nHdl <= 0)
	msginfo('Arquivo c:\temp\cek\clientes.csv nao encontrado.')
	return 
endif

_nLastRec := FT_FLastRec()

SA1->(DBSETORDER(1))
_nL := 0
_nReg := 0
if(_nHdl > 0)
	FT_FGOTOP()
	_cCab := FT_FREADLN()
	_aFHeader := StrTokArr2(_cCab,';')
	While !FT_FEOF()
		_cLinha := FT_FREADLN()
		_aFLinha := StrTokArr2(_cLinha,';')
		if(!Empty(_cLinha))
			_nL++
			_cCodCli  := _aFLinha[1]
			_cCodLoja := _aFLinha[2]
			_nPComVen := _aFLinha[6]
			IF(SA1->(DBSEEK(xFilial("SA1")+padr(_cCodCli,tamsx3('A1_COD')[1])+PADR(_cCodLoja,tamsx3('A1_LOJA')[1]))))
				/**/
				_nReg++
				RECLOCK('SA1',.F.)
					SA1->A1_WSDTALT :=DTOS(DATE())+STRTRAN(TIME(),':','')
					SA1->A1_PCOMVEN := _nPComVen
				SA1->(MSUNLOCK())
							/**/
			ENDIF
		endif
		FT_FSKIP()
	EndDo
	FT_FUSE()
endif

if(_nReg =_nL)
	msgalert('todos os clientes encontrados')
else
	msgalert('foram encontrados '+cvaltochar(_nReg)+' de '+cvaltochar(_nL)+' ')
endif

return

user function CEKA002V()

Local _aClientes := {}
Local _nHdl, _cCab, _nL :=0, _nLastRec, _nReg := 0
Local _aFHeader
Local _cCofCli, _cCodLoja
If(Select("SX2")=0)
	RpcSetType(3)          
	RpcSetEnv("01" ,"0101", "","","","",{"SA1","SBM"})   	    	  
	_lPrepEnv := .T.
EndIf

_nHdl := FT_FUse('c:\temp\cek\clientes_4.csv')
if(_nHdl <= 0)
	msginfo('Arquivo c:\temp\cek\clientes_4.csv nao encontrado.')
	return 
endif

_nLastRec := FT_FLastRec()

SA3->(DBSETORDER(1))
SA1->(DBSETORDER(1))
_nL := 0
_nReg := 0
if(_nHdl > 0)
	FT_FGOTOP()
	_cCab := FT_FREADLN()
	_aFHeader := StrTokArr2(_cCab,';')
	FT_FSKIP()
	While !FT_FEOF()
		_cLinha := FT_FREADLN()
		_aFLinha := StrTokArr2(_cLinha,';')
		if(!Empty(_cLinha))
			_nL++
			_cCodCli  := _aFLinha[1]
			_cCodLoja := _aFLinha[2]
			_cVen 	  := _aFLinha[5]
			IF(SA1->(DBSEEK(xFilial("SA1")+padr(_cCodCli,tamsx3('A1_COD')[1])+PADR(_cCodLoja,tamsx3('A1_LOJA')[1]))))
				/**/
				IF(!EMPTY(_cVen))
					IF(SA3->(DBSEEK(XFILIAL("SA3")+_cVen)))
	
						IF(ALLTRIM(SA1->A1_VEND) <> ALLTRIM(_cVen))			
							_nReg++								
							RECLOCK('SA1',.F.)
								SA1->A1_VEND := _cVen
								SA1->A1_WSDTALT :=DTOS(DATE())+STRTRAN(TIME(),':','')
							SA1->(MSUNLOCK())
						ENDIF
					ENDIF
				ENDIF
							/**/
			ENDIF
		ENDIF
		FT_FSKIP()
	EndDo
	FT_FUSE()
ENDIF

if(_nReg =_nL)
	msgalert('todos os clientes encontrados')
else
	msgalert('foram encontrados '+cvaltochar(_nReg)+' de '+cvaltochar(_nL)+' ')
endif

return


user function CEKA2CTB()

Local _aClientes := {}
Local _nHdl, _cCab, _nL :=0, _nLastRec, _nReg := 0
Local _aFHeader
Local _cCofCli, _cCodLoja

Private _aFLinha
If(Select("SX2")=0)
	RpcSetType(3)          
	RpcSetEnv("01" ,"0101", "","","","",{"SB1","SBM"})   	    	  
	_lPrepEnv := .T.
EndIf

_nHdl := FT_FUse('c:\temp\cek\clientes_tab.csv')
if(_nHdl <= 0)
	msginfo('Arquivo c:\temp\cek\clientes_tab.csv nao encontrado.')
	return 
endif

_nLastRec := FT_FLastRec()

SA1->(DBSETORDER(1))
_nL := 0
_nReg := 0
if(_nHdl > 0)
	FT_FGOTOP()
	_cCab := FT_FREADLN()
	_aFHeader := StrTokArr2(_cCab,';')
	FT_FSKIP()
	While !FT_FEOF()
		_cLinha := FT_FREADLN()
		_aFLinha := StrTokArr2(_cLinha,';')
		conout(_cLinha + cvaltochar(len(_aFLinha)))
		if(!Empty(_cLinha))
			_nL++
			conout('linha:'+cvaltochar(_nL))
			_cCodCli  	:= _aFLinha[1]
			_cCodLoja 	:= _aFLinha[2]
			if(len(_aFLinha)>=9)
				_CTAB 		:= _aFLinha[9]
				_CTAB		:= PADR(_CTAB,TAMSX3('A1_TABELA')[1]) 
				IF(SA1->(DBSEEK(xFilial("SA1")+padr(_cCodCli,tamsx3('A1_COD')[1])+PADR(_cCodLoja,tamsx3('A1_LOJA')[1]))))
					/**/
					_nReg++
					IF(DA0->(DBSEEK(XFILIAL("DA0")+_CTAB)))
						RECLOCK('SA1',.F.)
							SA1->A1_WSDTALT := DTOS(DATE())+STRTRAN(TIME(),':','')
							SA1->A1_TABELA 	:= _CTAB
						SA1->(MSUNLOCK())
					ENDIF
								/**/
				ENDIF

			endif
		endif
		FT_FSKIP()
	EndDo
	FT_FUSE()
endif

if(_nReg =_nL)
	msgalert('todos os clientes encontrados')
else
	msgalert('foram encontrados '+cvaltochar(_nReg)+' de '+cvaltochar(_nL)+' ')
endif

return
