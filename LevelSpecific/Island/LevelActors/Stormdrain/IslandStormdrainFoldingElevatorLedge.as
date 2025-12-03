class AIslandStormdrainFoldingElevatorLedge : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = "Root")
	USceneComponent MovingRoot;

	UPROPERTY(DefaultComponent, Attach = "Root")
	UStaticMeshComponent Mesh1;

	UPROPERTY(DefaultComponent, Attach = "Mesh1")
	UStaticMeshComponent Mesh2;

	default PrimaryActorTick.bStartWithTickEnabled = false;
	float Offset = 0;
	float TargetOffset = -530;
	float InterpSpeed = 1.2;
	UPROPERTY(EditInstanceOnly)
	float DelayBeforeMovement = 0;
	FVector StartLocation;

	UFUNCTION()
	void TriggerFold()
	{
		SetActorTickEnabled(true);
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartLocation = MovingRoot.GetRelativeLocation();
		Mesh1.AttachToComponent(MovingRoot, NAME_None, EAttachmentRule::KeepWorld);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(DelayBeforeMovement > 0)
		{
			DelayBeforeMovement -= DeltaSeconds;
		}

		else
		{
			Offset = Math::FInterpTo(Offset, TargetOffset, DeltaSeconds, InterpSpeed);
			if(Math::IsNearlyEqual(Offset, TargetOffset, SMALL_NUMBER))
			{
				Offset = TargetOffset;
				SetActorTickEnabled(false);
			}
			//MovingRoot.SetRelativeRotation(FRotator(Angle, 0, 0));
			MovingRoot.SetRelativeLocation(StartLocation + FVector(Offset, 0, 0));
		}
	}
}