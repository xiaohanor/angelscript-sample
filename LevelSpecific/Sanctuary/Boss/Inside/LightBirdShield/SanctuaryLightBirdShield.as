class USanctuaryLightBirdShieldEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void ZoeEnterShield(){}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void ZoeExitShield(){}
};

class ASanctuaryLightBirdShield : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent LightPivot;

	UPROPERTY(DefaultComponent)
	USceneComponent ShieldPivot;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedActorComp;

	UPROPERTY(EditDefaultsOnly)
	UMaterialParameterCollection GlobalParametersVFX;

	UPROPERTY(EditDefaultsOnly)
	float Radius = 600.0;
	float CurrentRadius = 0.0;

	FHazeAcceleratedFloat Scale;

	bool bIsIlluminating = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		auto LightBird = LightBirdCompanion::GetLightBirdCompanion();
		AttachToActor(Game::Mio, n"Hips");
//		ShieldPivot.AttachToComponent(Game::Mio.Mesh, n"Hips");
		LightPivot.AttachToComponent(LightBird.RootComponent);

		TArray<UPrimitiveComponent> Primitives;
		GetComponentsByClass(Primitives);
		for (auto Primitive : Primitives)
		{
			if (Primitive.HasTag(n"ZoeOnlySee"))
				Primitive.SetRenderedForPlayer(Game::Mio, false);
		}

		Scale.SnapTo(1.0);

		Illuminate();
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		PrintToScreen("AccFloat");
	}

	UFUNCTION()
	void LightShieldHit(FVector HitLocation)
	{
		FRotator WorldHitRotation = (HitLocation - ActorLocation).GetSafeNormal().ToOrientationRotator();

		FRotator RelativeHitRotation = ShieldPivot.WorldTransform.InverseTransformRotation(WorldHitRotation);
		FVector RelativeHitLocation = ShieldPivot.WorldTransform.InverseTransformPosition(HitLocation);

	//	Debug::DrawDebugArrow(HitLocation, HitLocation + WorldHitRotation.ForwardVector * 200.0, Duration = 1.0);

		BP_LightShieldHit(RelativeHitLocation, RelativeHitRotation);
	}

	UFUNCTION(BlueprintEvent)
	private void BP_LightShieldHit(FVector HitLocation, FRotator HitRotation){}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (bIsIlluminating)
			Scale.SpringTo(1.0, 300.0, 0.5, DeltaSeconds);
		else
			Scale.ThrustTo(0.0, 0.5, DeltaSeconds, 5.0); // 50.0

		CurrentRadius = Scale.Value * Radius;

		ActorScale3D = FVector::OneVector * (Math::Max(0.0, CurrentRadius * 0.01 + SMALL_NUMBER));
	
		PrintToScreen("AccFloat: " + Scale.Value);
		PrintToScreen("AccFloatVelocity: " + Scale.Velocity);

//		Debug::DrawDebugSphere(ActorLocation, Radius * Scale.Value, 12, FLinearColor::Red, 3.0, 0.0);

		Material::SetVectorParameterValue(GlobalParametersVFX, n"SphereMaskDarkness", FLinearColor(ActorLocation.X, ActorLocation.Y, ActorLocation.Z, 1.0));
		Material::SetScalarParameterValue(GlobalParametersVFX, n"RadiusDarkness", CurrentRadius);
	}

	void Illuminate()
	{
		Scale.SnapTo(Scale.Value);
		bIsIlluminating = true;
	}

	void Unilluminate()
	{
		Scale.SnapTo(Scale.Value);
		bIsIlluminating = false;
	}

	UFUNCTION(BlueprintPure)
	float GetCurrentShieldRadius() property
	{
		return CurrentRadius;
	}

	UFUNCTION(BlueprintPure)
	float GetShieldAlpha() property
	{
		return CurrentRadius / Radius;
	}
};