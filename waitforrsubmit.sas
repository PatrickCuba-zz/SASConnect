%Macro WaitForRsubmit(Type=);
	%If &__CanParallel.=1 %Then %Do;
		%Let Type=%Sysfunc(CoalesceC(&Type., _all_));
		waitfor &Type. &__HandlesUsedTxt.;
	%End;

	%Put NOTE: Unassign used Handles;
	%Do F=1 %To &__MaxHandles.;
		%Let __Hdle&F=Free;
		%Let __HandlesUsedTxt=;
		%Let __HandlesUsed=0;
	%End;
%Mend;