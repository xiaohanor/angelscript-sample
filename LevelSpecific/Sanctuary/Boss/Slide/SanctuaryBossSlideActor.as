class ASanctuaryBossSlideActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, EditDefaultsOnly)
	UHazeRequestCapabilityOnPlayerComponent CapabilityRequestComponent;

	UPROPERTY(EditAnywhere)
	float Speed = 2000.0;

	UPROPERTY(EditAnywhere)
	float ConstrainRadius = 500.0;

	UPROPERTY(EditAnywhere)
	FTransform MioStartTransform;

	UPROPERTY(EditAnywhere)
	FTransform ZoeStartTransform;

	UPROPERTY(EditAnywhere)
	AActor ActorWithSpline;
	UHazeSplineComponent Spline;

	FSplinePosition SplinePosition;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (ActorWithSpline != nullptr)
		{
			Spline = UHazeSplineComponent::Get(ActorWithSpline);

			SplinePosition = Spline.GetSplinePositionAtSplineDistance(0.0);
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		SplinePosition.Move(Speed * DeltaSeconds);

		SetActorLocationAndRotation(
			SplinePosition.WorldLocation,
			SplinePosition.WorldRotation
		);		
	}

	UFUNCTION(DevFunction)
	void StartSlide()
	{
		SetActorTickEnabled(true);

		Game::Mio.ApplyViewSizeOverride(this, EHazeViewPointSize::Fullscreen, EHazeViewPointBlendSpeed::Instant);

		for (auto Player : Game::Players)
		{
//			Player.ActivateCamera(Camera, 0.0, this, EHazeCameraPriority::VeryHigh);

			CapabilityRequestComponent.StartInitialSheetsAndCapabilities(Player, this);

			auto PlayerComp = USanctuaryBossSlidePlayerComponent::Get(Player);
			// PlayerComp.SlideActor = this;
		}

		BP_StartSlide();
	}

	UFUNCTION(BlueprintEvent)
	void BP_StartSlide() { }

	UFUNCTION(DevFunction)
	void EndSlide()
	{
		if (!IsActorTickEnabled())
			return;

		SetActorTickEnabled(false);

		Game::Mio.ClearViewSizeOverride(this, EHazeViewPointBlendSpeed::Instant);
		
		for (auto Player : Game::Players)
		{
//			Player.DeactivateCameraByInstigator(this);
		
			CapabilityRequestComponent.StopInitialSheetsAndCapabilities(Player, this);
		}
	
		BP_EndSlide();
	}

	UFUNCTION(BlueprintEvent)
	void BP_EndSlide() { }
};