class UIslandWalkerFlameThrowerComponent : UBasicAIProjectileLauncherComponent
{
	UPROPERTY(BlueprintReadOnly)
	FVector TargetLocation;	

	FVector SpreadDirectionOverride = FVector::ZeroVector;

	TArray<AActor> ActiveFireWalls;

	UFUNCTION(BlueprintPure)
	FVector GetSprayDirection() const property
	{
		return (TargetLocation - LaunchLocation).GetSafeNormal();
	}

	UFUNCTION(BlueprintPure)
	float GetSprayDistance() const property
	{
		return LaunchLocation.Distance(TargetLocation);
	}

	UFUNCTION(BlueprintPure)
	FVector GetSpreadDirection() const property
	{
		if (SpreadDirectionOverride.IsZero())
			return (TargetLocation - LaunchLocation).GetSafeNormal2D();
		return SpreadDirectionOverride;
	}

	bool IsImmuneDueToShenanigans(AHazePlayerCharacter Player, float MinShenanigansHeight)
	{
		// When high enough above arena we can avoid damage when in lots of special moves
		if (Player.ActorLocation.Z < MinShenanigansHeight)
			return false;
		if (Player.IsAnyCapabilityActive(PlayerSwingTags::SwingMovement))
			return true;
		if (Player.IsAnyCapabilityActive(PlayerSwingTags::SwingJump))
			return true;
		if (Player.IsAnyCapabilityActive(PlayerMovementTags::AirJump))
			return true;
		if (Player.IsAnyCapabilityActive(PlayerMovementTags::WallRun))
			return true;
		if (Player.IsAnyCapabilityActive(PlayerMovementTags::WallScramble))
			return true;
		if (Player.IsAnyCapabilityActive(PlayerGrappleTags::GrappleEnter))
			return true;
		return false;
	}

	UBasicAIProjectileComponent Launch(FVector Velocity, FRotator Rotation) override	
	{
		UBasicAIProjectileComponent ProjComp = Super::Launch(Velocity, Rotation);		

		// Keep track of firewalls that are currently being used
		if (!ActiveFireWalls.Contains(ProjComp.Owner))
		{
			ActiveFireWalls.Add(ProjComp.Owner);
			UHazeActorRespawnableComponent RespawnComp = UHazeActorRespawnableComponent::Get(ProjComp.Owner);
			RespawnComp.OnUnspawn.AddUFunction(this, n"OnUnspawnedFirewall");
		}
		return ProjComp;
	}

	UFUNCTION()
	private void OnUnspawnedFirewall(AHazeActor UnspawnedFirewall)
	{
		UHazeActorRespawnableComponent RespawnComp = UHazeActorRespawnableComponent::Get(UnspawnedFirewall);
		RespawnComp.OnUnspawn.Unbind(this, n"OnUnspawnedFirewall");
		ActiveFireWalls.RemoveSingleSwap(UnspawnedFirewall);
	}

	UFUNCTION(BlueprintPure, Meta = (NoSuperCall))
	void GetFireSpread(TArray<FVector>&out OutLocations, float Interval = 300.0)
	{
		for (AActor Actor : ActiveFireWalls)
		{
			auto Firewall = Cast<AIslandWalkerFirewall>(Actor);
			if (Firewall == nullptr)
				continue;
			Firewall.GetFireSpread(OutLocations, Interval);
		}	
	};
}

class UIslandWalkerFuelAndFlameThrowerComponent : UIslandWalkerFlameThrowerComponent
{
	UFUNCTION(BlueprintPure)
	void GetFuelSpread(TArray<FVector>&out OutLocations, float Interval = 300.0)
	{
		for (AActor Firewall : ActiveFireWalls)
		{
			auto FueledFirewall = Cast<AIslandWalkerFueledFirewall>(Firewall);
			if (FueledFirewall == nullptr)
				continue;
			FueledFirewall.GetFuelSpread(OutLocations, Interval);
		}	
	};

	void GetFireSpread(TArray<FVector>&out OutLocations, float Interval = 300.0) override
	{
		for (AActor Firewall : ActiveFireWalls)
		{
			auto FueledFirewall = Cast<AIslandWalkerFueledFirewall>(Firewall);
			if (FueledFirewall == nullptr)
				continue;
			FueledFirewall.GetFireSpread(OutLocations, Interval);
		}	
	};
}
