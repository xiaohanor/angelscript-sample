class USummitClimbingCritterSpawnGravityCapability : UHazeCapability
{
	default TickGroup = EHazeTickGroup::BeforeMovement;

	UWallclimbingComponent WallclimbingComp;
	UHazeActorRespawnableComponent RespawnComp;
	bool bHasSetGravity = false;
	FVector DefaultGravity;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		WallclimbingComp = UWallclimbingComponent::GetOrCreate(Owner);
		DefaultGravity = WallclimbingComp.PreferredGravity;
		RespawnComp = UHazeActorRespawnableComponent::Get(Owner);
		if (RespawnComp != nullptr)
			RespawnComp.OnRespawn.AddUFunction(this, n"OnReset");
	}

	UFUNCTION()
	private void OnReset()
	{
		WallclimbingComp.PreferredGravity = DefaultGravity;
		bHasSetGravity = false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (bHasSetGravity)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (ActiveDuration > 0.1)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		// Set gravity with high prio and block behaviour for a short while so that spawning critter will orient itself
		bHasSetGravity = true;
		FVector Gravity;

		// Find nearby climbable wall to latch onto
		if (RespawnComp != nullptr)
		{
			// Get climbable wall from spawner
			UClimbableWallTrackerComponent WallTrackerComp = UClimbableWallTrackerComponent::GetOrCreate(RespawnComp.Spawner);
			UHazeActorSpawnPattern SpawnPattern = Cast<UHazeActorSpawnPattern>(RespawnComp.SpawnParameters.Spawner);
			Gravity = -WallTrackerComp.FindWallNormal(SpawnPattern, UTeenDragonTailClimbableComponent, 400.0);
		}
		else
		{
			// No spawner to cache wall normal on
			Gravity = -WallTracker::GetNearestWallNormal(Owner.ActorLocation, 400, UTeenDragonTailClimbableComponent);
		}

		// Set preferred gravity or fall back to set value if we couldn't find a wall
		if (Gravity.IsNearlyZero())
			Gravity = WallclimbingComp.PreferredGravity.IsNearlyZero() ? -FVector::UpVector : WallclimbingComp.PreferredGravity.GetSafeNormal();
		else	
			WallclimbingComp.PreferredGravity = Gravity; 

		Owner.OverrideGravityDirection(Gravity, this, EInstigatePriority::High);
		Owner.BlockCapabilitiesExcluding(BasicAITags::Behaviour, n"CrowdRepulsion", this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Owner.ClearGravityDirectionOverride(this);
		Owner.UnblockCapabilities(BasicAITags::Behaviour, this);
	}
}
