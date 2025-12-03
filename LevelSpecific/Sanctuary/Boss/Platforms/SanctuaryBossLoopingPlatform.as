class ASanctuaryBossLoopingPlatform : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UFauxPhysicsConeRotateComponent FauxPhysicsConeRotateComponent;

	UPROPERTY(DefaultComponent, Attach = FauxPhysicsConeRotateComponent)
	UFauxPhysicsTranslateComponent FauxPhysicsTranslateComponent;

	UPROPERTY(DefaultComponent, Attach = FauxPhysicsTranslateComponent)
	UStaticMeshComponent MeshComp;

	UPROPERTY(DefaultComponent)
	USanctuaryBossHydraResponseComponent ResponseComp;

	UPROPERTY(DefaultComponent)
	UFauxPhysicsPlayerWeightComponent FauxPhysicsPlayerWeightComponent;

	UPROPERTY()
	FHazeTimeLike ImpactRotationTimelike;
	default ImpactRotationTimelike.Duration = 1.0;
	default ImpactRotationTimelike.Curve.AddDefaultKey(0.0, 0.0);
	default ImpactRotationTimelike.Curve.AddDefaultKey(1.0, 1.0);

	UPROPERTY()
	FHazeTimeLike ProjectileImpactTimelike;

	UPROPERTY()
	UMaterialInstance Material;

	UPROPERTY()
	float LocalRotationSpeed = 0.0;

	UPROPERTY(EditInstanceOnly)
	float PlatformImpactRotation = 10.0;

	UPROPERTY(EditInstanceOnly)
	float PlatformOrbitImpact = 5.0;

	UPROPERTY(EditInstanceOnly)
	ASanctuaryBossLoopingPlatform PlatformL1;

	float PlatformL1RotSpeed = 0.0;

	UPROPERTY(EditInstanceOnly)
	ASanctuaryBossLoopingPlatform PlatformL2;

	float PlatformL2RotSpeed = 0.0;

	UPROPERTY(EditInstanceOnly)
	ASanctuaryBossLoopingPlatform PlatformR1;

	float PlatformR1RotSpeed = 0.0;

	UPROPERTY(EditInstanceOnly)
	ASanctuaryBossLoopingPlatform PlatformR2;

	float PlatformR2RotSpeed = 0.0;

	UPROPERTY(EditInstanceOnly)
	ASanctuaryBossLoopingPlatformDebris Debris;

	UPROPERTY(EditInstanceOnly)
	ASanctuaryBossPhase2Manager Manager;

	float ManagerOrbitSpeed = 0.0;

	FVector MeshRelativeLocation;

	bool bMiddlePlatform = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (IsValid(Debris))
			Debris.AddActorDisable(this);

		ResponseComp.OnSmashed.AddUFunction(this, n"HandlePlatformSmashed");
		ImpactRotationTimelike.BindUpdate(this, n"ImpactRotationTimelikeUpdate");
		ProjectileImpactTimelike.BindUpdate(this, n"ProjectileImpactTimelikeUpdate");

		MeshRelativeLocation = MeshComp.RelativeLocation;
	}

	UFUNCTION()
	private void HandlePlatformSmashed(ASanctuaryBossHydraHead Head)
	{
		OnPlatformSmashed();

		if (!bMiddlePlatform)
		{
			PlatformL1RotSpeed = PlatformL1.LocalRotationSpeed;
			PlatformL2RotSpeed = PlatformL2.LocalRotationSpeed;
			PlatformR1RotSpeed = PlatformR1.LocalRotationSpeed;
			PlatformR2RotSpeed = PlatformR2.LocalRotationSpeed;
		}
		
		ManagerOrbitSpeed = Manager.PlatformSpeed;

		ImpactRotationTimelike.Play();
	}

	UFUNCTION()
	void StartSmashed()
	{
		PlatformL1.LocalRotationSpeed = PlatformL1RotSpeed + PlatformImpactRotation;
		PlatformL2.LocalRotationSpeed = PlatformL2RotSpeed + PlatformImpactRotation * 0.5;
		PlatformR1.LocalRotationSpeed = PlatformR1RotSpeed + PlatformImpactRotation * -1.0;
		PlatformR2.LocalRotationSpeed = PlatformR2RotSpeed + PlatformImpactRotation * -0.5;
		Manager.PlatformSpeed = PlatformOrbitImpact;

		OnStartSmashed();
	}

	UFUNCTION(BlueprintEvent)
	void OnPlatformSmashed()
	{
	}

	UFUNCTION(BlueprintEvent)
	void OnStartSmashed()
	{
	}

	UFUNCTION()
	void ImpactRotationTimelikeUpdate(float Alpha)
	{
		if (!bMiddlePlatform)
		{
			PlatformL1.LocalRotationSpeed = Math::Lerp(PlatformL1RotSpeed, PlatformL1RotSpeed + PlatformImpactRotation, Alpha);
			PlatformL2.LocalRotationSpeed = Math::Lerp(PlatformL2RotSpeed, PlatformL2RotSpeed + PlatformImpactRotation * 0.5, Alpha);
			PlatformR1.LocalRotationSpeed = Math::Lerp(PlatformR1RotSpeed, PlatformR1RotSpeed + PlatformImpactRotation * -1.0, Alpha);
			PlatformR2.LocalRotationSpeed = Math::Lerp(PlatformR2RotSpeed, PlatformR2RotSpeed + PlatformImpactRotation * -0.5, Alpha);
		}

		Manager.PlatformSpeed = Math::Lerp(ManagerOrbitSpeed, PlatformOrbitImpact, Alpha);
	}

	UFUNCTION()
	void ProjectileImpactTimelikeUpdate(float Alpha)
	{
		MeshComp.SetRelativeLocation(Math::Lerp(MeshRelativeLocation, MeshRelativeLocation + FVector::DownVector * 100.0, Alpha));
	}


	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		MeshComp.AddLocalRotation(FRotator(0.0, LocalRotationSpeed * DeltaSeconds, 0.0));
	}
};