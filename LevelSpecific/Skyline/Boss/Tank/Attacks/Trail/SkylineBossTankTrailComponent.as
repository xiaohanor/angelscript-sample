class USkylineBossTankTrailComponent : USceneComponent
{
	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<ASkylineBossTankTrail> TrailClass;
	ASkylineBossTankTrail Trail;

	bool bActivated = false;

	float PointSpacing = 1000.0; // 2000.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}

	void ActivateTrail()
	{
		bActivated = true;
		
		if (TrailClass != nullptr)
		{
			Trail = SpawnActor(TrailClass);
			Trail.AddTrailSplinePoint(WorldLocation);
		}
	}

	void DeactivateTrail()
	{
		bActivated = false;

		if (IsValid(Trail))
			Trail.DestroyActor();
	}

	void AddExhaustBeamPoint()
	{
		if (!IsValid(Trail))
			return;

		if (WorldLocation.Distance(Trail.Points.Last()) < PointSpacing)
			return;

		Trail.AddTrailSplinePoint(WorldLocation);
	}
};