class UTundraBossDefeatedCapability : UTundraBossChildCapability
{
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(Boss.State == ETundraBossStates::Defeated)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Boss.State != ETundraBossStates::Defeated)
			return true;

		return false;
	}


	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Boss.MioIceChunk.DeactivateIceChunk();
		Boss.ZoeIceChunk.DeactivateIceChunk();
		Boss.FallingIciclesManager.StopDroppingIcicles();
		Boss.RedIceManager.StopRedIce();
		Boss.AddActorDisable(this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		
	}
};