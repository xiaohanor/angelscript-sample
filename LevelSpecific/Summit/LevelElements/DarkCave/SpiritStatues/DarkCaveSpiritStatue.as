event void FOnDarkCaveSpiritStatueDestroyed();
event void FOnDarkCaveSpiritStatueCompletedJourney(bool bIsLastOne);

class ADarkCaveSpiritStatue : ASummitNightQueenGem
{
	default TailResponseComp.bShouldStopPlayer = false;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	USpotLightComponent SpotLight;
	default SpotLight.SetIntensity(15.0);
	default SpotLight.CastShadows = false;
	default SpotLight.bUseInverseSquaredFalloff = false;

	UPROPERTY(DefaultComponent)
	USummitDarkCaveSaveComponent SaveComp;

	UPROPERTY()
	FOnDarkCaveSpiritStatueDestroyed OnDarkCaveSpiritStatueDestroyed;

	UPROPERTY()
	FOnDarkCaveSpiritStatueCompletedJourney OnDarkCaveSpiritStatueCompletedJourney;

	UPROPERTY(EditAnywhere)
	ANightQueenMetal MetalCovering;

	UPROPERTY(EditAnywhere)
	ADarkCaveDragonOrnament DragonOrnament;

	UPROPERTY(EditAnywhere)
	AActor MagicalCylinder;

	UPROPERTY(EditAnywhere)
	float DragonSpiritSpeed = 8000.0;

	UPROPERTY(EditAnywhere)
	AGodray GodRay;

	UPROPERTY(EditAnywhere)
	TSubclassOf<ADarkCaveDragonSpirit> DragonSpiritClass;
	ADarkCaveDragonSpirit DragonSpirit;

	UPROPERTY(EditDefaultsOnly)
	FRuntimeFloatCurve MoveCurve;
	default MoveCurve.AddDefaultKey(0.0, 0.0);
	default MoveCurve.AddDefaultKey(1.0, 1.0);

	UPROPERTY(EditDefaultsOnly)
	float MoveDuration = 2.0;
	float MoveTime;

	float CurrentIntensity = 2.5;

	TArray<AHazePlayerCharacter> Players;

	bool bSpiritFreed;
	bool bSpiritCompletedJourney;

	float GodRayOpacity;

	FVector GroundedLocation;
	FVector StartLocation;
	FVector CurrentActorLocation;
	float HeightOffset = 100.0;
	bool bMetalMelted;

	float OffsetLocation;

	float TargetIntensity;


	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		if(GodRay != nullptr)
		{
			GodRayOpacity = GodRay.Component.Opacity;
		}
		GroundedLocation = ActorLocation;
		StartLocation = ActorLocation + FVector::UpVector * HeightOffset;
		ActorLocation = StartLocation;
		CurrentActorLocation = ActorLocation;

		TargetIntensity = SpotLight.Intensity;
		SpotLight.SetIntensity(CurrentIntensity);

		MetalCovering.OnNightQueenMetalMelted.AddUFunction(this, n"OnNightQueenMetalMelted");
		SaveComp.OnSummitDarkCaveActivateSave.AddUFunction(this, n"OnSummitDarkCaveActivateSave");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		Super::Tick(DeltaSeconds);

		if (bCrystalDestroyed)
		{
			GodRayOpacity = Math::FInterpConstantTo(GodRayOpacity, 0.0, DeltaSeconds, GodRayOpacity * 0.75);
			GodRay.Component.SetGodrayOpacity(GodRayOpacity);
		}

		if (bMetalMelted)
		{
			MoveTime += DeltaSeconds;
			MoveTime = Math::Clamp(MoveTime, 0.0, MoveDuration);
			float Alpha = Math::Saturate(MoveTime / MoveDuration);
			CurrentActorLocation = Math::Lerp(StartLocation, GroundedLocation, MoveCurve.GetFloatValue(Alpha));
			CurrentIntensity = Math::FInterpConstantTo(CurrentIntensity, TargetIntensity, DeltaSeconds, TargetIntensity * 1.5);
			SpotLight.SetIntensity(CurrentIntensity);
		}

		FVector BobOffset = FVector(0.0, 0.0, 25) * Math::Sin(Time::GameTimeSeconds * 1.75);
		ActorLocation = CurrentActorLocation + BobOffset;

		AddActorLocalRotation(FRotator(0.0, 15 * DeltaSeconds, 0.0));
	}

	UFUNCTION()
	private void OnNightQueenMetalMelted()
	{
		bMetalMelted = true;
		UDarkCaveSpiritStatueEventHandler::Trigger_Exposed(this);
	}

	UFUNCTION(DevFunction)
	void SetStatueComplete()
	{
		bSpiritFreed = true;
	}

	void DestroyCrystal() override
	{
		if (bCrystalDestroyed)
			return;

		bCrystalDestroyed = true;

		if(!SceneView::IsFullScreen())
		{
			Game::Mio.PlayCameraShake(CameraShake, this, 1.5, ECameraShakePlaySpace::World);
			Game::Zoe.PlayCameraShake(CameraShake, this, 1.5, ECameraShakePlaySpace::World);
		}

		UDarkCaveSpiritStatueEventHandler::Trigger_Destroyed(this);
		
		if (bPlayDefaultDestroyEffect)
		{

			if(SmashEvent != nullptr)
			{
				AudioEventParams.Transform = Game::GetZoe().GetActorTransform();
				AudioComponent::PostFireForget(SmashEvent, AudioEventParams);
			}
		}

		SpotLight.SetIntensity(0.0);
		
		MeshComp.AddComponentVisualsBlocker(this);
		CapsuleComp.SetCollisionEnabled(ECollisionEnabled::NoCollision);

		if (MagicalCylinder != nullptr)
			MagicalCylinder.SetActorHiddenInGame(true);

		GodRay.AddActorDisable(this);

		Timer::SetTimer(this, n"DelayedSpiritStatueEvent", 0.5, false);
	}

	UFUNCTION()
	void DelayedSpiritStatueEvent()
	{
		bSpiritFreed = true;
		OnDarkCaveSpiritStatueDestroyed.Broadcast();
		OnSummitGemDestroyed.Broadcast(this);
	}

	UFUNCTION()
	private void OnSummitDarkCaveActivateSave()
	{
		SpotLight.SetIntensity(0.0);
		
		MeshComp.AddComponentVisualsBlocker(this);
		CapsuleComp.SetCollisionEnabled(ECollisionEnabled::NoCollision);

		if (MagicalCylinder != nullptr)
			MagicalCylinder.SetActorHiddenInGame(true);

		GodRay.AddActorDisable(this);

		bSpiritFreed = true;
		
		AddActorDisable(this);
	}
};