// Actors will spawn at one of these scenepoints
UCLASS(meta = (ShortTooltip="Actors will spawn at one of these scenepoints."))
class UHazeActorSpawnPatternSpawnAtScenepoint : UHazeActorSpawnPattern
{
	default UpdateOrder = ESpawnPatternUpdateOrder::Late;

	UPROPERTY(EditAnywhere, Category = "SpawnPattern")
	TArray<AScenepointActorBase> SpawnScenepoints;

	private FScenepointContainer ScenepointsContainer;

	// Will spawn at scenepoint in predetermined order if true. Will try to find a random point in any players' view if false.
	UPROPERTY(EditInstanceOnly, Category = "SpawnPattern")
	bool bSpawnInArrayOrder = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		ScenepointsContainer.Scenepoints.Empty(SpawnScenepoints.Num());
		for (AScenepointActorBase Scenepoint : SpawnScenepoints)
		{
			if (Scenepoint != nullptr)
				ScenepointsContainer.Scenepoints.Add(Scenepoint.GetScenepoint());
		}
		ScenepointsContainer.Reset();

		if (ScenepointsContainer.Scenepoints.Num() == 0)
			DeactivatePattern(this, EInstigatePriority::Override);
	}

	void UpdateControlSide(float DeltaTime, FHazeActorSpawnBatch& SpawnBatch) override
	{
		Super::UpdateControlSide(DeltaTime, SpawnBatch);
		
		// Spawn at scene points for any actors about to be spawned 
		for (auto& Entry : SpawnBatch.Batch)
		{
			for (FHazeActorSpawnParameters& Params : Entry.Value.SpawnParameters)
			{
				UScenepointComponent Scenepoint;
				if (!bSpawnInArrayOrder)
				 	Scenepoint = ScenepointsContainer.UseBestScenepoint();
				else
					Scenepoint = ScenepointsContainer.UseNextScenepoint();
				Params.Location = Scenepoint.WorldLocation;
				Params.Rotation = Scenepoint.WorldRotation;

				// Animation scenepoints should be used immediately
				UScenepointAnimationComponent SpAnimComp = UScenepointAnimationComponent::Get(Scenepoint.Owner);
				if ((SpAnimComp != nullptr) && (SpAnimComp.EntryAnimation != nullptr))
					Params.Scenepoint = Scenepoint;

				// Use any spline from scenepoint, but do not set Params.Spline to null if there isn't any, since we may have set that earlier.
				UHazeSplineComponent SpSpline = UHazeSplineComponent::Get(Scenepoint.Owner);
				if (SpSpline != nullptr) 
					Params.Spline = SpSpline;
			}
		}
	}
}
