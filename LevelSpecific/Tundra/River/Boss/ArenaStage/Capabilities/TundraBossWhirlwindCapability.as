class UTundraBossWhirlwindCapability : UTundraBossChildCapability
{
	float Duration = 18;
	ETundraBossStates CurrentState;

	float JumpTimer = 0;
	float JumpTimerDuration = 6.5;
	bool bHasRequestedJumpAnim = false;

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FTundraBossWhirlwindParams& Params) const
	{
		if(Boss.State != ETundraBossStates::Whirlwind && Boss.State != ETundraBossStates::WhirlwindWithJump)
			return false;

		Params.CurrentState = Boss.State;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(ActiveDuration > Duration)
			return true;
		
		if(Boss.State == ETundraBossStates::Whirlwind)
			return false;

		if(Boss.State == ETundraBossStates::WhirlwindWithJump)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FTundraBossWhirlwindParams Params)
	{
		CurrentState = Params.CurrentState;
		bHasRequestedJumpAnim = false;
		JumpTimer = 0;
		
		Boss.RequestAnimation(ETundraBossAttackAnim::Whirlwind);
		Boss.OnAttackEventHandler(Duration);
		//We only need foreshadow before the "WithJump" version.
		bool bWithForeshadow = CurrentState == ETundraBossStates::Whirlwind ? false : true;
		Boss.WhirlwindActor.ActivateWhirlwind(2, bWithForeshadow);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Boss.Mesh.SetAnimBoolParam(n"ExitIceKingAnimation", true);
		Boss.WhirlwindActor.DeactivateWhirlwind();
		Boss.CapabilityStopped(CurrentState);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(CurrentState == ETundraBossStates::WhirlwindWithJump && !bHasRequestedJumpAnim)
		{
			JumpTimer += DeltaTime;
			if(JumpTimer >= JumpTimerDuration)
			{
				bHasRequestedJumpAnim = true;
				Boss.RequestAnimation(ETundraBossAttackAnim::Wallrun);
				Timer::SetTimer(this, n"RaisePlatform", 0.25);
				
				if(HasControl())
					Boss.JumpedToNewLocationInLastPhase.Broadcast();
			}
		}
	}

	UFUNCTION()
	void RaisePlatform()
	{
		ATundraBossBossPlatform PlatformToShow = Boss.GetTargetPhase03Platform(ETundraBossLocation::Front);			
		Boss.ActivateNextBossPlatform(PlatformToShow, true);
	}
};

struct FTundraBossWhirlwindParams
{
	ETundraBossStates CurrentState;
}