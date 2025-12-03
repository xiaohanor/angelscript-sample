class UBigCrackBirdRunAwayCapability : UBigCrackBirdBaseCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	FHazeRuntimeSpline NavigationSpline;
	float DistanceAlongSpline = 0;
	float MoveSpeed = 600;

	ABigCrackBirdNest TargetNest;

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Bird.bRunningAway)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(DistanceAlongSpline == NavigationSpline.Length)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		for(auto Nest : TListedActors<ABigCrackBirdNest>().Array)
		{
			if(Nest.Bird != nullptr)
				continue;

			if(Nest.AttachParentActor != nullptr)
				continue;

			TargetNest = Nest;
		}

		check(TargetNest != nullptr);

		const UNavigationPath Path;

		Path = UNavigationSystemV1::FindPathToLocationSynchronously(Bird.ActorLocation, TargetNest.ActorLocation);
		DistanceAlongSpline = 0;
		Bird.bRunningAway = true;

		if(Path.IsValid())
		{
			NavigationSpline.SetPoints(Path.PathPoints);
			NavigationSpline.InsertPoint(Bird.ActorLocation, 0);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Bird.bRunningAway = false;
		Bird.InteractComp.Enable(Bird);
		Bird.AttachToActor(TargetNest, AttachmentRule = EAttachmentRule::KeepWorld);
		Bird.bAttached = true;
		Bird.CurrentNest = TargetNest;
		TargetNest.Bird = Bird;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(NavigationSpline.Points.IsEmpty())
			return;
		
		DistanceAlongSpline += DeltaTime * 900;
		DistanceAlongSpline = Math::Clamp(DistanceAlongSpline, 0, NavigationSpline.Length);
		FVector Location = NavigationSpline.GetLocationAtDistance(DistanceAlongSpline);
		Bird.SetActorLocation(Location);
		Bird.SetActorRotation(Math::RInterpConstantTo(Bird.ActorRotation, NavigationSpline.GetRotationAtDistance(DistanceAlongSpline), DeltaTime, 100));
	}
};