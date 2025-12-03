class UIslandPunchotronCooldownComponent : UActorComponent
{
	TMap<UClass, float> BehaviourCooldownMap;

	void SetCooldown(TSubclassOf<UObject> CooldownClass, float Duration)
	{
		BehaviourCooldownMap.Add(CooldownClass.Get(), Duration);		
	}

	bool IsCooldownOver(TSubclassOf<UObject> CooldownClass)
	{
		float CooldownDuration = 0.0;
		if (!BehaviourCooldownMap.Find(CooldownClass.Get(), CooldownDuration))
			return true; // no entry found
		if (CooldownDuration <= 0)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		for (auto& Cooldown : BehaviourCooldownMap)
		{
			Cooldown.Value = Cooldown.Value - DeltaSeconds;
		}
	}
};