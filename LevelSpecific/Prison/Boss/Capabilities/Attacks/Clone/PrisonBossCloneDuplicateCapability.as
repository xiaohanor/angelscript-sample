class UPrisonBossCloneDuplicateCapability : UPrisonBossChildCapability
{
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::OnlyCrumbNetwork;

	bool bFullyCloned = false;

	ASplineActor TargetSpline;

	FVector TargetLocation;

	float CurrentCloneDuration = 0.0;

	int ClonesSpawned = 0;
	float DistancePerClone;

	UPrisonBossCloneManagerComponent CloneManagerComp;

	FSplinePosition SplinePos;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		
		CloneManagerComp = UPrisonBossCloneManagerComponent::GetOrCreate(Boss);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (bFullyCloned)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		ClonesSpawned = 0;
		CurrentCloneDuration = 0.0;
		bFullyCloned = false;

		Boss.AnimationData.bIsDuplicatingClone = true;
		TargetSpline = Boss.CircleSplineAirOuterLower;
		CloneManagerComp.Clones.Empty();

		DistancePerClone = TargetSpline.Spline.SplineLength/PrisonBoss::MaxCloneAmount;
		SplinePos = FSplinePosition(TargetSpline.Spline, TargetSpline.Spline.GetClosestSplineDistanceToWorldLocation(Boss.ActorLocation), true);

		UPrisonBossEffectEventHandler::Trigger_CloneStartSpawning(Boss);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Boss.AnimationData.bIsDuplicatingClone = false;

		UPrisonBossEffectEventHandler::Trigger_ClonesFullySpawned(Boss);

		// Fallback to spawn any clones that are missing (can happen in network with high ping)
		while (!bFullyCloned)
			SpawnClone();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (bFullyCloned)
			return;

		CurrentCloneDuration += DeltaTime;
		if (CurrentCloneDuration >= PrisonBoss::CloneSpawnInterval)
			SpawnClone();
	}

	void SpawnClone()
	{
		ClonesSpawned++;
		CurrentCloneDuration -= PrisonBoss::CloneSpawnInterval;

		SplinePos.Move(DistancePerClone);

		FVector Loc = SplinePos.WorldLocation;
		FVector DirToMid = (Boss.MiddlePoint.ActorLocation - Loc).GetSafeNormal();

		if (ClonesSpawned >= PrisonBoss::MaxCloneAmount - 1)
			bFullyCloned = true;
		
		CloneManagerComp.SpawnClone(Loc, DirToMid.Rotation(), bFullyCloned);

		UPrisonBossEffectEventHandler::Trigger_CloneSpawned(Boss);
	}
}