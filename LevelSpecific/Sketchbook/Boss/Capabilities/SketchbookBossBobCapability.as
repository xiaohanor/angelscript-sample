class USketchbookBossBobCapability : USketchbookBossChildCapability
{
	const float BobFrequency = 0.5;
	const float Roll = 10;
	int RollMultiplier = 1;
	float LastBobTime;

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		LastBobTime = Time::GameTimeSeconds;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(Time::GetGameTimeSince(LastBobTime) > BobFrequency)
		{
			LastBobTime = Time::GameTimeSeconds;
			RollMultiplier *= -1;
			FRotator NewRotation = FRotator(0, 0, Roll * RollMultiplier);
			Boss.BobSceneComponent.SetRelativeRotation(NewRotation);
		}
	}
};