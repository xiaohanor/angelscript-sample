// Gives entry spline to spawned actors from patterns of lower update order
UCLASS(meta = (ShortTooltip="Gives entry spline to spawned actors."))
class UHazeActorSpawnPatternEntrySpline : UHazeActorSpawnPattern
{
	default UpdateOrder = ESpawnPatternUpdateOrder::Late;

	UPROPERTY(EditAnywhere, Category = "SpawnPattern")
	AHazeActor SplineOwner;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		if (SplineOwner == nullptr || !devEnsure(UHazeSplineComponent::Get(SplineOwner) != nullptr, "Entry spline spawn pattern on " + Owner.Name + " has a spline owner " + SplineOwner.Name + " without spline component!"))
			DeactivatePattern(this, EInstigatePriority::Override);
	}

	void UpdateControlSide(float DeltaTime, FHazeActorSpawnBatch& SpawnBatch) override
	{
		Super::UpdateControlSide(DeltaTime, SpawnBatch);
		
		// Set spline for any actors about to be spawned 
		for (auto& Entry : SpawnBatch.Batch)
		{
			for (FHazeActorSpawnParameters& Params : Entry.Value.SpawnParameters)
			{
				Params.Spline = Spline::GetGameplaySpline(SplineOwner, this);
			}
		}
	}
}
