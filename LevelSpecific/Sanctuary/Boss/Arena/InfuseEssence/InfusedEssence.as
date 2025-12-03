class AInfusedEssence : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USanctuaryFloatingSceneComponent FloatingComp;

	UPROPERTY()
	UNiagaraSystem VFXSystem;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent ZoeEssence;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent MioEssence;

	int EssenceID = 0;
	int TotalEssences = 3;

	bool bDoOnce = true;

	FHazeAcceleratedVector AccLocation;
	FHazeAcceleratedFloat AccRadius;

	AHazeCharacter FollowCompanion;
	ASanctuaryBossArenaManager ArenaManager;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AccRadius.SnapTo(0.0);
		TListedActors<ASanctuaryBossArenaManager> ArenaManagers;
		if (ArenaManagers.Num() > 0)
			ArenaManager = ArenaManagers.Single;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		float SecondsPerCircling = 3.0;
		float ProgressAlpha = Math::Fmod(Time::GameTimeSeconds, SecondsPerCircling) / SecondsPerCircling; // circles per seconds

		float RadiusTarget = ProgressAlpha < 0.5 ? 0.0 : 1.0;
		AccRadius.AccelerateTo(RadiusTarget, SecondsPerCircling, DeltaSeconds);
		float Radius = Math::EaseInOut(20.0 * FollowCompanion.GetActorScale3D().Size(), 30.0 * FollowCompanion.GetActorScale3D().Size(), AccRadius.Value, 2.0);

		float PulsingAlpha = Math::Lerp(-1.0, 1.0, ProgressAlpha);
		SetActorScale3D(FVector::OneVector * Math::EaseInOut(0.5, 0.5 * FollowCompanion.GetActorScale3D().Size() * 0.5, Math::Sin(PulsingAlpha), 2.0));

		float EssenceRotationStep = (360.0 / TotalEssences);
		float RotationProgress = 360.0 * ProgressAlpha + (EssenceRotationStep * EssenceID);

		FVector RotationAxis = -FVector::UpVector;
		if (ArenaManager != nullptr)
		{
			FVector ToCompanion = FollowCompanion.ActorLocation - ArenaManager.ActorLocation;
			ToCompanion.Z = 0;
			RotationAxis = ToCompanion.GetSafeNormal();
		}
		else if (EssenceID == 1)
			RotationAxis = (FVector::UpVector + FVector::RightVector).GetSafeNormal();
		else if (EssenceID == 2)
			RotationAxis = (FVector::UpVector - FVector::RightVector).GetSafeNormal();

		FVector RelativeLocation = Math::RotatorFromAxisAndAngle(RotationAxis, RotationProgress).ForwardVector * Radius;
		AccLocation.AccelerateTo(FollowCompanion.ActorLocation + RelativeLocation, SecondsPerCircling * 0.5, DeltaSeconds);

		SetActorLocation(AccLocation.Value);
		
		if(bDoOnce)
		{
			bDoOnce = false;
			
			if(FollowCompanion.IsA(AAISanctuaryDarkPortalCompanion))
			{
				ZoeEssence.SetHiddenInGame(false);
			}

			if(FollowCompanion.IsA(AAISanctuaryLightBirdCompanion))
			{
				MioEssence.SetHiddenInGame(false);
			}
		}
	}

};