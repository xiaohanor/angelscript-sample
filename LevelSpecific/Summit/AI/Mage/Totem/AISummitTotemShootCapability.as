class UAISummitTotemShootCapability : UHazeCapability
{
	default CapabilityTags.Add(n"AISummitTotemShootCapability");
	
	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 100;

	float AttackTime;
	float AttackInterval = 1.5;
	float RecoveryTime;
	float RecoveryInterval = 1.5;

	AAISummitTotem Totem;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Totem = Cast<AAISummitTotem>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Time::GameTimeSeconds < RecoveryTime)
			return false;
		
		if (Totem.Target == nullptr)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Time::GameTimeSeconds > AttackTime)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		AttackTime = Time::GameTimeSeconds + AttackInterval;
		Totem.BP_TotemWindBack();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Totem.SpawnMageSpiritBall();
		RecoveryTime = Time::GameTimeSeconds + RecoveryInterval;
	}
}