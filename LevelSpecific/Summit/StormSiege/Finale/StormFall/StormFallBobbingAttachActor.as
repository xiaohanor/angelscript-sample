class AStormFallBobbingAttachActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = Root)
	UEditorBillboardComponent BillboardComp;
	default BillboardComp.SetWorldScale3D(FVector(20.0));
	default BillboardComp.SpriteName = "S_TriggerSphere";
#endif

	UPROPERTY(EditAnywhere)
	FVector LocationOffset;

	UPROPERTY(EditAnywhere)
	float LocationMoveRate = 0.5;

	UPROPERTY(EditAnywhere)
	float LocationMoveMultiplier = 1.0;

	UPROPERTY(EditAnywhere)
	FRotator RotationOffset;

	UPROPERTY(EditAnywhere)
	float RotationMoveRate = 0.75;

	UPROPERTY(EditAnywhere)
	float RotationMoveMultiplier = 1.0;

	float RandomizedStartingOffset;

	FVector StartingLoc;
	FRotator StartingRot;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartingLoc = ActorLocation;
		StartingRot = ActorRotation;

		RandomizedStartingOffset = Math::RandRange(0.0, 3.5);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		float RotMult = Math::Sin(RandomizedStartingOffset + Time::GameTimeSeconds * LocationMoveRate);
		float LocMult = Math::Sin(RandomizedStartingOffset + Time::GameTimeSeconds * RotationMoveRate);
		FVector TargetLoc = StartingLoc + (LocationOffset * LocMult * LocationMoveMultiplier);
		FRotator TargetRot = StartingRot + (RotationOffset * RotMult * RotationMoveMultiplier);
		SetActorLocationAndRotation(TargetLoc, TargetRot);
	}
};