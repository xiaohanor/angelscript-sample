class ASolarFlareLeverDownObject : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MoveRoot;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = MoveRoot)
	UBillboardComponent Visual;
	default Visual.SetWorldScale3D(FVector(10.0));
#endif

	UPROPERTY(EditAnywhere)
	ASolarFlareStickInteraction StickInteraction;

	float DownAmount;
	float UpAmount = 400.0;
	float DownSpeed = 500.0;
	float ZTarget;
	FHazeAcceleratedFloat AccelZ;

	UPROPERTY(EditAnywhere)
	float MaxDownMoveAmount = 1000.0;
	
	FVector StartLoc;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StickInteraction.OnSolarFlareMovementStickApplied.AddUFunction(this, n"OnSolarFlareMovementStickApplied");
		StartLoc = MoveRoot.RelativeLocation;
	}

	UFUNCTION()
	private void OnSolarFlareMovementStickApplied(FVector2D Input)
	{
		DownAmount = Math::Clamp(Input.Y, -1.0, 0.0);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (DownAmount < 0.0)
			ZTarget += DownAmount * DeltaSeconds * DownSpeed;
		else 
			ZTarget += UpAmount * DeltaSeconds;

		ZTarget = Math::Clamp(ZTarget, -MaxDownMoveAmount, 0.0);

		AccelZ.AccelerateTo(ZTarget, 0.5, DeltaSeconds);

		MoveRoot.RelativeLocation = StartLoc + FVector(0.0, 0.0, AccelZ.Value);

		PrintToScreen("ZTarget: " + ZTarget);
		PrintToScreen("DownAmount: " + DownAmount);
		DownAmount = 0.0;
	}
}