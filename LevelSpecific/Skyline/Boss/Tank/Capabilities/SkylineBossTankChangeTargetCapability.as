struct FSkylineBossTankChangeTargetActivateParams
{
	AHazeActor TargetToChangeTo;
};

class USkylineBossTankChangeTargetCapability : USkylineBossTankChildCapability
{
	default CapabilityTags.Add(SkylineBossTankTags::SkylineBossTankChangeTarget);

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FSkylineBossTankChangeTargetActivateParams& Params) const
	{
		if (!BossTank.HasAttackTarget())
			return false;

		bool bShouldActivate = false;
		if (BossTank.GetBikeFromTarget(BossTank.GetAttackTarget()).GetDriver().IsPlayerDead())
			bShouldActivate = true;
		else if (Time::GameTimeSeconds < BossTank.TargetChangeTime)
			bShouldActivate = false;

		if(!bShouldActivate)
			return false;

		// If we have a target to change to, use that
		Params.TargetToChangeTo = BossTank.TargetToChangeTo;

		// If we don't, get it from the attack target
		if (Params.TargetToChangeTo == nullptr)
			Params.TargetToChangeTo = BossTank.GetBikeFromTarget(BossTank.GetAttackTarget()).GetDriver();

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (ActiveDuration > 2.0)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FSkylineBossTankChangeTargetActivateParams Params)
	{
		/*
		auto TargetBike = Cast<AGravityBikeFree>(BossTank.GetAttackTarget());

		if (TargetBike != nullptr)
			BossTank.SetTarget(TargetBike.GetDriver().OtherPlayer);
		*/
		BossTank.TargetToChangeTo = Params.TargetToChangeTo;

		BossTank.SetTarget(BossTank.TargetToChangeTo);

		// Set to change to the other player after some delay
		BossTank.SetTargetChange(BossTank.GetBikeFromTarget(BossTank.TargetToChangeTo).GetDriver().OtherPlayer, 12.0);

//		BossTank.BlockCapabilities(SkylineBossTankTags::SkylineBossTankAttack, this);
//		BossTank.BlockCapabilities(SkylineBossTankTags::SkylineBossTankChase, this);
	
//		BossTank.InstigatedSpeed.Apply(500.0, this, EInstigatePriority::High);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
//		BossTank.UnblockCapabilities(SkylineBossTankTags::SkylineBossTankAttack, this);
//		BossTank.UnblockCapabilities(SkylineBossTankTags::SkylineBossTankChase, this);

//		BossTank.InstigatedSpeed.Clear(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		PrintToScreen("Time: " + (BossTank.TargetChangeTime - Time::GameTimeSeconds), 0.0, FLinearColor::Green);
	}
}