// Gives entry scenepoints to spawned actors from patterns of lower update order
UCLASS(meta = (ShortTooltip="Gives entry scenepoints to spawned actors."))
class UHazeActorSpawnPatternEntryScenepoint : UHazeActorSpawnPattern
{
	default UpdateOrder = ESpawnPatternUpdateOrder::Late;

	UPROPERTY(EditAnywhere, Category = "SpawnPattern")
	TArray<AScenepointActorBase> EntryScenepoints;

	private FScenepointContainer ScenepointsContainer;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		ScenepointsContainer.Scenepoints.Empty(EntryScenepoints.Num());
		for (AScenepointActorBase Scenepoint : EntryScenepoints)
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
		
		// Set scene points for any actors about to be spawned 
		for (auto& Entry : SpawnBatch.Batch)
		{
			for (FHazeActorSpawnParameters& Params : Entry.Value.SpawnParameters)
			{
				Params.Scenepoint = ScenepointsContainer.UseBestScenepoint();

				// Animation scenepoints should start at entry scenepoint 
				UScenepointAnimationComponent SpAnimComp = UScenepointAnimationComponent::Get(Params.Scenepoint.Owner);
				if ((SpAnimComp != nullptr) && (SpAnimComp.EntryAnimation != nullptr))
				{
					Params.Location = Params.Scenepoint.WorldLocation;
					Params.Rotation = Params.Scenepoint.WorldRotation;
				}

				// Use any spline from scenepoint, but do not set Params.Spline to null if there isn't any, since we may have set that earlier.
				UHazeSplineComponent SpSpline = UHazeSplineComponent::Get(Params.Scenepoint.Owner);
				if (SpSpline != nullptr) 
					Params.Spline = SpSpline;
			}
		}
	}
}
