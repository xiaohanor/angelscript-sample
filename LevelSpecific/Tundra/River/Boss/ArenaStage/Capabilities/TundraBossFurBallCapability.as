class UTundraBossFurBallCapability : UTundraBossChildCapability
{
	float Duration;

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(Boss.State != ETundraBossStates::Furball)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Boss.State != ETundraBossStates::Furball)
			return true;

		if(ActiveDuration >= Duration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Duration = Boss.AnimInstance.GetTundraBossAnimationDuration(ETundraBossAttackAnim::FurBall);
		Boss.RequestAnimation(ETundraBossAttackAnim::FurBall);
		Boss.OnAttackEventHandler(Duration);
		Boss.bStopFurballFromSpawning = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Boss.Mesh.SetAnimBoolParam(n"ExitIceKingAnimation", true);
		Boss.CapabilityStopped(ETundraBossStates::Furball);
	}
};