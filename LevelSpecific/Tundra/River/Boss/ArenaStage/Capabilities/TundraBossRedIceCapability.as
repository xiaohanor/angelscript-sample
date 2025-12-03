class UTundraBossFallingRedIceCapability : UTundraBossChildCapability
{
	bool bIsSlowVersion = false;
	bool bHasTriggeredRedIce = false;
	bool bIsLastPhase = false;
	float InitialDelay = 2.0;
	float Duration;
	ETundraBossStates FallState;

	float SlowDropInterval = 2;
	float FastDropInterval = 1;

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FTundraBossRedIceParams& Params) const
	{
		if(Boss.State != ETundraBossStates::TriggerRedIce
		&& Boss.State != ETundraBossStates::TriggerRedIceSlowVersion)
			return false;

		Params.bIsSlowVersion = SetSlowVersion();
		Params.bIsLastPhase = Boss.IsInLastPhase();

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Boss.State != ETundraBossStates::TriggerRedIce
		&& Boss.State != ETundraBossStates::TriggerRedIceSlowVersion)
			return true;

		if(ActiveDuration > Duration)
			return true;
		
		return false;
	}


	UFUNCTION(BlueprintOverride)
	void OnActivated(FTundraBossRedIceParams Params)
	{
		Duration = Boss.AnimInstance.GetTundraBossAnimationDuration(ETundraBossAttackAnim::TriggerRedIce);
		bIsSlowVersion = Params.bIsSlowVersion;
		bIsLastPhase = Params.bIsLastPhase;
		bHasTriggeredRedIce = false;
		Boss.RequestAnimation(ETundraBossAttackAnim::TriggerRedIce);	
		Boss.OnAttackEventHandler(Duration);

		if(!HasControl())
			return;
				
		FallState = Boss.State;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Boss.Mesh.SetAnimBoolParam(n"ExitIceKingAnimation", true);

		if(!HasControl())
			return;
		
		Boss.CapabilityStopped(FallState);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		if(ActiveDuration > InitialDelay && !bHasTriggeredRedIce)
		{
			bHasTriggeredRedIce = true;
			Boss.RedIceManager.StartSpawningRedIce(bIsSlowVersion ? SlowDropInterval : FastDropInterval, bIsLastPhase);
		}
	}

	bool SetSlowVersion() const
	{
		if(Boss.State == ETundraBossStates::TriggerRedIceSlowVersion)
		{
			return true;
		}
		else
		{
			return false;
		}
	}
};

struct FTundraBossRedIceParams
{
	bool bIsSlowVersion;
	bool bIsLastPhase;
}