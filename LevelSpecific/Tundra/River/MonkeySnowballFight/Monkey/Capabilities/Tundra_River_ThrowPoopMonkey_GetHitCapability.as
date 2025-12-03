class UTundra_River_ThrowPoopMonkey_GetHitCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Local;
	ATundra_River_ThrowPoopMonkey Monkey;

	float DespawnTimer;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Monkey = Cast<ATundra_River_ThrowPoopMonkey>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Monkey.State != ETundraPoopMonkeyState::Hit)
			return false;

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
		Monkey.MeshComp.SetAnimTrigger(n"Hit");
		DespawnTimer = 1.65;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		DespawnTimer -= DeltaTime;
		if (DespawnTimer <= 0)
			Owner.DestroyActor();
	}
};