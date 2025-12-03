event void FOnSummitPipeDoorOpened();

class ASummitPipeDoor : AHazeActor
{
	UPROPERTY()
	FOnSummitPipeDoorOpened OnSummitPipeDoorOpened;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent LDoor;

	UPROPERTY(DefaultComponent, Attach = LDoor)
	UStaticMeshComponent LDoorMesh;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent RDoor;

	UPROPERTY(DefaultComponent, Attach = RDoor)
	UStaticMeshComponent RDoorMesh;

	UPROPERTY(EditAnywhere)
	bool bIsAudioTesting;

	UPROPERTY()
	FRuntimeFloatCurve Curve;
	default Curve.AddDefaultKey(0, 0);
	default Curve.AddDefaultKey(1.0, 1.0);

	float MaxAngle = 90.0;
	float AlphaTime;
	float Duration = 5.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorTickEnabled(false);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		AlphaTime += DeltaSeconds / Duration;
		AlphaTime = Math::Clamp(AlphaTime, 0, Duration);
		LDoor.RelativeRotation = FRotator(0,Curve.GetFloatValue(AlphaTime) * MaxAngle,0);
		RDoor.RelativeRotation = FRotator(0,-Curve.GetFloatValue(AlphaTime) * MaxAngle,0);
	}

	void StartDoorOpeningSequence()
	{
		SetActorTickEnabled(true);
		OnSummitPipeDoorOpened.Broadcast();
	}
};