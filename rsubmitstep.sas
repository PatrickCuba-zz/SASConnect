%Macro RsubmitStep(InheritLib=, DownloadWork=, UploadWork=);

	/* Check if Connect Handles has run */
    %If %Symexist(__MaxHandles)=0 %Then %Do;
		%Put NOTE: ConnectHandle has not run... running it now... ;
		%ConnectHandles;
	%End;

	/* Check we still have free handles */
	%If &&__Hdle&__MaxHandles.=Used %Then %Do;
		%Put NOTE: More Handles needed;
		%Let __MaxHandles=%Eval(&__MaxHandles.+1);
        %Global __Hdle&__MaxHandles;
    	%Let __Hdle&__MaxHandles=Free;
 		%Put NOTE: Sign on with handle __Hdle&__MaxHandles = &&__Hdle&__MaxHandles;

		Filename F&__MaxHandles TEMP;
	%End;

	%Put NOTE: Available Handles=&__MaxHandles.;
 	%Put NOTE: Handles used=&__HandlesUsed.;
	%Global DownloadWork2;
	%Let DownloadWork2=&DownloadWork.;

	/* Testing for Free handles - once found use as token for RSUBMIT */
	%Do R=1 %To &__MaxHandles.;
		%Put CHECK __Hdle&R=&&__Hdle&R;
		%If &&__Hdle&R=Free %Then %Do;
		    %Let __Hdle&R=Used;
	        %Global __Hdle&R FileRef;
			%Put NOTE: Using Handle __Hdle&R;
			%Let __HandlesUsed=&R.;
			%Let __HandlesUsedTxt=&__HandlesUsedTxt. __Hdle&R.;
			%Let Token=__Hdle&R;

			/* If we have libraries to ingest include them here */
			%If &InheritLib^= %Then %Let InheritLib=InheritLib=(&InheritLib.);
			/* Save Rsubmit statement */
			%Let FileRef=F&R.;
			%If &__CanParallel.=1 %Then %Do;
				%Put NOTE: Creating RSubmit Script... ;

				Data _Null_;
					File F&R.;
					Put "signon &Token.;";
					Put '%Let MasterWork=%Sysfunc(Pathname(Work));';
					Put '%syslput _all_ ;';
					/* Copy compiled macros catalog - needed as the sessions catalog is locked */
					Put '%Put NOTE: Copying Compiled Macro Catalog to unlocked catalog;';
					Put 'Data _null_;';
					Put '	Keep fname;';
					Put '	Length MyDir $8.;';
					Put '	Rc=Filename(MyDir,"&MasterWork");';
					Put '	Did=DOpen(MyDir);';
					Put '	Dnum=Dnum(Did);';
					Put '	Do D = 1 to Dnum;';
					Put '		fname=Dread(Did,D);';
					Put "		If Scan(fname, -1, '.')='sas7bcat' and substr(fname,1,6)='sasmac' then Call Symput('MySASMacVar', Scan(fname, 1, '.'));";
					Put '	End;';
					Put '	Rc=DClose(Did);';
					Put 'Run;';
					Put '%Put NOTE: MySASMacVar=&MySASMacVar.;';

					Put 'proc catalog c=work.&MySASMacVar. et=macro;  ';
					Put '  copy ';
					Put '  out=work.mysasmacr;';
					Put 'quit; ';
					Put "rsubmit &Token. wait = no sysrputsync = yes persist = no &InheritLib.;";

					/* Access to parent format */
					Put 'libname lwork "&MasterWork.";';
					Put '%Put NOTE: Link local formats to parent format session ;';
					Put 'options append=(fmtsearch=(lwork));';

                    /* Include any additional variables/macros to parse to rsubmitted code */	
					Put '%Let SlaveWorkPath=%Sysfunc(Pathname(Work));';
					Put 'Libname SWork "&SlaveWorkPath.";';
					Put '%Put NOTE: Copy parent compiled macros to local session;';
					Put 'proc catalog c=lwork.mysasmacr et=macro;  ';
					Put '  copy ';
					Put '  out=SWork.SASMACR;';
					Put 'quit; ';
					Put 'Options mstored sasmstore=SWork;';
					%If &UploadWork. ^= %Then %Do;
						%Let UploadWorkCount=%Sysfunc(CountW(&UploadWork));
						%Put NOTE: Number of tables to upload=&UploadWorkCount.;
						%Do SelectUploadCount=1 %To &UploadWorkCount.;
							%Let SelectUpload=%Scan(&UploadWork., &SelectUploadCount.);
							Put "Proc Upload Data=&SelectUpload. Out=&SelectUpload.; Run;";
						%End;
					%End;
					Put '%pre_process;';
				Run;

				/* Download any datasets to Client WORK directory*/
				%If &DownloadWork. ^= %Then %Do;
				    Data _Null_;
						File F&R. MOD;
						Put 'Filename Fend TEMP;';
						Put 'Data _null_;';
						Put '   Length Table $256. SrcTable TgtTable $42.;';
						Put '   File FEnd;';
						Put '   Tables="&DownloadWork2.";';
						Put '   NumberOfTables=Sum(Count(Strip(Compbl(Tables))," "), 1);';
						Put '   Putlog "NOTE: Number of Tables to Download is " NumberOfTables;';
						Put '   Do x=1 To NumberOfTables;';
						Put '   SrcTable=Scan(Tables, x, " ");';
						Put '   If Index(SrcTable, ".") Then TgtTable=Scan(Table, -1, ".");';
						Put '   Else TgtTable=Tables;';
						Put '      Table=Compbl("Proc Download Data="|| SrcTable ||" Out="|| TgtTable ||"; Run;");';
						Put '      Put Table;';
						Put '   End;';
						Put 'Run;';
					Run;
				%End;
				%Else %Do;
				    Data _Null_;
						File F&R. MOD;
						Put 'Filename Fend TEMP;';
						Put 'Data _null_;';
						Put '   File FEnd;';
						Put '   Putlog "NOTE: No downloads";';
						Put 'Run;';
					Run;
				%End;
			%End;
			%Else %Do;
				%Put NOTE: Creating Empty Script... ;
				Data _Null_;
					File F&R.;
					Put "Data _null_; "; 
                    Put "Put 'NOTE: No SAS/Connect Detected - no RSUBMIT';";
                    Put "Run;";
				Run;
			%End;
			/* Exist Macro loop */
			%Goto EndofMac;
		%End;
	%End;
%EndofMac:

%Mend;