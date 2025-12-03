enum ETundraBossLocation
{
	Front,
	Left,
	Right
}

class UTundraBossJumpToLocationCapability : UTundraBossChildCapability
{
	float Duration;

	bool bShouldTogglePhase02Platforms = false;
	bool bHasRaisedPlatform = false;
	float PlatformSwitchDelay = 1;
	float PlatformSwitchDelayTimer = 0;
	bool bInLastPhase = false;

	ETundraBossLocation StartLocation;
	ETundraBossLocation TargetLocation;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FTundraBossJumpToLocationParams& Params) const
	{
		if(Boss.State != ETundraBossStates::JumpToNextLocation)
			return false;

		Params.StartLocation = Boss.CurrentBossLocation;
		Params.TargetLocation = Boss.SetTargetLocation();
		Params.bInLastPhase = Boss.IsInLastPhase();

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(ActiveDuration > Duration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FTundraBossJumpToLocationParams Params)
	{		
		Duration = Boss.AnimInstance.GetTundraBossAnimationDuration(ETundraBossAttackAnim::Wallrun);

		StartLocation = Params.StartLocation;
		TargetLocation = Params.TargetLocation;
		bInLastPhase = Params.bInLastPhase;
		
		PlatformSwitchDelayTimer = 0;
		bHasRaisedPlatform = false;

		if(bInLastPhase)
		{
			bShouldTogglePhase02Platforms = false;
			LastPhaseJump();			
		}
		else
		{
			bShouldTogglePhase02Platforms = true;
		}

		Boss.RequestAnimation(ETundraBossAttackAnim::Wallrun);
		UTundraBossRingOfIceSpikesActor_EffectHandler::Trigger_JumpedToNextLocation(Boss);
		Boss.OnAttackEventHandler(Duration);		
	}

	void LastPhaseJump()
	{
		Boss.JumpedToNewLocationInLastPhase.Broadcast();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if(!HasControl())
			return;
		
		Boss.CurrentBossLocation = TargetLocation;
		Boss.CapabilityStopped(ETundraBossStates::JumpToNextLocation);
	}
	
	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(bShouldTogglePhase02Platforms && !bHasRaisedPlatform)
		{
			PlatformSwitchDelayTimer += DeltaTime;
			if(PlatformSwitchDelayTimer < PlatformSwitchDelay)
				return;

			bHasRaisedPlatform = true;
			ATundraBossBossPlatform PlatformToShow = Boss.GetTargetPhase02Platform(TargetLocation);			
			Boss.ActivateNextBossPlatform(PlatformToShow, bInLastPhase);
		}
		else
		{
			if(ActiveDuration > 0.75 && !bHasRaisedPlatform)
			{
				bHasRaisedPlatform = true;
				
				ATundraBossBossPlatform PlatformToShow = Boss.GetTargetPhase03Platform(TargetLocation);			
				Boss.ActivateNextBossPlatform(PlatformToShow, bInLastPhase);
			}
		}
	}
};

struct FTundraBossJumpToLocationParams
{
	ETundraBossLocation StartLocation;
	ETundraBossLocation TargetLocation;
	bool bInLastPhase;
}