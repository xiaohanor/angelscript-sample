class AJetskiFloatingDebrisTrigger : AActorTrigger
{
	default ActorClasses.Add(AJetski);
	default BrushComponent.LineThickness = 45.0;
	default BrushComponent.bLinesInScreenSpace = false;
	default BrushComponent.RelativeScale3D = FVector(8.0, 15.0, 8.0);
	bool bDoOnce = false;

	UPROPERTY(EditAnywhere)
	TArray<AJetskiFloatingDebris> DebrisToTrigger;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		OnActorEnter.AddUFunction(this, n"HandleJetskiEnter");
	}

	UFUNCTION()
	private void HandleJetskiEnter(AHazeActor Actor)
	{
		if (bDoOnce)
			return;

		bDoOnce = true;

		for (auto Debris : DebrisToTrigger)
			Debris.StartFalling();
	}
};