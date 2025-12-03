class UTundraBossFallingIceSpikeCapability : UTundraBossChildCapability
{
	bool bIsSlowVersion = false;
	bool bHasTriggeredIcicles = false;
	float InitialDelay = 2.5;
	float Duration;
	ETundraBossStates FallState;

	float SlowDropInterval = 3;
	float FastDropInterval = 1;

	bool bIsInLastPhase = false;

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FTundraBossFallingIceSpikeParams& Params) const
	{
		if(Boss.State != ETundraBossStates::TriggerFallingIceSpikes
		&& Boss.State != ETundraBossStates::TriggerFallingIceSpikesSlowVersion)
			return false;

		if(Boss.State == ETundraBossStates::TriggerFallingIceSpikesSlowVersion)
		{
			Params.bIsSlowVersion = true;
		}
		else
		{
			Params.bIsSlowVersion = false;
		}

		Params.bIsInLastPhase = Boss.IsInLastPhase();

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Boss.State != ETundraBossStates::TriggerFallingIceSpikes
		&& Boss.State != ETundraBossStates::TriggerFallingIceSpikesSlowVersion)
			return true;

		if(ActiveDuration > Duration)
			return true;
		
		return false;
	}


	UFUNCTION(BlueprintOverride)
	void OnActivated(FTundraBossFallingIceSpikeParams Params)
	{
		Duration = Boss.AnimInstance.GetTundraBossAnimationDuration(ETundraBossAttackAnim::TriggerFallingIcicles);
		bIsSlowVersion = Params.bIsSlowVersion;
		bIsInLastPhase = Params.bIsInLastPhase;
		bHasTriggeredIcicles = false;
		Boss.RequestAnimation(ETundraBossAttackAnim::TriggerFallingIcicles);
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
		if(ActiveDuration > InitialDelay && !bHasTriggeredIcicles)
		{
			bHasTriggeredIcicles = true;
			Boss.FallingIciclesManager.StartDroppingIcicles(bIsSlowVersion ? SlowDropInterval : FastDropInterval, bIsInLastPhase);
		}
	}
};

struct FTundraBossFallingIceSpikeParams
{
	bool bIsSlowVersion;
	bool bIsInLastPhase;
}