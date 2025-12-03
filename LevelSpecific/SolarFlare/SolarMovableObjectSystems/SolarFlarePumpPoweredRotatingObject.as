class ASolarFlarePumpPoweredRotatingObject : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent)
	USolarFlareEffectComponent EffectComp;

	UPROPERTY(EditAnywhere)
	float RotationSpeed = 5.0;

	FRotator CurrentRot;
	FQuat TargetQuat;
	FHazeAcceleratedQuat AccelQuat;

	float RotationMultiplier;

	UPROPERTY(EditAnywhere)
	ASolarFlareStickInteraction StickInteraction;

	bool bStickInputting;

	FVector2D PlayerInput;

	float Angle;


	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StickInteraction.OnSolarFlareMovementStickApplied.AddUFunction(this, n"OnSolarFlareMovementStickApplied");
	}

	UFUNCTION()
	private void OnSolarFlareMovementStickApplied(FVector2D Input)
	{
		PlayerInput = Input;

		if (Input.X != 0.0)
			bStickInputting = true;
	}


	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		Angle += PlayerInput.X * 25.0 * DeltaSeconds;
		Angle = Math::Wrap(Angle, -180.0, 180.0);
		MeshRoot.SetRelativeRotation(FRotator(0.0, 0.0, Angle));
		
		bStickInputting = false;
		PlayerInput = FVector2D(0.0, 0.0);
	}
}