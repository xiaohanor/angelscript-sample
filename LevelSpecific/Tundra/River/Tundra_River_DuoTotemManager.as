event void FTriggerEvent();

class ATundra_River_DuoTotemManager : AHazeActor
{
	bool bTreeGuardianReady = false;
	bool bMonkeyReady = false;

	UPROPERTY()
	FTriggerEvent StartBoulderChase;

	UFUNCTION()
	void SetTreeManReady(bool Ready)
	{
		if(HasControl())
		{
			bTreeGuardianReady = Ready;
			ReadyCheck();
		}
	}

	UFUNCTION()
	void SetMonkeyReady(bool Ready)
	{
		if(HasControl())
		{
			bMonkeyReady = Ready;
			ReadyCheck();
		}
	}
	
	void ReadyCheck()
	{
		if(bMonkeyReady && bTreeGuardianReady)
		{
			CrumbTriggerBoulderChase();
		}
	}

	UFUNCTION(CrumbFunction)
	void CrumbTriggerBoulderChase()
	{
		StartBoulderChase.Broadcast();
	}
}