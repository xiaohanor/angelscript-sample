event void FSanctuaryIsPlayerInAntiGravitySignature(AHazePlayerCharacter Player, bool bInField);

UCLASS(Abstract)
class ASanctuaryAntiGravityField : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USphereComponent OverlapperField;

	UPROPERTY(DefaultComponent, Attach = Root)
	UPointLightComponent PointLightComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent Mesh;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent ScaleRoot;

	UPROPERTY(DefaultComponent, Attach = ScaleRoot)
	UHazeSphereComponent HazeSphereComponent;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent Billboard;

	UPROPERTY(DefaultComponent)
	ULightBirdResponseComponent LightBirdResponseComponent;

	UPROPERTY(Category = "Swimming Settings", EditAnywhere, BlueprintReadOnly)
	const EPlayerSwimmingActiveState SwimmingState = EPlayerSwimmingActiveState::Active;

	UPROPERTY(Category = "Swimming Settings", EditAnywhere)
	UPlayerSwimmingSettings SwimmingSettings;

	UPROPERTY()
	UHazeCameraSpringArmSettingsDataAsset CameraSettings;

	UPROPERTY()
	UMovementGravitySettings GravitySettings;

	UPROPERTY(EditAnywhere)
	bool bSwimming = true;

	UPROPERTY()
	float MaxForce = 1300.0;

	UPROPERTY()
	float MinForceFraction = 0.8;

	UPROPERTY()
	float EjectForce = 500.0;

	bool bLit = false;
	bool bDebugLit = false;
	FHazeAcceleratedFloat AccRadius;
	float CachedRadius;

	float MaxRadius = 0.0;
	float MinRadius = 0.1;

	UPROPERTY(EditAnywhere)
	float AccelerationDuration = 3.0;

	TArray<ASanctuaryAntiGravityAffectedObject> AffectedObjects;
	TPerPlayer<bool> bPlayerInsideGravityField;

	float DebugLitTimer = 0.0;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		HazeSphereComponent.ConstructionScript_Hack();
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		LightBirdResponseComponent.OnIlluminated.AddUFunction(this, n"StartIlluminate");
		LightBirdResponseComponent.OnUnilluminated.AddUFunction(this, n"StopIlluminate");

		OverlapperField.OnComponentBeginOverlap.AddUFunction(this, n"PlayerEnterField");
		OverlapperField.OnComponentEndOverlap.AddUFunction(this, n"PlayerExitField");

		MaxRadius = OverlapperField.SphereRadius;
		OverlapperField.SetSphereRadius(MinRadius);
		PointLightComp.SetAttenuationRadius(MinRadius);

		ScaleRoot.SetWorldScale3D(FVector(MinRadius * 0.01));
		HazeSphereComponent.UpdateScale();
		
		AccRadius.SnapTo(MinRadius);
		CachedRadius = MinRadius;

		TListedActors<ASanctuaryAntiGravityAffectedObject> Objecties;
		AffectedObjects = Objecties.GetArray();

		// WOW this reversed for loop is soo cool!

		// for (int i = AffectedObjects.Num() - 1; i >= 0; i--)
		// {
		// 	if (AffectedObjects[i].GetDistanceTo(this) > MaxRadius * 2.0)
		// 	{
		// 		AffectedObjects.RemoveAt(i);
		// 	}
		// }

		SanctuaryAntiGravityFieldDevToggles::AntiGravityCategory.MakeVisible();
	}

	UFUNCTION()
	private void StartIlluminate()
	{
		bLit = true;

		if (AffectedObjects.Num() <= 0)
		{
			TListedActors<ASanctuaryAntiGravityAffectedObject> Objecties;
			AffectedObjects = Objecties.GetArray();
		}
	}

	UFUNCTION()
	private void StopIlluminate()
	{
		bLit = false;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		bDebugLit = false;
		if (SanctuaryAntiGravityFieldDevToggles::AutoToggle.IsEnabled())
		{
			bDebugLit = true;
			DebugLitTimer += DeltaSeconds;
			const float DebugToggleDuration = 6.0;
			bLit = Math::Fmod(DebugLitTimer, DebugToggleDuration) / DebugToggleDuration > 0.5;
		}

		if (bLit || bDebugLit)
			AccRadius.AccelerateTo(MaxRadius, AccelerationDuration, DeltaSeconds);
		else
			AccRadius.AccelerateTo(MinRadius, 2.0, DeltaSeconds);

		if (!Math::IsNearlyEqual(AccRadius.Value, CachedRadius, 1.0))
		{
			CachedRadius = AccRadius.Value;
			OverlapperField.SetSphereRadius(CachedRadius);
			PointLightComp.SetAttenuationRadius(CachedRadius);
			ScaleRoot.SetWorldScale3D(FVector(CachedRadius * 0.01));
			HazeSphereComponent.UpdateScale();
		}

		// Apply force if player is inside volume
		for (auto Player : Game::Players)
		{
			if (!bPlayerInsideGravityField[Player])
				continue;

			float DistanceToPlayer = ActorLocation.Distance(Player.ActorLocation);

			FVector CurrentDirection = (ActorLocation - Player.ActorCenterLocation).GetSafeNormal();

			if (DistanceToPlayer >= OverlapperField.SphereRadius * MinForceFraction)
				Player.AddMovementImpulse(CurrentDirection * MaxForce * DeltaSeconds);
		}

		CheckUpdateOverlaps();
		if (SanctuaryAntiGravityFieldDevToggles::DrawSphere.IsEnabled())
			Debug::DrawDebugSphere(ActorLocation, CachedRadius, 12, ColorDebug::Cyan);
	}

	void CheckUpdateOverlaps()
	{
		const float BobbingLoopTime = 5.0;
		const float BobbingWaveLength = 500.0;
		const float BobbingLoopProgress = Math::Fmod(Time::GameTimeSeconds, BobbingLoopTime) / BobbingLoopTime;
		const float BobbingWave = BobbingWaveLength * BobbingLoopProgress;
		for (int iObject = 0; iObject < AffectedObjects.Num(); ++iObject)
		{
			if (CachedRadius < 1.0)
			{
				AffectedObjects[iObject].bIsInsideAntiGravity.Clear(this);
				AffectedObjects[iObject].AntiGravityBobbingForce = 0.0;
			}
			else
			{
				FVector Diff = AffectedObjects[iObject].Mesh.WorldLocation - ActorLocation;
				bool bIsInside = Diff.Size() < CachedRadius;
				if (bIsInside)
				{
					Diff.Z = 0.0;
					float PlaceOnWave = Math::Fmod(Diff.Size() + BobbingWave, BobbingWaveLength);
					float BobbingAlpha = (PlaceOnWave / BobbingWaveLength);
					BobbingAlpha *= 2.0;
					if (BobbingAlpha > 1.0)
						BobbingAlpha = 2.0 - BobbingAlpha;
					AffectedObjects[iObject].AntiGravityBobbingForce = BobbingAlpha;

				AffectedObjects[iObject].bIsInsideAntiGravity.Apply(true, this);
				}
				else
				{
					AffectedObjects[iObject].AntiGravityBobbingForce = 0.0;
					AffectedObjects[iObject].bIsInsideAntiGravity.Clear(this);
				}
			}
		}
	}

	UFUNCTION()
	private void PlayerEnterField(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                              UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep,
	                              const FHitResult&in SweepResult)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player != nullptr)
		{
			USanctuaryAntiGravityPlayerComponent Compy = USanctuaryAntiGravityPlayerComponent::GetOrCreate(Player);
			Compy.bIsInAntiGravityField = true;
			Compy.OverlappingFields.Add(this);

			if (bSwimming)
			{
				UPlayerSwimmingComponent::GetOrCreate(Player).ApplySwimmingState(SwimmingState, this);
				Player.ApplySettings(SwimmingSettings, this);
				Player.ApplyCameraSettings(CameraSettings, 3.0, this, EHazeCameraPriority::VeryHigh);
				//Player.AddMovementImpulse(FVector::UpVector * 700.0);	

				FVector EjectDirection = (Player.ActorCenterLocation - ActorLocation).GetSafeNormal();
				Player.AddMovementImpulse(-EjectDirection * EjectForce + FVector::UpVector * 400.0);
			}
			else
			{
				Player.ApplySettings(GravitySettings, this);
				Player.AddMovementImpulse(FVector::UpVector * 700.0);	
			}

			bPlayerInsideGravityField[Player] = true;
		}
	}

	UFUNCTION()
	private void PlayerExitField(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                             UPrimitiveComponent OtherComp, int OtherBodyIndex)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player != nullptr)
		{
			USanctuaryAntiGravityPlayerComponent Compy = USanctuaryAntiGravityPlayerComponent::GetOrCreate(Player);
			Compy.bIsInAntiGravityField = false;
			Compy.OverlappingFields.Remove(this);

			UPlayerSwimmingComponent::GetOrCreate(Player).ClearSwimmingState(this);
			Player.ClearCameraSettingsByInstigator(this, 3.0);
			Player.ClearSettingsByInstigator(this);

			bPlayerInsideGravityField[Player] = false;

			FVector EjectDirection = (Player.ActorCenterLocation - ActorLocation).GetSafeNormal();

			Player.AddMovementImpulse(EjectDirection * EjectForce + FVector::UpVector * 400.0);
		}
	}
};