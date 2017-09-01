%Macro ConnectHandles(ConnectHandles=);
    /* Detect required parallel products */       
    %Global __CanParallel __EndRsubmit;
	Options Source2 ;

	%Let __EndRsubmit=;

	%Let __CanParallel=%Sysfunc(sysprod(connect));
	%If &ConnectHandles.= %Then %Let ConnectHandles=1;

	%If &__CanParallel.=1 %Then %Do;
		*** Step 1a: Required Connect Options *** ;
		%let noobjserver=%quote(-noobjectserver);
		
		/* Get Work path from Master session */
		/* Ensure subprocesses are kept under the same Work subfolder but own subdirectory */
		%Let Master_WorkPath=%Sysfunc(pathname(Work));
		%Put NOTE: Master_WorkPath=&Master_WorkPath.;
		options sascmd = "!sascmd &noobjserver -Work &Master_WorkPath.";

		%Global __MaxHandles __HandlesUsed __HandlesUsedTxt;
		%Let __HandlesUsedTxt=;
 		%Let __HandlesUsed=0;

		/* Generate required Handles */
	    %Do H=1 %To &ConnectHandles.;
		     %Global __Hdle&H;
	    	 %Let __Hdle&H=Free;
	 		 %Put NOTE: Sign on with handle __Hdle&H = &&__Hdle&H;

			 Filename F&H TEMP;
		%End;
    %End;
	%Else %Do;
		%Put WARNING: No Connect detected;
		/* Generate empty files if we have no Connect */
		%Do H=1 %To &ConnectHandles.;
		     %Global __Hdle&H;
	    	 %Let __Hdle&H=Free;
			 Filename F&H TEMP;
		%End;
	%End;

	%Let __MaxHandles=&ConnectHandles.;
%Mend;