class USummitCritterSwarmSpawnBehaviour : UBasicBehaviour
{
	// Movement only (which is replicated separately)
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::ActivatesOnControlOnly;
	
	default Requirements.Add(EBasicBehaviourRequirement::Movement);
	default Requirements.AddBlock(EBasicBehaviourRequirement::Weapon);

	UHazeActorRespawnableComponent RespawnComp;
	USummitCritterSwarmComponent SwarmComp;
	USummitCritterSwarmSettings SwarmSettings;
	float ChangeDestinationTime;
	FVector Destination;
	bool bDoneSpawning = false;
	int NumSpawnedCritters = 0;
	float SpawnTime;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		SwarmSettings = USummitCritterSwarmSettings::GetSettings(Owner);

		SwarmComp = USummitCritterSwarmComponent::Get(Owner);
		RespawnComp = UHazeActorRespawnableComponent::Get(Owner);
		RespawnComp.OnRespawn.AddUFunction(this, n"OnRespawn");
		OnRespawn();
	}

	UFUNCTION()
	private void OnRespawn()
	{
		bDoneSpawning = false;
		SwarmComp.InitialLocation = RespawnComp.SpawnParameters.Location + RespawnComp.SpawnParameters.Rotation.Vector() * SwarmSettings.SpawningMoveDistance;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if (bDoneSpawning)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (NumSpawnedCritters >= SwarmSettings.NumCritters) 
			return true;
		if (SwarmComp.UnspawnedCritters.Num() == 0)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		ChangeDestinationTime = 0.0;

		// Unspawn all critters
		NumSpawnedCritters = 0;
		SpawnTime = Time::GameTimeSeconds;
		for (USummitSwarmingCritterComponent Mesh : SwarmComp.Critters)
		{
			Mesh.AddComponentVisualsBlocker(this);
			SwarmComp.UnspawnedCritters.Add(Mesh);
		}
		SwarmComp.Critters.Empty(SwarmComp.UnspawnedCritters.Num());
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		bDoneSpawning = true;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (Time::GameTimeSeconds > SpawnTime)
		{
			// Spawn a critter. These will then flock to actor location in a nice gout
			SpawnTime += SwarmSettings.SpawningDuration / float(SwarmSettings.NumCritters);
			USummitSwarmingCritterComponent Critter = SwarmComp.UnspawnedCritters[0];
			Critter.RemoveComponentVisualsBlocker(this);
			SwarmComp.Critters.Add(Critter);
			SwarmComp.UnspawnedCritters.RemoveAtSwap(0);
			NumSpawnedCritters++;
		}

		// Fly to spawn location, then stay in place when there to allow critters to catch up.
		if (!Owner.ActorLocation.IsWithinDist(SwarmComp.InitialLocation, 1000.0))
			DestinationComp.MoveTowards(SwarmComp.InitialLocation, SwarmSettings.SpawningSpeed);	

#if EDITOR
	 	// Owner.bHazeEditorOnlyDebugBool = true;
		if (Owner.bHazeEditorOnlyDebugBool)
		{
			Debug::DrawDebugSphere(Game::Zoe.ActorCenterLocation + FVector(0,0,400), 100, 4, FLinearColor::Blue, 10);
			Debug::DrawDebugLine(Owner.ActorLocation, SwarmComp.InitialLocation, FLinearColor::Gray, 10);
			//Debug::DrawDebugSphere(Owner.ActorLocation, Cast<AHazeCharacter>(Owner).CapsuleComponent.CapsuleRadius, 12, FLinearColor::Blue, 100);
			for (auto Critter : SwarmComp.Critters)
			{
				Debug::DrawDebugLine(Critter.WorldLocation, Owner.ActorLocation, FLinearColor::Blue, 10);
			}
		}
#endif
	}
}
