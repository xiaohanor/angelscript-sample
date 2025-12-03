class AMeltdownSplitSlideTank : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent SawBladeRoot;

	UPROPERTY(EditAnywhere)
	float Speed = 500.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorTickEnabled(false);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		AddActorLocalOffset(FVector::ForwardVector * Speed * DeltaSeconds);
		SawBladeRoot.AddRelativeRotation(FRotator(0.0, 0.0, 360.0 * DeltaSeconds));
	}

	UFUNCTION()
	void Activate()
	{
		SetActorTickEnabled(true);
	}
};