class UDiscSlideHydraGrindComponent : UBoxComponent
{
	UPROPERTY(EditInstanceOnly)
	float HopOffDistance = -1.0;

	UPROPERTY(EditInstanceOnly)
	bool bGrindingEnabled = true;

	UPROPERTY(EditInstanceOnly)
	float GrindSpeed = 4000.0;

	bool bTriggered = false;
	ADiscSlideHydra Hydra;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Hydra = Cast<ADiscSlideHydra>(Owner);
		if (bGrindingEnabled)
			OnComponentBeginOverlap.AddUFunction(this, n"TriggerBeginOverlap");
	}

	UFUNCTION()
	void TriggerBeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep, const FHitResult&in SweepResult)
	{
		if (bTriggered)
			return;

		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;
		TListedActors<ASlidingDisc> Discs;
		if (Discs.Num() == 0)
			return;
		ASlidingDisc Disc = Discs.Single;
		if (Disc.GrindingOnHydra != nullptr)
			return;
		Disc.GrindingOnHydra = Hydra;
		if (Hydra.SurfaceActor != nullptr)
			Hydra.SurfaceActor.bPlayersAreGrinding = true;
		Disc.GrindHopOffDistance = HopOffDistance;
		bTriggered = true;
	}
}