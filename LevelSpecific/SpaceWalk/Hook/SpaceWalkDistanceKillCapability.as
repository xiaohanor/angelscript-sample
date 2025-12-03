class USpaceWalkDistanceKillCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default TickGroup = EHazeTickGroup::Gameplay;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	USpaceWalkPlayerComponent SpaceComp;
	UPlayerTargetablesComponent PlayerTargetablesComponent;
	USpaceWalkOxygenPlayerComponent OxyComp;
	ASpaceWalkDebrisKillActor Debris;

	float TimeStartedChecking = 0.0;
	float TimeWithoutNearbyHook = 0.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SpaceComp = USpaceWalkPlayerComponent::Get(Player);
		PlayerTargetablesComponent = UPlayerTargetablesComponent::Get(Player);
		OxyComp = USpaceWalkOxygenPlayerComponent::Get(Player);
	}

	float GetDistanceFromClosestHookComponent() const
	{
		float ClosestDistance = BIG_NUMBER;

		TArray<UTargetableComponent> Targetables;
		PlayerTargetablesComponent.GetRegisteredTargetables(USpaceWalkHookPointComponent, Targetables);

		FVector PlayerLocation = Player.ActorLocation;
		for (UTargetableComponent Targetable : Targetables)
		{
			float Distance = Targetable.WorldLocation.Distance(PlayerLocation);
			if (Distance < ClosestDistance)
				ClosestDistance = Distance;
		}

		return ClosestDistance;
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (TimeStartedChecking == 0.0)
			TimeStartedChecking = Time::GameTimeSeconds;
		if (GetDistanceFromClosestHookComponent() > SpaceWalk::DistanceFromClosestHookPointToKillPlayer)
			TimeWithoutNearbyHook += DeltaTime;
		else
			TimeWithoutNearbyHook = 0.0;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Player.IsPlayerDead())
			return false;
		if (OxyComp.OxygenInteraction != nullptr)
			return false;
		if (OxyComp.bHasRunOutOfOxygen)
			return false;
		if (TimeWithoutNearbyHook < 0.5)
			return false;
		if (Time::GetGameTimeSince(TimeStartedChecking) < 4.0)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Player.IsPlayerDead())
			return true;
		if (!IsValid(Debris))
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		// Spawn the debris somewhere in a box around the player
		FVector DebrisSpawnPoint = Player.ActorLocation + (Math::GetRandomPointOnSphere() * SpaceWalk::DebrisSpawnDistanceFromPlayer);
		Debris = SpawnActor(SpaceComp.DebrisKillActorClass, DebrisSpawnPoint);
		Debris.Launch(Player);
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