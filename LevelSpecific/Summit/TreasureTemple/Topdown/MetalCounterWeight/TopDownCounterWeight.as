class ATopDownCounterWeight : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UFauxPhysicsTranslateComponent Translate;

	UPROPERTY(DefaultComponent, Attach = Translate)
	UFauxPhysicsForceComponent Force;

	UPROPERTY(DefaultComponent, Attach = Translate)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = Translate)
	UFauxPhysicsWeightComponent Weight;

	UPROPERTY(EditAnywhere)
	ANightQueenMetal Metal;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Metal.OnNightQueenMetalMelted.AddUFunction(this, n"OnNightQueenMetalMelted");
		Metal.OnNightQueenMetalRecovered.AddUFunction(this, n"OnNightQueenMetalRecovered");
	}

	UFUNCTION()
	private void OnNightQueenMetalMelted()
	{
		Force.Force = FVector(1000.0, 0.0, 0.0);
		Weight.MassScale = 0.0;
	}

	UFUNCTION()
	private void OnNightQueenMetalRecovered()
	{
		Force.Force = FVector(0.0, 0.0, 0.0);
		Weight.MassScale = 1.0;
	}
}