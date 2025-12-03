class ASanctuaryProximityCrystal : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent RingMeshComp1;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent RingMeshComp2;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent RingMeshComp3;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent CrystalMesh1;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent CrystalMesh2;

	UPROPERTY(DefaultComponent, Attach = Root)
	USphereComponent CollisionComp;
	default CollisionComp.bGenerateOverlapEvents = false;
	default CollisionComp.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Ignore);
	default CollisionComp.SetCollisionResponseToChannel(ECollisionChannel::WeaponTraceMio, ECollisionResponse::ECR_Overlap);

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent VFXComp;

	UPROPERTY()
	UMaterialInterface CrystalMaterial;

	UPROPERTY(BlueprintReadOnly)
	UMaterialInstanceDynamic MID;

	UPROPERTY()
	FLinearColor EmissiveColor;

	UPROPERTY(DefaultComponent)
	ULightBirdResponseComponent LightBirdResponseComp;
	default LightBirdResponseComp.bCanBeIlluminatedFromProximity = true;

	FHazeTimeLike CrystalActivationTimeLike;
	default CrystalActivationTimeLike.UseLinearCurveZeroToOne();
	default CrystalActivationTimeLike.Duration = 0.5;

	float RotationSpeed = 30.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MID = Material::CreateDynamicMaterialInstance(this, CrystalMaterial);
		LightBirdResponseComp.OnIlluminated.AddUFunction(this, n"HandleIlluminated");
		LightBirdResponseComp.OnUnilluminated.AddUFunction(this, n"HandleUnIlluminated");
		CrystalActivationTimeLike.BindUpdate(this, n"CrystalActivationTimeLikeUpdate");

		//CrystalMesh1.SetMaterial(0, CrystalMaterial);
		//CrystalMesh2.SetMaterial(0, CrystalMaterial);
	}

	UFUNCTION()
	private void HandleIlluminated()
	{
		CrystalActivationTimeLike.Play();
		VFXComp.Activate();
	}

	UFUNCTION()
	private void HandleUnIlluminated()
	{
		CrystalActivationTimeLike.Reverse();
		VFXComp.Deactivate();
	}

	UFUNCTION()
	private void CrystalActivationTimeLikeUpdate(float CurrentValue)
	{
		FLinearColor NewColor = EmissiveColor * Math::Lerp(0.1, 1000.0, CurrentValue);
		MID.SetVectorParameterValue(n"EmissiveColor", NewColor);
		
		//PrintToScreen("Color: " + MID.GetVectorParameterValue(n"EmissiveColor"), 3.0);

		RotationSpeed = Math::Lerp(30.0, 300.0, CurrentValue);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		float DeltaRotation = RotationSpeed * DeltaSeconds;

		RingMeshComp1.AddWorldRotation(FRotator(DeltaRotation, DeltaRotation * 0.5, DeltaRotation * 0.3));
		RingMeshComp2.AddWorldRotation(FRotator(DeltaRotation, DeltaRotation * 0.2, DeltaRotation * -1));
		RingMeshComp3.AddWorldRotation(FRotator(DeltaRotation * 0.3, DeltaRotation -1,  DeltaRotation));
	}
};