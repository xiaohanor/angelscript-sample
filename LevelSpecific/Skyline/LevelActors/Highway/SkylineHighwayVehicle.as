class ASkylineHighwayVehicle : AHazeActor
{
	FHazeAcceleratedRotator AccRotator;	
	FRotator Rotation;
	float RotationDuration;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UEditorBillboardComponent Billboard;
#endif

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AccRotator.Value = ActorRotation;
		Rotation = ActorRotation;
	}

	UFUNCTION(BlueprintCallable)
	void Rotate(FRotator TargetRotation, float Duration)
	{
		Rotation = TargetRotation;
		RotationDuration = Duration;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		AccRotator.AccelerateTo(Rotation, RotationDuration, DeltaSeconds);
		ActorRotation = AccRotator.Value;
	}
}