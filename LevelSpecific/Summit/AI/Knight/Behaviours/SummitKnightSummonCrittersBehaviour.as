class USummitKnightSummonCrittersBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);

	USummitKnightSettings Settings;
	USummitKnightAnimationComponent KnightAnimComp;
	USummitKnightComponent KnightComp;
	USummitKnightCritterSummoningLaunchComponent LaunchComp;
	UHazeSkeletalMeshComponentBase Mesh;
	TArray<AScenepointActorBase> EntryScenepoints;
	bool bSummonAtPlacedLocations = true;
	TArray<FVector> SummonLocations;

	FBasicAIAnimationActionDurations Durations;
	bool bLaunchedSummonBlobs;
	bool bSummoned;
	bool bDoneSummoning;
	int NumSpawnedCritters;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Settings = USummitKnightSettings::GetSettings(Owner);
		LaunchComp = USummitKnightCritterSummoningLaunchComponent::Get(Owner);
		KnightAnimComp = USummitKnightAnimationComponent::GetOrCreate(Owner);
		KnightComp = USummitKnightComponent::Get(Owner);
		if(KnightComp.CritterSpawner != nullptr)
		{
			KnightComp.CritterSpawner.SpawnerComp.OnPostSpawn.AddUFunction(this, n"OnSpawnedCritter");
		}

		Mesh = Cast<AHazeCharacter>(Owner).Mesh;	

		if (KnightComp.CritterSpawner != nullptr)
		{
			EntryScenepoints = UHazeActorSpawnPatternEntryScenepoint::Get(KnightComp.CritterSpawner).EntryScenepoints;	
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();

		// We launch the summoning blobs or whatever effect will be used at start of action interval 
		// and start spawning critters at end of action interval
		Durations.Telegraph = Settings.SummonCrittersTelegraphDuration;
		Durations.Anticipation = Settings.SummonCrittersAnticipationDuration;
		Durations.Action = Settings.SummonCrittersActionDuration;
		Durations.Recovery = Settings.SummonCrittersRecoverDuration;
		KnightAnimComp.FinalizeDurations(SummitKnightFeatureTags::SummonCritters, NAME_None, Durations);
		AnimComp.RequestAction(SummitKnightFeatureTags::SummonCritters, NAME_None, EBasicBehaviourPriority::Medium, this, Durations);

		bLaunchedSummonBlobs = false;
		bSummoned = false;
		bDoneSummoning = false;
		NumSpawnedCritters = 0;
		SummonLocations.Reset(Settings.SummonCrittersNumber);

		UHazeActorSpawnPatternInterval IntervalPattern = UHazeActorSpawnPatternInterval::Get(KnightComp.CritterSpawner);
		if (IntervalPattern != nullptr)
		{
			IntervalPattern.MaxActiveSpawnedActors = Settings.SummonCrittersNumber;
			IntervalPattern.Interval = (Durations.Recovery - 0.5) / Math::Max(1.0, float(Settings.SummonCrittersNumber - 1));
			IntervalPattern.RespawnDelay = Durations.Action + Durations.Recovery;
		}
		UHazeActorSpawnPatternWave WavePattern = UHazeActorSpawnPatternWave::Get(KnightComp.CritterSpawner);
		if (WavePattern != nullptr)
		{
			WavePattern.WaveSize = Settings.SummonCrittersNumber;
			WavePattern.RespawnDuration = Durations.Action + Durations.Recovery;
		}

		USummitKnightEventHandler::Trigger_OnTelegraphSummonCritters(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (ActiveDuration > Durations.GetTotal())	
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		if (!bDoneSummoning)
			KnightComp.DeactivateSpawners();
		bDoneSummoning = true;
		USummitKnightEventHandler::Trigger_OnStopSummoningCritters(Owner);

		// Next summon should be dynamically placed
		bSummonAtPlacedLocations = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		DestinationComp.RotateTowards(KnightComp.Arena.Center);

		if (HasControl() && !bLaunchedSummonBlobs && Durations.IsInActionRange(ActiveDuration))
			CrumbLaunchSummonBlobs(GetSummonLocations());

		if (!bSummoned && Durations.IsInRecoveryRange(ActiveDuration))
		{
			bSummoned = true;
			bDoneSummoning = false;
			KnightComp.CritterSpawner.ActivateSpawner();
			USummitKnightEventHandler::Trigger_OnStartSummoningCritters(Owner);
		}	
	}
	
	TArray<FVector> GetSummonLocations()
	{
		TArray<FVector> Locs;
		Locs.SetNum(Settings.SummonCrittersNumber);
		if (bSummonAtPlacedLocations)
		{
			// Critters will be summoned where the scenepoints are placed
			for (int i = 0; i < Settings.SummonCrittersNumber; i++)
			{
				Locs[i] = EntryScenepoints[i % EntryScenepoints.Num()].ActorLocation;	
			}
			return Locs;
		}

		FVector BaseLoc = KnightComp.Arena.GetClampedToArena((Owner.ActorLocation + Game::Zoe.ActorLocation) * 0.5, 800.0);
		FVector Side = (KnightComp.Arena.Center - BaseLoc).CrossProduct(FVector::UpVector).GetSafeNormal2D();
		FVector Loc = BaseLoc - Side * ((Settings.SummonCrittersNumber - 1.0) * 0.5 * Settings.SummonCrittersSpacing + Math::RandRange(-0.5, 0.5) * Settings.SummonCrittersSpacing);
		float InsideDistance = KnightComp.Arena.Radius - BaseLoc.Dist2D(KnightComp.Arena.Center);
		for (int i = 0; i < Settings.SummonCrittersNumber; i++)
		{
			Locs[i] = KnightComp.Arena.GetClampedToArena(Loc, InsideDistance); 
			Loc += Side * Settings.SummonCrittersSpacing * Math::RandRange(0.8, 1.2);
		}
		Locs.Shuffle();
		return Locs; 
	}

	UFUNCTION(CrumbFunction)
	void CrumbLaunchSummonBlobs(TArray<FVector> SummonLocs)
	{
		bLaunchedSummonBlobs = true;
		SummonLocations = SummonLocs;

		// Place all scenepoints at first loc, then move them for each spawned critter
		// to ensure they use those locations in that order
		PlaceScenepoints(0);

		float FirstSpawnDelay = (Durations.PreRecoveryDuration - ActiveDuration);
		float SpawnInterval = UHazeActorSpawnPatternInterval::Get(KnightComp.CritterSpawner).Interval;			
		LaunchComp.SpawnBlobs(SummonLocs.Num(), Owner);
		for (int i = 0; i < SummonLocs.Num(); i++)
		{
			LaunchComp.Blobs[i].Launch(LaunchComp.WorldLocation, SummonLocs[i], FirstSpawnDelay + SpawnInterval * i);
		}

		FSummitKnightLaunchCritterBlobsParams Params;
		Params.LaunchComp = LaunchComp;
		Params.Projectiles = LaunchComp.Blobs;
		if (Params.Projectiles.Num() > SummonLocs.Num())
			Params.Projectiles.SetNum(SummonLocs.Num());
		USummitKnightEventHandler::Trigger_OnSummonCrittersBlobsLaunched(Owner, Params);	
	}

	UFUNCTION()
	private void OnSpawnedCritter(AHazeActor SpawnedActor, UHazeActorSpawnerComponent Spawner, UHazeActorSpawnPattern SpawningPattern)
	{
		NumSpawnedCritters++;

		FVector EmergeLoc = KnightComp.GetArenaLocation(SpawnedActor.ActorLocation);
		USummitKnightEventHandler::Trigger_OnSummonedCritterEmerge(Owner, FSummitKnightCritterEmergeParams(EmergeLoc, Cast<AAISummitKnightCritter>(SpawnedActor)));

		if (!bDoneSummoning && (NumSpawnedCritters == Settings.SummonCrittersNumber))
		{
			KnightComp.DeactivateSpawners();
			bDoneSummoning = true;
		}

		// Move all scenepoints to next position
		PlaceScenepoints(NumSpawnedCritters);
	}

	void PlaceScenepoints(int Index)
	{
		if (bSummonAtPlacedLocations)
			return;
		if (!SummonLocations.IsValidIndex(Index))
			return;
		for (AScenepointActorBase Scenepoint : EntryScenepoints)
		{
			FVector Loc = SummonLocations[Index];
			FRotator Rot = FRotator::MakeFromZX(FVector::UpVector, Game::Zoe.ActorLocation - Loc);
			Scenepoint.SetActorLocationAndRotation(Loc, Rot, true);
		}
	}
}

class USummitKnightCritterSummoningBlob : USceneComponent
{
	FVector Start;
	FVector StartControl;
	FVector DestControl;
	FVector Destination;
	float Alpha;
	float AlphaPerSecond;
	bool bHasReachedEnd;

	default PrimaryComponentTick.bStartWithTickEnabled = false;

	void Launch(FVector LaunchLoc, FVector Dest, float Duration)
	{
		bHasReachedEnd = false;
		Start = LaunchLoc;
		Destination = Dest;
		FVector ToDest = (Dest - LaunchLoc).GetSafeNormal2D();
		float Dist = (Dest - LaunchLoc).Size2D();
		StartControl = Start + ToDest * Dist * 0.4 + Math::GetRandomPointInSphere() * Dist * 0.3 + FVector(0.0, 0.0, Math::RandRange(0.15, 0.3) * Dist);
		DestControl = Destination - ToDest * Dist * 0.2 + Math::GetRandomPointInSphere() * Dist * 0.2 + FVector(0.0, 0.0, Math::RandRange(0.3, 0.5) * Dist);
		Alpha = 0.0;
		AlphaPerSecond = Math::Max(1.0 / Math::Max(Duration, 0.01), 0.1);
		
		WorldLocation = LaunchLoc;
		WorldRotation = FRotator::MakeFromXZ(BezierCurve::GetDirection_2CP(Start, StartControl, DestControl, Destination, 0.0), UpVector);

		SetComponentTickEnabled(true);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		Alpha = Math::Min(1.0, Alpha + AlphaPerSecond * DeltaTime);
		WorldLocation = BezierCurve::GetLocation_2CP(Start, StartControl, DestControl, Destination, Alpha);
		WorldRotation = FRotator::MakeFromXZ(BezierCurve::GetDirection_2CP(Start, StartControl, DestControl, Destination, 0.0), UpVector);

		if (!bHasReachedEnd && (Alpha > 0.999))
		{
			bHasReachedEnd = true;
			USummitKnightEventHandler::Trigger_OnSummonedCritterBlobImpact(Cast<AHazeActor>(Owner), FSummitKnightLaunchCritterBlobParams(this));			
		}

		if (bHasReachedEnd)
			SetComponentTickEnabled(false);

#if EDITOR
		if (Owner.bHazeEditorOnlyDebugBool)
		{
			Debug::DrawDebugSphere(WorldLocation, 50.0, 12, FLinearColor::Red, 5.0);
			Debug::DrawDebugArrow(WorldLocation, WorldLocation + WorldRotation.ForwardVector * 500.0, 100.0, FLinearColor::Red, 10);
			BezierCurve::DebugDraw_2CP(Start, StartControl, DestControl, Destination, FLinearColor::Yellow, 3.0);		
		}
#endif
	}
}

class USummitKnightCritterSummoningLaunchComponent : USceneComponent
{
	TArray<USummitKnightCritterSummoningBlob> Blobs;

	void SpawnBlobs(int NumBlobs, AHazeActor Launcher)
	{
		// Spawn local blobs, they're only used for effects
		for (int i = Blobs.Num(); i < NumBlobs; i++)
		{
			auto Blob = USummitKnightCritterSummoningBlob::Create(Launcher, FName("CritterBlob_" + i));
			Blobs.Add(Blob);
			Blob.DetachFromParent(true);
		}
	}
}
