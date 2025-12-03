class UTundraGnatClimbEntryBehaviour : UBasicBehaviour
{
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::ActivatesOnControlOnly;
	default Requirements.Add(EBasicBehaviourRequirement::Movement);

	UHazeActorRespawnableComponent RespawnComp;
	UTundraGnatComponent GnatComp;
	UTundraGnatHostComponent HostComp;
	UTundraGnatSettings Settings;
	UTundraGnatEntryScenepointComponent Scenepoint = nullptr;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		GnatComp = UTundraGnatComponent::Get(Owner);
		RespawnComp = UHazeActorRespawnableComponent::Get(Owner);
		RespawnComp.OnRespawn.AddUFunction(this, n"OnRespawn");	
		Settings = UTundraGnatSettings::GetSettings(Owner); 
	}

	UFUNCTION()
	private void OnRespawn()
	{
		GnatComp.bHasCompletedEntry = false;
		if (RespawnComp.Spawner == nullptr)
			return;
		AActor Host = RespawnComp.Spawner.AttachParentActor;
		if (Host == nullptr)
			return;
		HostComp = UTundraGnatHostComponent::Get(Host);
		if (!ensure(HostComp != nullptr))
			return;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if (GnatComp.bHasCompletedEntry)
			return false;
		if (HostComp == nullptr)
			return false;
		if (HostComp.Mesh == nullptr)
			return false;
		if (HostComp.EntryPoints.Num() == 0)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (GnatComp.bHasCompletedEntry)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		GnatComp.Host = HostComp.Owner;

		// Set to true once movement capability sets up spline and starts moving along it
		GnatComp.bHasStartedClimbing = false;

		bool bWave = RespawnComp.SpawnParameters.Spawner.IsA(UHazeActorSpawnPatternWave);

		if (bWave && (HostComp.WaveSpawnPoint != nullptr))
		{
			// All spawn from current wave shold use the same point
			Scenepoint = HostComp.WaveSpawnPoint;
			Scenepoint.Use(Owner);
			HostComp.WaveIndex++;
		}
		else
		{
			// Choose random point that hasn't been used for a while
			int iLast = -1;
			TArray<UTundraGnatEntryScenepointComponent>& EntryPoints = (Settings.ClimbEntryFrontOnly ? HostComp.FrontEntryPoints : HostComp.EntryPoints);
			for (UTundraGnatEntryScenepointComponent Point : EntryPoints)
			{
				if (Time::GetGameTimeSince(Point.LastUseTime) < Settings.ClimbEntryPointCooldown)
					break;
				iLast++;
			}
			int iRnd = Math::RandRange(0, Math::Max(0, iLast));
			Scenepoint = EntryPoints[iRnd];
			Scenepoint.Use(Owner);
		
			// Sort list on use age
			EntryPoints.RemoveAt(iRnd);
			EntryPoints.Add(Scenepoint);

			if (bWave)
				HostComp.WaveSpawnPoint = Scenepoint; // Subsequent wave spawn will use this point
			else
				HostComp.WaveSpawnPoint = nullptr; // Non-wave spawn, next wave will choose point normally
			HostComp.WaveIndex = 0;
		}

		// Always start at outside scenepoint, climbing towards attach bone.
		FVector StartWorldLoc = Scenepoint.WorldLocation;

		// Make sure we don't start too close to other gnats climbing along this leg
		for (AHazeActor Other : Scenepoint.GetUsers())
		{
			if (Other == Owner)
				continue;

			// Check if other gnat has claimed a climb location too near. 
			// Note that we cannot use actorlocation since that is not set until next tick when movement capability ticks.
			auto OtherGnatComp = UTundraGnatComponent::Get(Other);
			if (!OtherGnatComp.ClimbLoc.IsWithinDist(StartWorldLoc, Settings.ClimbEntryMinSpacing))
				continue; 
			
			// Found one other too close, move to below the lowest one
			FVector Down = -FVector::UpVector;
			float Lowest = Down.DotProduct(OtherGnatComp.ClimbLoc - StartWorldLoc);
			FVector LowestLoc = OtherGnatComp.ClimbLoc;
			for (AHazeActor Obstacle : Scenepoint.GetUsers())
			{
				if ((Obstacle == Other) || (Obstacle == Owner))
					continue;
				auto ObstacleGnatComp = UTundraGnatComponent::Get(Obstacle);
				float Lowth = Down.DotProduct(ObstacleGnatComp.ClimbLoc - StartWorldLoc); // This is not a word. I am unrepentant.
				if (Lowth < Lowest)
					continue;
				Lowest = Lowth;
				LowestLoc = ObstacleGnatComp.ClimbLoc;
			}
			StartWorldLoc = LowestLoc + Down * Math::RandRange(Settings.ClimbEntryMinSpacing, Settings.ClimbEntryMaxSpacing);
			break;
		}

		// Set climb location immediately so other climbers can avoid it. This is later updated in climb movement capability.
		GnatComp.ClimbLoc = StartWorldLoc;
		GnatComp.ClimbScenepoint = Scenepoint;
		
		// Climb bone will be set by movement capability
		GnatComp.ClimbBone = NAME_None;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		Scenepoint.Release(Owner);
		Scenepoint = nullptr;
		GnatComp.ClimbScenepoint = nullptr;
		GnatComp.ClimbBone = NAME_None;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Never count as done climbing until movement capability has started climb
		if (GnatComp.bHasStartedClimbing && (GnatComp.ClimbDistAlongSpline > GnatComp.ClimbSpline.Length - Settings.AtDestinationRange))
		{
			if (GnatComp.ClimbBone == n"Hips")
			{
				// We're done climbing!
				GnatComp.bHasCompletedEntry = true;
				return;
			}
		}
	}
}
