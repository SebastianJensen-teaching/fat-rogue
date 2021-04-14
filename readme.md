Det finns i princip två vanliga sätta att placera ut rum:

 - Placera via brute force och sen ta bort eller flytta isär kolliderande rum
 - Dela in kartan med BSP och placera rum i varje sektor

Min lösning är mer minimalistisk och snittar upp kartan i ett rutnät jämnstora sektorer. Om sannolikheten att ett rum placeras är hög så ger detta en jämn distrobution av rum som känns mer arkitekturellt realistisk än åtminstone brute force approachet. Nackdelen är att kartorna kan kännas för rigida eller "gridade", även jämfört med BSP. Detta ger dock potentiellt god kompabilitiet med designer som liknar Spelunky eller Binding of Isaac som ju bygger på skärm-scrolling istället för smooth scrolling.



