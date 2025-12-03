class AStoneBeastMountainBackgroundRotator : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = Root)
	UEditorBillboardComponent Visual;
	default Visual.SetWorldScale3D(FVector(10.0));
#endif

	float InterpSpeed;
	FRotator Rotation;
	FVector OffsetLoc;

	FVector StartLoc;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartLoc = ActorLocation;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		SetActorLocationAndRotation(
			Math::VInterpTo(ActorLocation, StartLoc + OffsetLoc, DeltaSeconds, InterpSpeed),
			Math::RInterpTo(ActorRotation, Rotation, DeltaSeconds, InterpSpeed)
		);
	}

	UFUNCTION()
	void NewLocationOffsetAndRotation(FVector NewOffset, FRotator RotationTarget, float InterpTarget)
	{
		Rotation = RotationTarget;
		InterpSpeed = InterpTarget;
		OffsetLoc = NewOffset;
	}
};