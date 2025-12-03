class AFairyGroundWarp : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent MeshComp;

	UPROPERTY(DefaultComponent)
	UTundraShapeshiftingInteractionComponent FairyInteractComp;

	float TimeStarted = 0;

	UPROPERTY(EditAnywhere)
	AFairyGroundWarp TargetWarpActor;

	UPROPERTY(EditAnywhere)
	AHazeCameraActor CameraOverride;

	FVector StartLocation;
	FVector Offset = FVector(0,0,-100);

	FVector WarpStartLocation;
	FVector WarpEndLocation;

	FVector OffsetLocation;

	bool bIsMovingDown = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		FairyInteractComp.OnInteractionStarted.AddUFunction(this, n"OnInteractStarted");
		FairyInteractComp.OnInteractionStopped.AddUFunction(this, n"OnInteractStopped");
		SetActorTickEnabled(false);
	}

	UFUNCTION()
	private void OnInteractStopped(UInteractionComponent InteractionComponent,
	                               AHazePlayerCharacter Player)
	{
		Player.DeactivateCameraByInstigator(this, 2.0);
		Player.UnblockCapabilities(CameraTags::CameraControl, this);
	}

	UFUNCTION()
	private void OnInteractStarted(UInteractionComponent InteractionComponent,
	                               AHazePlayerCharacter Player)
	{
		TimeStarted = Time::GameTimeSeconds;
		StartLocation = Player.ActorLocation;
		OffsetLocation = StartLocation + Offset;
		bIsMovingDown = true;

		WarpStartLocation = TargetWarpActor.ActorLocation - (TargetWarpActor.ActorUpVector * 100);
		WarpEndLocation = TargetWarpActor.ActorLocation;
		SetActorTickEnabled(true);
		Player.ActivateCamera(CameraOverride, 0.5, this, EHazeCameraPriority::VeryHigh);
		Player.BlockCapabilities(CameraTags::CameraControl, this);
	}
	

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (bIsMovingDown)
		{
			float Alpha = Math::Saturate(Time::GetGameTimeSince(TimeStarted)/0.5);
			FVector NewLocation = Math::Lerp(StartLocation, OffsetLocation, Alpha);
			Game::Zoe.SetActorLocationAndRotation(NewLocation, ActorRotation);
			if (Alpha >= 1.0)
			{
				bIsMovingDown = false;
				TimeStarted = Time::GameTimeSeconds;
			}
		}
		else
		{
			float Alpha = Math::Saturate(Time::GetGameTimeSince(TimeStarted)/0.5);
			FVector NewLocation = Math::Lerp(WarpStartLocation, WarpEndLocation, Alpha);
			Game::Zoe.SetActorLocationAndRotation(NewLocation, TargetWarpActor.ActorRotation);
			if (Alpha >= 1.0)
			{
				SetActorTickEnabled(false);
				FairyInteractComp.KickAnyPlayerOutOfInteraction();
			}
		}
	}
};