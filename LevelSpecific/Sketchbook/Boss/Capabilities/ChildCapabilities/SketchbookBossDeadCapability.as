class USketchbookBossDeadCapability : USketchbookBossChildCapability
{
	bool bActivatedOnce = false;

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Boss.bIsKilled)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(ActiveDuration >= Boss.DeathTime)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if(!bActivatedOnce)
		{
			bActivatedOnce = true;
			SketchbookBoss::GetSketchbookBossFightManager().RemoveBoss();
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
	}
};