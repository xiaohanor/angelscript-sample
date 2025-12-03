class UTundraBossClawAttackCapability : UTundraBossChildCapability
{
	float Duration;	
	float RelativeZ = 0;
	float RelativeZPhase02 = -453.0;
	float RelativeZPhase03 = -663.0;

	ETundraBossStates CurrentState;

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FTundraBossClawAttackParams& Params) const
	{
		if(Boss.State != ETundraBossStates::ClawAttack && Boss.State != ETundraBossStates::ClawAttackShort)
			return false;
		
		Params.BossState = Boss.State;
		// TODO: Could be removed right? Not used in Phase03
		Params.RelativeZ = Boss.IsInLastPhase() ? RelativeZPhase03 : RelativeZPhase02;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Boss.State == ETundraBossStates::SphereDamage)
			return true;

		if(ActiveDuration > Duration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FTundraBossClawAttackParams Params)
	{
		CurrentState = Params.BossState;
		UTundraBoss_EffectHandler::Trigger_OnClawAttackStarted(Boss);
		
		Duration = CurrentState == ETundraBossStates::ClawAttack ? Boss.AnimInstance.GetTundraBossAnimationDuration(ETundraBossAttackAnim::ClawAttack) : Boss.AnimInstance.GetTundraBossAnimationDuration(ETundraBossAttackAnim::ClawAttackShort);
		//Some buffer
		Duration += 0.5;

		RelativeZ = Params.RelativeZ;

		Boss.SpawnClawAttackRightPaw.AddUFunction(this, n"SpawnClawAttackRight");
		Boss.SpawnClawAttackLeftPaw.AddUFunction(this, n"SpawnClawAttackLeft");

		ETundraBossAttackAnim AnimToRequest = CurrentState == ETundraBossStates::ClawAttack ? ETundraBossAttackAnim::ClawAttack : ETundraBossAttackAnim::ClawAttackShort;
		Boss.RequestAnimation(AnimToRequest);

		Boss.ClawAttackNewRight.ActorRelativeLocation = FVector(Boss.ClawAttackNewRight.ActorRelativeLocation.X, Boss.ClawAttackNewRight.ActorRelativeLocation.Y, RelativeZ);
		Boss.ClawAttackNewLeft.ActorRelativeLocation = FVector(Boss.ClawAttackNewLeft.ActorRelativeLocation.X, Boss.ClawAttackNewLeft.ActorRelativeLocation.Y, RelativeZ);
		Boss.OnAttackEventHandler(Duration);
	}

	UFUNCTION()
	private void SpawnClawAttackLeft()
	{
		SpawnClawAttack(false);
	}

	UFUNCTION()
	private void SpawnClawAttackRight()
	{		
		SpawnClawAttack(true);
	}

	private void SpawnClawAttack(bool bRightPaw)
	{
		if(bRightPaw)
		{
			UTundraBoss_EffectHandler::Trigger_OnClawAttackRight(Boss);
			Boss.ClawAttackNewRight.ActivateClawAttack(Boss);
		}
		else
		{
			UTundraBoss_EffectHandler::Trigger_OnClawAttackLeft(Boss);
			Boss.ClawAttackNewLeft.ActivateClawAttack(Boss);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Boss.Mesh.SetAnimBoolParam(n"ExitIceKingAnimation", true);
		Boss.SpawnClawAttackRightPaw.Unbind(this, n"SpawnClawAttackRight");
		Boss.SpawnClawAttackLeftPaw.Unbind(this, n"SpawnClawAttackLeft");
		UTundraBoss_EffectHandler::Trigger_OnClawAttackEnded(Boss);
		Boss.CapabilityStopped(CurrentState);
	}
};

struct FTundraBossClawAttackParams
{
	ETundraBossStates BossState;
	float RelativeZ;
}