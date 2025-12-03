class ADiscSlideEatingHydra : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UHazeSkeletalMeshComponentBase Skelly;
	default Skelly.bVisible = true;

	UPROPERTY(DefaultComponent)
	UBillboardComponent StartEatLocation;

	UPROPERTY(DefaultComponent)
	UBillboardComponent EndEatLocation;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent TriggerComp;
	default TriggerComp.BoxExtent = FVector::OneVector * 1000.0;

	bool bStartedEating = false;

	float EatTimer = 0.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TriggerComp.OnComponentBeginOverlap.AddUFunction(this, n"TriggerBeginOverlap");
		Skelly.SetVisibility(false);
		StartEatingCamera();
	}

	UFUNCTION()
	private void TriggerBeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                                 UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep,
	                                 const FHitResult&in SweepResult)
	{
		StartEatingCamera();
	}

	void StartEatingCamera()
	{
		BP_Triggered();
		bStartedEating = true;
		Skelly.SetVisibility(true, true);
	}

	UFUNCTION(BlueprintEvent)
	void BP_Triggered() {}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (bStartedEating)
		{
			FTransform Tranformy = Game::Mio.ViewTransform;
			SetActorLocation(Tranformy.Location);
			SetActorRotation(Tranformy.Rotator());

			EatTimer += DeltaSeconds;
			float Alpha = Math::Clamp(EatTimer / 5.0, 0.0, 1.0);
			Skelly.SetRelativeLocation(Math::EaseInOut(-StartEatLocation.RelativeLocation, -EndEatLocation.RelativeLocation, Alpha, 2.0));
		}
	}
};