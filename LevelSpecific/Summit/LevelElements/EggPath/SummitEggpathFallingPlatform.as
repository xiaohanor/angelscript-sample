class ASummitEggpathFallingPlatform : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach=Root)
	UStaticMeshComponent PlatformMesh;

	UPROPERTY(DefaultComponent, Attach=Root)
	UStaticMeshComponent PlatformEnd;
	default PlatformEnd.CollisionProfileName = n"NoCollision";
	default PlatformEnd.bHiddenInGame = true;

	UPROPERTY(EditAnywhere)
	TSubclassOf<UCameraShakeBase> CameraShake;

	/* This is how long it will take for the Platform to open/close */
	UPROPERTY(EditAnywhere)
	float PlatformOpenDuration = 0.5;

	/* How it feels when the Platform opens */
	UPROPERTY(EditAnywhere)
	FRuntimeFloatCurve OpenInterpolation;
	default OpenInterpolation.AddDefaultKey(0.0, 0.0);
	default OpenInterpolation.AddDefaultKey(1.0, 1.0);

	FVector PlatformOriginalRelativeLocation;
	bool bPlatformIsOpen = false;
	float TimeOfChangeState = -100.0;
	float Speed;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		PlatformOriginalRelativeLocation = PlatformMesh.RelativeLocation;
	}

	UFUNCTION()
	void OpenPlatform()
	{
		bPlatformIsOpen = true;
		TimeOfChangeState = Time::GetGameTimeSeconds();

		Game::Mio.PlayWorldCameraShake(CameraShake, this, ActorLocation, 1000, 4000);
		Game::Zoe.PlayWorldCameraShake(CameraShake, this, ActorLocation, 1000, 4000);

		FVector OriginLocation = Root.WorldTransform.TransformPosition(PlatformOriginalRelativeLocation);
		FVector EndLocation = PlatformEnd.WorldLocation;

		float TotalDistance = OriginLocation.Distance(EndLocation);
		float CurrentDistance = PlatformMesh.WorldLocation.Distance(EndLocation);

		float CurrentAlpha = 1.0 - (CurrentDistance / TotalDistance);
		TimeOfChangeState -= CurrentAlpha * PlatformOpenDuration;

		PlatformStartFalling();
	}

	UFUNCTION()
	void ClosePlatform()
	{
		bPlatformIsOpen = false;
		TimeOfChangeState = Time::GetGameTimeSeconds();

		FVector OriginLocation = Root.WorldTransform.TransformPosition(PlatformOriginalRelativeLocation);
		FVector EndLocation = PlatformEnd.WorldLocation;

		float TotalDistance = OriginLocation.Distance(EndLocation);
		float CurrentDistance = PlatformMesh.WorldLocation.Distance(EndLocation);

		float CurrentAlpha = (CurrentDistance / TotalDistance);
		TimeOfChangeState -= CurrentAlpha * PlatformOpenDuration;
	}

	UFUNCTION(BlueprintPure)
	bool IsPlatformOpen()
	{
		return bPlatformIsOpen;
	}

	UFUNCTION(BlueprintEvent)
	void PlatformStartFalling() {}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		FVector OriginLocation = PlatformMesh.WorldTransform.TransformPosition(PlatformOriginalRelativeLocation);
		FVector EndLocation = PlatformEnd.WorldLocation;
		FRotator OriginRotation = PlatformMesh.WorldRotation;
		FRotator EndRotation = PlatformEnd.WorldRotation;
		PlatformMesh.WorldLocation = Math::Lerp(bPlatformIsOpen ? OriginLocation : EndLocation, bPlatformIsOpen ? EndLocation : OriginLocation, OpenInterpolation.GetFloatValue((Time::GetGameTimeSeconds() - TimeOfChangeState) / PlatformOpenDuration));
		PlatformMesh.WorldRotation = Math::LerpShortestPath(bPlatformIsOpen ? OriginRotation : EndRotation, bPlatformIsOpen ? EndRotation : OriginRotation, OpenInterpolation.GetFloatValue((Time::GetGameTimeSeconds() - TimeOfChangeState) / (PlatformOpenDuration * 2)));
		
		
		//Math::Lerp(bPlatformIsOpen ? OriginLocation : EndLocation, bPlatformIsOpen ? EndLocation : OriginLocation, OpenInterpolation.GetFloatValue((Time::GetGameTimeSeconds() - TimeOfChangeState) / PlatformOpenDuration));

	}
}