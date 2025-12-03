class UIslandPunchotronSidescrollerLandingComponent : UActorComponent
{
	private float LastLandingTimestamp = 0;
	private const float LandingCooldown = 0.5;
	private TInstigated<bool> bIsBlocked;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		bIsBlocked.SetDefaultValue(false);
	}

	void BlockLandingEffect(FInstigator Instigator)
	{
		bIsBlocked.Apply(true, Instigator);
	}

	void UnblockLandingEffect(FInstigator Instigator)
	{
		bIsBlocked.Clear(Instigator);
	}

	bool CanTriggerLandingEffect()
	{
		if (bIsBlocked.Get())
			return false;

		return Time::GameTimeSeconds > LastLandingTimestamp + LandingCooldown;
	}

	void UpdateLandingTimestamp()
	{
		LastLandingTimestamp = Time::GameTimeSeconds;
	}
}