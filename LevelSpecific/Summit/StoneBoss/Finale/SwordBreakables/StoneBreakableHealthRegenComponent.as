class UStoneBreakableHealthRegenComponent : UActorComponent
{
	UPROPERTY()
	float RegenRatePerSecond = 0.5;

	//How long the regen should be disabled when hit by both players within time frame
	float RegenDisableDuration = 1.0;

	private bool bIsRegenBlocked = false;

	bool IsRegenEnabled() const
	{
		return !bIsRegenBlocked;
	}
	void DisableRegen()
	{
		bIsRegenBlocked = true;
	}

	void EnableRegen()
	{
		bIsRegenBlocked = false;
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		
	}
};