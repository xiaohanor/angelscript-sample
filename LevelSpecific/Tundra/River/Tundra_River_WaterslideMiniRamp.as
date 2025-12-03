UCLASS(Abstract)
class ATundra_River_WaterslideMiniRamp : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent LaunchZone;

	UPROPERTY(DefaultComponent, Attach = Root)
	UArrowComponent LaunchDirection;

	UPROPERTY(EditInstanceOnly)
	APlayerForceSlideVolume SlideVolume;

	UPROPERTY(EditAnywhere)
	const float CooldownDuration = 0.5;

	UPROPERTY(EditAnywhere)
	float ImpulseStrength = 1300;

	UPROPERTY(EditAnywhere)
	bool bShouldZeroVelocity = false;

	float CooldownTimer = -1;
	bool bReady = true;
	
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		LaunchZone.OnComponentBeginOverlap.AddUFunction(this, n"OnOverlapBegin");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(CooldownTimer > 0)
		{
			CooldownTimer -= DeltaSeconds;
		}
		else if (CooldownTimer <= 0 && !bReady)
		{
			bReady = true;
			SlideVolume.SetVolumeEnabled(true);
		}
	}

	UFUNCTION()
	private void OnOverlapBegin(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                       UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep,
	                       const FHitResult&in SweepResult)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if(Player == nullptr || Player.IsZoe())
			return;

		LaunchPlayer(Player);
	}

	UFUNCTION()
	void LaunchPlayer(AHazePlayerCharacter Player)
	{
		if(CooldownTimer > 0)
			return;

		CooldownTimer = CooldownDuration;
		bReady = false;

		if(bShouldZeroVelocity)
		{
			Player.SetActorHorizontalAndVerticalVelocity(FVector::ZeroVector, FVector::ZeroVector);
		}

		SlideVolume.SetVolumeEnabled(false);
		// SlideVolume.ClearForceSlide(Player);
		Player.AddPlayerLaunchMovementImpulse(LaunchDirection.ForwardVector * ImpulseStrength);
	}
};
