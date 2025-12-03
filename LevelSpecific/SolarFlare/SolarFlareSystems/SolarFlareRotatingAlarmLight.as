class ASolarFlareRotatingAlarmLight : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UPointLightComponent PointLight;
	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent AlarmMeshComp;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent GodRay1;
	default	GodRay1.SetHiddenInGame(true);
	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent GodRay2;
	default	GodRay2.SetHiddenInGame(true);
	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	USpotLightComponent SpotLight1;
	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	USpotLightComponent SpotLight2;

	UPROPERTY(EditAnywhere)
	bool bAlwaysActive = false;

	UPROPERTY()
	FRuntimeFloatCurve Curve;
	default Curve.AddDefaultKey(0, 0);
	default Curve.AddDefaultKey(0.3, 0.2);
	default Curve.AddDefaultKey(1, 1);

	UPROPERTY(EditDefaultsOnly)
	UMaterialInterface OffMat;
	UMaterialInterface OnMat;

	ASolarFlareSun Sun;

	float TargetRotSpeed = 180.0;
	float AlarmLightTarget;
	float AlarmLightCurrent;
	float AlarmLightIntensity = 90.0;
	bool bIsActive;

	float SpotLightIntensity;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Sun = TListedActors<ASolarFlareSun>().GetSingle();
		PointLight.SetIntensity(0.0);
		SpotLightIntensity = SpotLight1.Intensity;
		OnMat = AlarmMeshComp.GetMaterial(0);


		if (!bAlwaysActive)
		{
			SpotLight1.SetIntensity(0.0);
			SpotLight2.SetIntensity(0.0);
			GodRay1.SetHiddenInGame(true);
			GodRay2.SetHiddenInGame(true);
			AlarmMeshComp.SetMaterial(0, OffMat);

			Sun.OnSolarFlareSunStartBuildup.AddUFunction(this, n"OnSolarFlareSunStartBuildup");
			Sun.OnSolarFlareActivateWave.AddUFunction(this, n"OnSolarFlareDeactivateWave");
		}
		else
		{
			bIsActive = true;
		}
	}

	UFUNCTION()
	private void OnSolarFlareSunStartBuildup()
	{
		ActivateAlarmLight();
	}

	UFUNCTION()
	private void OnSolarFlareDeactivateWave()
	{
		DeactivateAlarmLight();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		float AlarmLightMultiplier = Math::Sin(Time::GameTimeSeconds * 4);
		AlarmLightMultiplier += 1;
		AlarmLightMultiplier /= 2;
		AlarmLightMultiplier *= Curve.GetFloatValue(AlarmLightMultiplier);

		// AlarmLightCurrent = Math::FInterpConstantTo(AlarmLightCurrent, AlarmLightTarget * AlarmLightMultiplier, DeltaSeconds, AlarmLightIntensity * 2.0);
		if (bIsActive)
			MeshRoot.AddLocalRotation(FRotator(0.0, TargetRotSpeed * DeltaSeconds, 0.0));
		
		// PointLight.SetIntensity(AlarmLightCurrent);
	}

	void ActivateAlarmLight()
	{
		bIsActive = true;

		SpotLight1.SetIntensity(SpotLightIntensity);
		SpotLight2.SetIntensity(SpotLightIntensity);
		GodRay1.SetHiddenInGame(true);
		GodRay2.SetHiddenInGame(true);	
		AlarmMeshComp.SetMaterial(0, OnMat);
	}

	void DeactivateAlarmLight()
	{
		bIsActive = false;

		SpotLight1.SetIntensity(0.0);
		SpotLight2.SetIntensity(0.0);
		GodRay1.SetHiddenInGame(false);
		GodRay2.SetHiddenInGame(false);
		AlarmMeshComp.SetMaterial(0, OffMat);
	}
}