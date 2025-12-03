class ASanctuaryWellRotatingDebris : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UFauxPhysicsAxisRotateComponent RotateComp;

	UPROPERTY(DefaultComponent, Attach = RotateComp)
	UFauxPhysicsForceComponent ForceComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}

	UFUNCTION()
	void Activate()
	{
		ForceComp.Force = FVector::UpVector * -1000.0;
	}
};