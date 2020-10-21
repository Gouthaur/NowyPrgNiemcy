%%%
  VERSION:1
  LANGUAGE:ENGLISH
%%%
MODULE Spray_PR
  !********************************************
  ! Subject : Release agent spraying / for OS 3.0 
  !  / normal communication (assignment via coding)
  !  prepared for DEScom (incl. factory ware communication)
  !  DEScom-instructions declared as comments
  ! Author :
  ! Joachim L�hr / Tel.  : +49 4202 990391
  ! Andreas Lissek / Tel : +49 4202 990409
  ! Company : Kl�ckner DESMA - Achim
  ! Dept.: Automation    Fax ext 501
  ! Version dated:   29.08.2002
  ! Based on roughing version 
  ! modified 02.08.1999: rotation-wise spraying
  ! modified 18.09.2000: rot-wise spraying in mould_change
  !**********************************************
  ! Program consists of  Program MODULE:
  !  - Spray_NC - Module M100 (Dummy)
  !**********************************************
  ! Module Spray_NC consists of PROC:
  !      main  -  wait   -  sle_on_off - code -
  !      mould_change  -prgToReg - ConfigOn/Off -
  !     check_level - Show_assignment -
  !      FUNC Proc-Exist - FUNC string Contents
  !***********************************************
  ! Alternative version declared as comments:
  !  "!X"  = Spray system without elektrostatic power
  !***********************************************
  !***********************************************
  PROC haupt()
    main;
  ENDPROC

  !***********************************************
  PROC principale()
    main;
  ENDPROC

  !***********************************************
  !  Procedure StartSpray()
  !  
  ! Setting spray outputs
  !  
  !***********************************************
  PROC StartSpray()
    SetDO\SDelay:=0.2,doSprayY2,1;
    SetDO\SDelay:=0.2,doTurbineY1,1;
  ENDPROC

  !***********************************************
  !  Procedure StopSpray()
  !  
  ! Reseting spray outputs
  !  
  !***********************************************
  PROC StopSpray()
    SetDO\SDelay:=0.2,doSprayY2,0;
    SetDO\SDelay:=0.2,doTurbineY1,0;
  ENDPROC

!**************************************************
!MouldChange with communication
!**************************************************
PROC mould_changeWithCom()
lbMode:
    Reset doRobotEndpos;
    nMouldChange:=1;
    TPErase;
    !
    TPWrite string30;
    TPWrite " ";
    TPWrite string31;
    TPWrite " ";
    TPWrite string32;
    TPWrite string80;
    TPWrite string33;
    TPWrite " ";
    TPReadFK nMode,string42,string49,string50,"","",string53;
    !
    TEST nMode
    CASE 1:
      TPErase;
      !******************************** 
      ! to Modul XXXX - program call 
      ! based on contents of nPrg_Num 
      !******************************** 
      code_direct_com;
      !
      Reset doTurbineY1;
      Reset doSprayY2;      
      !X  Reset doOpenNozzle;
      !X  Reset doSprayAir;
      MoveJ pWaitePos,v2000,z20,tDuese;
      TPErase;
      !
      GOTO lbMode;
      !
    CASE 2:
      TPErase;
      TPWrite string81;
      TPWrite " ";
      TPWrite string74;
      TPWrite " ";
      TPWrite " ";
      TPWrite " ";
      TPReadFK nKey,string42,string75,string76,"","",string21;
      TEST nKey
      CASE 1:
        TPErase;
        TPWrite " ";
        TPWrite " ";
        TPWrite string29;
        WaitTime 2;
        !
      CASE 2:
        TPErase;
        TPWrite " ";
        TPWrite string74;
        TPWrite " ";
        TPWrite string77;
        TPWrite " ";
        TPWrite string79;
        TPWrite " ";
        TPReadNum nNoSprayRotation,string78;
        !
      CASE 3,4,5:
        TPErase;
        GOTO lbMode;
      ENDTEST
      !
    CASE 3,4,5:
      TPErase;
    ENDTEST
    !************************
    ! label change finish 
    !************************
lbChangeEnd:
    TPErase;
    TPWrite " ";
    TPWrite string23;
    WaitDI diMouldChange,0;
    TPErase;
  ERROR
    RAISE;
  ENDPROC

  !Proc WaitWithCom
  PROC WaitWithCom()
    TPErase;
    PDispOff;
    Reset doTurbineY1;
    Reset doSprayY2;
    Reset doHighByteReadOK;
    Reset doLowByteReadOK;
    Reset doDirectComOK;
    !
    MoveJ pWaitePos,v800,z20,tDuese;
    TPWrite " ";
    TPWrite " ";
    TPWrite string1;
    WaitTime 0.1;
    Set doRobotEndpos;
    ! 
    WaitDI diTableEndpos,0;
    Set doAlarmLamp;
    TPErase;
    TPWrite " ";
    TPWrite " ";
    TPWrite string2;
    Reset doEnableLastTurn;
    WaitTime 0.2;
    WaitDI diTableEndpos,1;
    Reset doRobotEndpos;
    TPErase;
  ENDPROC

  ! Proc  code_direct_com
  PROC code_direct_com()
    Reset doDirectComOK;
    nAddByte:=0;
    WaitUntil diAddByteStrobe=1\MaxTime:=2\TimeFlag:=bAddByteFlag;
    IF bAddByteFlag=FALSE THEN
      WaitTime 0.1;
      nAddByte:=gi_RT_Code;
      Set doAddByteReadOk;
      WaitDI diAddByteStrobe,0;
      Reset doAddByteReadOk;
      nAddByte:=nAddByte*65536;
    ENDIF
    nHighByte:=0;
    WaitUntil diLowByteStrobe=0 AND diHighByteStrobe=1;
    WaitTime 0.1;
    nHighByte:=gi_RT_Code;
    Set doHighByteReadOK;
    WaitDI diHighByteStrobe,0;
    Reset doHighByteReadOK;
    nHighByte:=nHighByte*256;
    nLowByte:=0;
    WaitUntil diLowByteStrobe=1 AND diHighByteStrobe=0;
    WaitTime 0.1;
    nLowByte:=gi_RT_Code;
    Set doLowByteReadOK;
    WaitDI diLowByteStrobe,0;
    Reset doLowByteReadOK;
    !
    nPrg_Num:=nAddByte+nHighByte+nLowByte;
    !
    !
    IF nPrg_Num<0 GOTO lbWrongPrgNr;
    !
    WaitDI diStartRobot,1\MaxTime:=1\TimeFlag:=bSLE_Off;
    !
    IF diStartRobot=0 OR nPrg_Num=0 GOTO lbStationOff;
    ! 
    !********************************** 
    ! to Modul XXXX - program call 
    ! based on contents of nPrg_Num 
    !********************************** 
    IF nPrg_Num=0 THEN
      TPErase;
      TPWrite " ";
      TPWrite " ";
      TPWrite string35;
      WaitTime 3;
      RETURN;
    ENDIF
    TPWrite " ";
    TPWrite " ";
    TPWrite string26\Num:=nPrg_Num;
    CallByVar "P",nPrg_Num;
    !
    RETURN;
    !
lbWrongPrgNr:
    TPWrite " ";
    TPWrite " ";
    Set doDirectComOK;
    TPWrite string25;
    WaitTime 5;
    Reset doDirectComOK;
    RETURN;
    !
lbStationOff:
    Reset doDirectComOK;
    TPWrite " ";
    TPWrite " ";
    TPWrite string4;
    WaitTime 5;
    RETURN;
  ERROR
    RAISE;
  ENDPROC

  !***********************************************
  !  Procedure main()
  !  
  ! administration for spraying robot
  !  
  ! Version dated 30.10.97
  ! Modified 30.10.97: Error-Handling + upper_detection
  !***********************************************
  PROC main()
    TPErase;
lbStart:
    IF nCommType=1 THEN
      WaitWithCom;
      code_direct_com;
      IF diStartRobot=0 GOTO lbStart;
    ENDIF
    IF nCommType=0 THEN
      wait;
      sle_on_off;
      code;
    ENDIF
  ERROR
    IF ERRNO=168 THEN
      TPErase;
      TPWrite string37+NumToStr(nPrg_Num,0)+string38;
      TPReadFK nKey,string6,"","","","","OK";
      RETURN;
    ENDIF
  ENDPROC

  !***********************************************
  !***********************************************
  !   Procedure wait()
  !  
  ! rotary table turn and new endposition
  ! mould changing switch I/O
  !
  ! Version: 1.0		Date: 20.08.96
  ! Modified:	
  !***********************************************
  PROC wait()
    TPErase;
    PDispOff;
    Reset doTurbineY1;
    Reset doSprayY2;
    !X  Reset doOpenNozzle;
    !X  Reset doSprayAir;
    MoveJ pWaitePos,v800,z20,tPistol;
    !
    !  Place to insert ProcCall for "check_level"
    !
lbMouldChange:
    nMouldChange:=0;
    Set doRobotEndpos;
    ClkStop clock1;
    nTime:=ClkRead(clock1);
    TPWrite " ";
    TPWrite " ";
    TPWrite string1;
    TPWrite " ";
    TPWrite "Runtime = "\Num:=nTime;
    ! srvEnable;
    WaitUntil diMouldChange=1 OR diTableEndpos=0;
    !***************************************
    ! IF mould change switch is ON
    ! go to PROC : mould_change
    !***************************************
    IF diMouldChange=1 THEN
      mould_change;
      nMouldChange:=1;
      !
    ELSEIF diTableEndpos=0 THEN
      !******************************************* 
      !******************************************* 
      ! srvDisable;
      TPErase;
      TPWrite " ";
      TPWrite " ";
      TPWrite string2;
      WaitTime 0.2;
      WaitDI diTableEndpos,1;
      !******************************************* 
      ! przerwanie stop
      IDelete intno1;
      !******************************************* 
    ENDIF
    Reset doRobotEndpos;
    ClkReset clock1;
    ClkStart clock1;
    IF nMouldChange=1 GOTO lbMouldChange;
    TPErase;
    !
    nNoSprayCycles:=nSLE_Total*nNoSprayRotation;
    IF ncycle_count>nNoSprayCycles+nSLE_Total ncycle_count:=1;
  ERROR
    RAISE;
  ENDPROC

  !***********************************************
  !***********************************************
  !     Procedure sle_on_off ()
  !
  ! check initiator in front of spraying robot or
  ! start signal from roundtable control system
  !
  ! Version: 1.0		Date: 20.08.96
  ! Modified:	
  !***********************************************
  PROC sle_on_off()
    WaitDI diStartRobot,1\MaxTime:=1\TimeFlag:=bSLE_Off;
    IF diStartRobot=0 THEN
      TPWrite " ";
      TPWrite " ";
      TPWrite string4;
      WaitTime 2;
      RETURN;
    ENDIF
  ENDPROC

  !***********************************************
  !***********************************************
  !     Procedure code ()
  !
  ! read rotary table - code
  ! calculate robot position
  ! check code to be between 0 (zero)
  ! and max SLE-number 
  !
  ! Version dated 17.10.97
  ! Modified 17.10.97: pApproachPos hinter nPrg_Num=0
  !***********************************************
  PROC code()
    nSLE_Code:=gi_RT_Code;
    IF nSLE_Code<1 OR nSLE_Code>nSLE_Total GOTO lbCodingWrong;
    nSLE_Code:=nSLE_Code-nRob_Pos+1;
    IF nSLE_Code<=0 nSLE_Code:=nSLE_Code+nSLE_Total;
    WaitDI diTableEndpos,1;
    TPWrite " ";
    TPWrite " ";
    TPWrite string3\Num:=nSLE_Code;
    !***************************************
    !assignment from nSLE_x  to nPrg_Num
    !***************************************
    TEST nSLE_Code
    CASE 1:
      nPrg_Num:=nSLE_1;
    CASE 2:
      nPrg_Num:=nSLE_2;
    CASE 3:
      nPrg_Num:=nSLE_3;
    CASE 4:
      nPrg_Num:=nSLE_4;
    CASE 5:
      nPrg_Num:=nSLE_5;
    CASE 6:
      nPrg_Num:=nSLE_6;
    CASE 7:
      nPrg_Num:=nSLE_7;
    CASE 8:
      nPrg_Num:=nSLE_8;
    CASE 9:
      nPrg_Num:=nSLE_9;
    CASE 10:
      nPrg_Num:=nSLE_10;
    CASE 11:
      nPrg_Num:=nSLE_11;
    CASE 12:
      nPrg_Num:=nSLE_12;
    CASE 13:
      nPrg_Num:=nSLE_13;
    CASE 14:
      nPrg_Num:=nSLE_14;
    CASE 15:
      nPrg_Num:=nSLE_15;
    CASE 16:
      nPrg_Num:=nSLE_16;
    CASE 17:
      nPrg_Num:=nSLE_17;
    CASE 18:
      nPrg_Num:=nSLE_18;
    CASE 19:
      nPrg_Num:=nSLE_19;
    CASE 20:
      nPrg_Num:=nSLE_20;
    CASE 21:
      nPrg_Num:=nSLE_21;
    CASE 22:
      nPrg_Num:=nSLE_22;
    CASE 23:
      nPrg_Num:=nSLE_23;
    CASE 24:
      nPrg_Num:=nSLE_24;
    CASE 25:
      nPrg_Num:=nSLE_25;
    CASE 26:
      nPrg_Num:=nSLE_26;
    CASE 27:
      nPrg_Num:=nSLE_27;
    CASE 28:
      nPrg_Num:=nSLE_28;
    CASE 29:
      nPrg_Num:=nSLE_29;
    CASE 30:
      nPrg_Num:=nSLE_30;
    ENDTEST
    !***************************************
    ! program call based on contents of nPrg_Num 
    !***************************************
    IF nPrg_Num=0 THEN
      TPErase;
      TPWrite " ";
      TPWrite " ";
      TPWrite string3\Num:=nSLE_Code;
      TPWrite " ";
      TPWrite string35;
      WaitTime 3;
      RETURN;
    ENDIF
    MoveJ pApproachPos,v400,z20,tPistol;
    !
    ! Sequence for rotation-wise spraying
    IF nNoSprayRotation>0 AND ncycle_count>nSLE_Total THEN
      TPErase;
      TPWrite " ";
      TPWrite string29;
      Config_Off;
      Config_On;
      RETURN;
    ENDIF
    !
    TPWrite " ";
    TPWrite " ";
    TPWrite string26\Num:=nPrg_Num;
    Config_Off;
    StartSpray;
    CallByVar "P",nPrg_Num;
    StopSpray;
    Config_On;
    !
    RETURN;
    !
lbCodingWrong:
    TPErase;
    TPWrite " ";
    TPWrite " ";
    TPWrite string5;
    TPReadFK nCodeWrong,string6,"","","","","OK";
    IF nCodeWrong=5 TPErase;
  ERROR
    RAISE;
  ENDPROC

  !***********************************************
  PROC Config_Off()
    ConfL\Off;
    ConfJ\Off;
  ENDPROC

  PROC Config_On()
    ConfL\On;
    ConfJ\On;
  ENDPROC

  !***********************************************
  !***********************************************
  !     Procedure mould_change ()
  !
  ! mould - changing - switch -  I/O
  !
  ! Version dated:   05.10.1998
  ! Modified:  Save-function added, prepared for DEScom
  !***********************************************
  PROC mould_change()
lbMode:
    Reset doRobotEndpos;
    TPErase;
    !
    TPWrite string31;
    TPWrite string32;
    TPWrite string80;
    TPWrite string40;
    TPWrite string41;
    TPWrite string33;
    ! TPWrite " ";
    TPReadFK nMode,string42,string49,string50,string51,string52,string53;
    !
    TEST nMode
    CASE 1:
      TPErase;
      !******************************** 
      ! to Modul XXXX - program call 
      ! based on contents of nPrg_Num 
      !******************************** 
      code;
      Reset doTurbineY1;
      Reset doSprayY2;
      !X  Reset doOpenNozzle;
      !X  Reset doSprayAir;
      MoveJ pWaitePos,v1500,z20,tPistol;
      !
      TPErase;
      GOTO lbMode;
      !
    CASE 2:
      TPErase;
      TPWrite string81;
      TPWrite " ";
      TPWrite string74;
      TPWrite " ";
      TPWrite " ";
      TPWrite " ";
      TPReadFK nKey,string42,string75,string76,"","",string21;
      TEST nKey
      CASE 1:
lbChangeBegin:
        TPErase;
        !********************************** 
        ! selection of station - number 
        !********************************** 
        TPWrite string7;
        TPWrite " ";
        TPWrite string8;
        TPWrite string9;
        TPWrite " ";
        TPReadNum nSLE_Num,string10;
        TPErase;
        !********************************** 
        ! check of station (SLE) number
        !********************************** 
        IF nSLE_Num=0 GOTO lbMode;
        IF nSLE_Num>nSLE_Total THEN
          TPErase;
          TPWrite " ";
          TPWrite " ";
          TPWrite " ";
          TPWrite string22;
          WaitTime 2;
          GOTO lbChangeBegin;
        ENDIF
        !********************************** 
        ! selection  of program - number
        !********************************** 
lbChangeProgrNr:
        TPWrite string11\Num:=nSLE_Num;
        TPWrite " ";
        TPWrite string54\Num:=nSLE_{nSLE_Num};
        TPWrite string16;
        TPWrite string34;
        TPWrite " ";
        TPReadNum nPrg_Num,"min=100 max=8388608";
        !********************************** 
        ! check program - number 
        !********************************** 
        IF nPrg_Num=0 THEN
          TPErase;
          TPWrite " ";
          TPWrite " ";
          TPWrite string36\Num:=nSLE_Num;
          WaitTime 3;
          GOTO lbNoProgr;
        ENDIF
        !
        IF nPrg_Num<100 OR nPrg_Num>8388608 THEN
          TPErase;
          TPWrite " ";
          TPWrite " ";
          TPWrite " ";
          TPWrite string25;
          WaitTime 2;
          GOTO lbChangeProgrNr;
        ENDIF
        !
lbNoProgr:
        TPErase;
        TPWrite " ";
        TPWrite string23;
        WaitDI diMouldChange,0;
        TPErase;
        prgToReg;
        RETURN;
        !
      CASE 2:
        TPErase;
        TPWrite " ";
        TPWrite string74;
        TPWrite " ";
        TPWrite string77;
        TPWrite " ";
        TPWrite string79;
        TPWrite " ";
        TPReadNum nNoSprayRotation,string78;
        !
      CASE 3,4,5:
        TPErase;
        GOTO lbMode;
      ENDTEST
      !
    CASE 3:
      TPErase;
      ! For activating DEScom: delete the 4 following instructions!
      TPWrite " ";
      TPWrite " ";
      TPWrite string29;
      WaitTime 2;
      ! prSave;
      GOTO lbMode;
      !
    CASE 4:
      Show_Assignment;
      GOTO lbMode;
      !
    CASE 5:
      TPErase;
      TPWrite " ";
      TPWrite string23;
      WaitDI diMouldChange,0;
      TPErase;
    ENDTEST
  ERROR
    RAISE;
  ENDPROC

  !***********************************************
  !***********************************************
  !   Function  string Contents :
  ! Function to prepare the program number for being
  !   presented on display in PROC Show_Assignment
  !***********************************************
  FUNC string Contents(
    num slenum)

    VAR num Length;
    VAR string Content;

    Content:=NumToStr(slenum,0);
    Length:=StrLen(Content);
    TEST Length
    CASE 1:
      Content:="       "+Content;
    CASE 2:
      Content:="      "+Content;
    CASE 3:
      Content:="     "+Content;
    CASE 4:
      Content:="    "+Content;
    CASE 5:
      Content:="   "+Content;
    CASE 6:
      Content:="  "+Content;
    CASE 7:
      Content:=" "+Content;
    ENDTEST
    RETURN Content;
  ENDFUNC

  !***********************************************
  !***********************************************
  !   Procedure  Show_Assignment :
  ! Procedure to show a list of the actual program numbers
  !   per station on the display by "mould_change"-function
  !***********************************************
  PROC Show_Assignment()
    VAR string SLE_1_3;
    VAR string SLE_4_6;
    VAR string SLE_7_9;
    VAR string SLE_10_12;
    VAR string SLE_13_15;
    VAR string SLE_16_18;
    VAR string SLE_19_21;
    VAR string SLE_22_24;
    VAR string SLE_25_27;
    VAR string SLE_28_30;

    SLE_1_3:="S 1:"+Contents(nSLE_1)+"  S 2:"+Contents(nSLE_2)+"  S 3:"+Contents(nSLE_3);
    SLE_4_6:="S 4:"+Contents(nSLE_4)+"  S 5:"+Contents(nSLE_5)+"  S 6:"+Contents(nSLE_6);
    SLE_7_9:="S 7:"+Contents(nSLE_7)+"  S 8:"+Contents(nSLE_8)+"  S 9:"+Contents(nSLE_9);
    SLE_10_12:="S10:"+Contents(nSLE_10)+"  S11:"+Contents(nSLE_11)+"  S12:"+Contents(nSLE_12);
    SLE_13_15:="S13:"+Contents(nSLE_13)+"  S14:"+Contents(nSLE_14)+"  S15:"+Contents(nSLE_15);
    SLE_16_18:="S16:"+Contents(nSLE_16)+"  S17:"+Contents(nSLE_17)+"  S18:"+Contents(nSLE_18);
    SLE_19_21:="S19:"+Contents(nSLE_19)+"  S20:"+Contents(nSLE_20)+"  S21:"+Contents(nSLE_21);
    SLE_22_24:="S22:"+Contents(nSLE_22)+"  S23:"+Contents(nSLE_23)+"  S24:"+Contents(nSLE_24);
    SLE_25_27:="S25:"+Contents(nSLE_25)+"  S26:"+Contents(nSLE_26)+"  S27:"+Contents(nSLE_27);
    SLE_28_30:="S28:"+Contents(nSLE_28)+"  S29:"+Contents(nSLE_29)+"  S30:"+Contents(nSLE_30);
lbPage1:
    TPErase;
    TPWrite SLE_1_3;
    TPWrite SLE_4_6;
    IF nSLE_Total>6 THEN
      TPWrite SLE_7_9;
      TPWrite SLE_10_12;
    ENDIF
    IF nSLE_Total<7 OR nSLE_Total<13 THEN
      TPReadFK nKey,"","","","","CANCEL","";
      IF nKey=4 RETURN;
    ENDIF
    TPWrite SLE_13_15;
    TPReadFK nKey,"","","","","CANCEL","NEXT";
    TPErase;
    IF nKey=4 RETURN;
    TPWrite SLE_16_18;
    IF nSLE_Total>18 THEN
      TPWrite SLE_19_21;
      TPWrite SLE_22_24;
    ENDIF
    IF nSLE_Total>24 THEN
      TPWrite SLE_25_27;
      TPWrite SLE_28_30;
    ENDIF
    TPReadFK nKey,"","","","","CANCEL","BACK";
    TPErase;
    IF nKey=5 GOTO lbPage1;
    RETURN;
  ENDPROC

  !***********************************************
  !***********************************************
  !  Procedure  prgToReg()
  !  
  ! assignment  nPrg_Num to nSLE_x  
  !
  ! Version: 1.0		Date: 20.08.96
  ! Modified:	
  !***********************************************
  PROC prgToReg()
    nSLE_{nSLE_Num}:=nPrg_Num;
    TEST nSLE_Num
    CASE 1:
      nSLE_old:=nSLE_1;
      nSLE_1:=nPrg_Num;
    CASE 2:
      nSLE_old:=nSLE_2;
      nSLE_2:=nPrg_Num;
    CASE 3:
      nSLE_old:=nSLE_3;
      nSLE_3:=nPrg_Num;
    CASE 4:
      nSLE_old:=nSLE_4;
      nSLE_4:=nPrg_Num;
    CASE 5:
      nSLE_old:=nSLE_5;
      nSLE_5:=nPrg_Num;
    CASE 6:
      nSLE_old:=nSLE_6;
      nSLE_6:=nPrg_Num;
    CASE 7:
      nSLE_old:=nSLE_7;
      nSLE_7:=nPrg_Num;
    CASE 8:
      nSLE_old:=nSLE_8;
      nSLE_8:=nPrg_Num;
    CASE 9:
      nSLE_old:=nSLE_9;
      nSLE_9:=nPrg_Num;
    CASE 10:
      nSLE_old:=nSLE_10;
      nSLE_10:=nPrg_Num;
    CASE 11:
      nSLE_old:=nSLE_11;
      nSLE_11:=nPrg_Num;
    CASE 12:
      nSLE_old:=nSLE_12;
      nSLE_12:=nPrg_Num;
    CASE 13:
      nSLE_old:=nSLE_13;
      nSLE_13:=nPrg_Num;
    CASE 14:
      nSLE_old:=nSLE_14;
      nSLE_14:=nPrg_Num;
    CASE 15:
      nSLE_old:=nSLE_15;
      nSLE_15:=nPrg_Num;
    CASE 16:
      nSLE_old:=nSLE_16;
      nSLE_16:=nPrg_Num;
    CASE 17:
      nSLE_old:=nSLE_17;
      nSLE_17:=nPrg_Num;
    CASE 18:
      nSLE_old:=nSLE_18;
      nSLE_18:=nPrg_Num;
    CASE 19:
      nSLE_old:=nSLE_19;
      nSLE_19:=nPrg_Num;
    CASE 20:
      nSLE_old:=nSLE_20;
      nSLE_20:=nPrg_Num;
    CASE 21:
      nSLE_old:=nSLE_21;
      nSLE_21:=nPrg_Num;
    CASE 22:
      nSLE_old:=nSLE_22;
      nSLE_22:=nPrg_Num;
    CASE 23:
      nSLE_old:=nSLE_23;
      nSLE_23:=nPrg_Num;
    CASE 24:
      nSLE_old:=nSLE_24;
      nSLE_24:=nPrg_Num;
    CASE 25:
      nSLE_old:=nSLE_25;
      nSLE_25:=nPrg_Num;
    CASE 26:
      nSLE_old:=nSLE_26;
      nSLE_26:=nPrg_Num;
    CASE 27:
      nSLE_old:=nSLE_27;
      nSLE_27:=nPrg_Num;
    CASE 28:
      nSLE_old:=nSLE_28;
      nSLE_28:=nPrg_Num;
    CASE 29:
      nSLE_old:=nSLE_29;
      nSLE_29:=nPrg_Num;
    CASE 30:
      nSLE_old:=nSLE_30;
      nSLE_30:=nPrg_Num;
    DEFAULT:
      TPWrite string22;
      WaitTime 2;
    ENDTEST
    ! IF nSLE_old=0 AND nPrg_Num=0 RETURN;
    ! IF srvInit() THEN
    !   TPErase;
    !   TPWrite " ";
    !   TPWrite " ";
    !   TPWrite string43;
    !   WaitTime 0.2;
    !   prExchange;
    ! ENDIF
  ENDPROC

  !***********************************************
  !***********************************************
  !    Procedure check_level
  !
  !   Procedure to check the material level of the tank (OPTION)
  !
  !   Version dated 27.03.97
  !***********************************************
  PROC check_level()
    IF diMaterialLevel=0 THEN
      nMinCounter:=nMinCounter+1;
      Set doAlarmLamp;
      TPWrite " ";
      TPWrite string24;
      IF nMinCounter>50 THEN
        WaitDI diMaterialLevel,1;
        nMinCounter:=0;
        Reset doAlarmLamp;
      ENDIF
    ELSE
      nMinCounter:=0;
      Reset doAlarmLamp;
    ENDIF
  ENDPROC
ENDMODULE
