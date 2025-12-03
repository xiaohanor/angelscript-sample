UCLASS(Abstract)
class UPlayerDamageEventHandler : UHazeEffectEventHandler
{
	UPROPERTY()
	AHazePlayerCharacter Player;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);	
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void TakeSmallDamage(){}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void TakeBigDamage(){}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void TakeDamageOverTime(){}


	// Simple cooldown handling, expand to a map if we need separate cooldowns later
	float Cooldown = 0.0;

	UFUNCTION()
	void ApplyCooldown(float Duration)
	{
		Cooldown = Math::Max(Cooldown, Time::GameTimeSeconds + Duration);
	}

	UFUNCTION(BlueprintCallable, meta = (ExpandBoolAsExecs = "ReturnValue"))
	bool IsPastCoolDown()
	{
		if (Time::GameTimeSeconds > Cooldown)
			return true;
		return false;
	}
};

// Some unreal functions require an object as an instigator. 
class UDummyPlayerDamageEventHandlerInstigator : UObject
{}