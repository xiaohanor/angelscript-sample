UCLASS(Abstract)
class ASanctuaryLightableVortex : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent EmberMovingLocation;
	FVector OGEmberLocation;
	FHazeAcceleratedFloat AccSpringyZOffset;

	UPROPERTY(DefaultComponent, Attach = EmberMovingLocation)
	UStaticMeshComponent EmberMesh;
	FVector OGEmberScale;

	UPROPERTY(DefaultComponent, Attach = EmberMovingLocation)
	ULightBirdTargetComponent LightBirdTargetComponent;
	default LightBirdTargetComponent.AutoAimMaxAngle = 45.0;

	UPROPERTY(DefaultComponent)
	UPointLightComponent LightAmbient1;
	float32 Light1Intensity = 0.0;

	UPROPERTY(DefaultComponent)
	UPointLightComponent LightAmbient2;
	float32 Light2Intensity = 0.0;

	UPROPERTY(DefaultComponent)
	UPointLightComponent LightAmbient3;
	float32 Light3Intensity = 0.0;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent MeshEffectAmbient;
	FVector EffectScale;

	UPROPERTY(DefaultComponent)
	ULightBirdResponseComponent LightBirdResponseComponent;
	default LightBirdResponseComponent.bExclusiveAttachedIllumination = true;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike IlluminateTimelike;
	default IlluminateTimelike.UseSmoothCurveZeroToOne();

	const FVector SmallScale = FVector::OneVector * KINDA_SMALL_NUMBER * 2.0;

	UPROPERTY(EditInstanceOnly)
	AHazeSpotLight CeilingLight;
	float32 OGCeilIntensity = 0.0;

	UPROPERTY(EditInstanceOnly)
	AHazeSphere HazeSphere;
	float OGOpacity = 0.0;

	bool bLit = false;
	bool bAttached = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Light1Intensity = LightAmbient1.Intensity;
		Light2Intensity = LightAmbient2.Intensity;
		Light3Intensity = LightAmbient3.Intensity;

		LightAmbient1.SetIntensity(0.0);
		LightAmbient2.SetIntensity(0.0);
		LightAmbient3.SetIntensity(0.0);

		EffectScale = MeshEffectAmbient.GetWorldScale();
		MeshEffectAmbient.SetVisibility(false);

		OGEmberLocation = EmberMovingLocation.WorldLocation;
		OGEmberScale = EmberMesh.GetWorldScale();
	
		LightBirdResponseComponent.OnIlluminated.AddUFunction(this, n"StartIlluminate");
		LightBirdResponseComponent.OnAttached.AddUFunction(this, n"SpringToMiddle");
		LightBirdResponseComponent.OnDetached.AddUFunction(this, n"SpringDown");


		IlluminateTimelike.BindUpdate(this, n"IlluminationUpdate");
		BP_NoLight();
		if (CeilingLight != nullptr)
		{
			OGCeilIntensity = CeilingLight.SpotLightComponent.Intensity;
			CeilingLight.SpotLightComponent.SetIntensity(0.0);
		}
		if (HazeSphere != nullptr)
		{
			OGOpacity = HazeSphere.HazeSphereComponent.Opacity;
			HazeSphere.HazeSphereComponent.SetOpacityValue(0.0);
		}
	}

	UFUNCTION()
	private void SpringToMiddle()
	{
		bAttached = true;
	}

	UFUNCTION()
	private void SpringDown()
	{
		bAttached = false;
	}

	UFUNCTION(BlueprintEvent)
	void BP_NoLight() {}

	UFUNCTION()
	private void IlluminationUpdate(float CurrentValue)
	{
		LightAmbient1.SetIntensity(Math::Lerp(0.0, Light1Intensity, CurrentValue));
		LightAmbient2.SetIntensity(Math::Lerp(0.0, Light2Intensity, CurrentValue));
		LightAmbient3.SetIntensity(Math::Lerp(0.0, Light3Intensity, CurrentValue));
		MeshEffectAmbient.SetWorldScale3D(Math::Lerp(SmallScale, EffectScale, CurrentValue));
		if (CeilingLight != nullptr)
			CeilingLight.SpotLightComponent.SetIntensity(Math::Lerp(0.0, OGCeilIntensity, CurrentValue));
		if (HazeSphere != nullptr)
			HazeSphere.HazeSphereComponent.SetOpacityValue(Math::Lerp(0.0, OGOpacity, CurrentValue));
	}

	UFUNCTION()
	private void StartIlluminate()
	{
		LightBirdTargetComponent.Disable(this);
		LightBirdCompanion::GetLightBirdCompanion().CompanionComp.State = ELightBirdCompanionState::Follow;
		IlluminateTimelike.PlayFromStart();
		MeshEffectAmbient.SetVisibility(true);
		MeshEffectAmbient.SetWorldScale3D(SmallScale);
		BP_Illuminate();
		bLit = true;
	}

	UFUNCTION(BlueprintEvent)
	void BP_Illuminate() {}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (!bLit)
		{
			FVector EmberLocation = OGEmberLocation;
			const float LoopDuration = 10.0;
			float LoopAlpha = Math::Clamp(Math::Wrap(Time::GameTimeSeconds, 0.0, LoopDuration) / LoopDuration, 0.0, 1.0) * 2.0;
			if (LoopAlpha >= 1.0)
				LoopAlpha = 2.0 - LoopAlpha;
			const float HeightDiff = 50.0;
			EmberLocation.Z += Math::SinusoidalInOut(-HeightDiff, HeightDiff, LoopAlpha);

			if (bAttached)
				AccSpringyZOffset.SpringTo(0.0, 20, 0.5, DeltaSeconds);
			else
				AccSpringyZOffset.AccelerateTo(-150, 3.0, DeltaSeconds);

			EmberLocation.Z += AccSpringyZOffset.Value;
			EmberMovingLocation.SetWorldLocation(EmberLocation);

			FVector EmberScale = OGEmberScale;
			EmberMesh.SetWorldScale3D(EmberScale * Math::EaseInOut(1.0, 3.0, 1.0 - LoopAlpha, 2.0));

		}
	}
};
