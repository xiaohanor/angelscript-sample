class ASanctuaryLightBirdProximity : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UFauxPhysicsTranslateComponent TranslateComp;
	default TranslateComp.bConstrainX = true;
	default TranslateComp.bConstrainY = true;
	default TranslateComp.bConstrainZ = true;

	UPROPERTY(DefaultComponent, Attach = TranslateComp)
	UFauxPhysicsSpringConstraint SpringConstraint;
	default SpringConstraint.MaximumForce = 1000.0;

	UPROPERTY(DefaultComponent, Attach = TranslateComp)
	USanctuaryFloatingSceneComponent FloatingComp;

	UPROPERTY(DefaultComponent, Attach = FloatingComp)
	USceneComponent Pivot;

	UPROPERTY(DefaultComponent, Attach = Pivot)
	USceneComponent CoreRotationPivot;

	UPROPERTY(DefaultComponent, Attach = Pivot)
	USceneComponent RotationPivot1;

	UPROPERTY(DefaultComponent, Attach = Pivot)
	USceneComponent RotationPivot2;

	UPROPERTY(DefaultComponent, Attach = Pivot)
	USphereComponent LightProximityOverlap;
	default LightProximityOverlap.bGenerateOverlapEvents = false;
	default LightProximityOverlap.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Ignore);
	default LightProximityOverlap.SetCollisionResponseToChannel(ECollisionChannel::WeaponTraceMio, ECollisionResponse::ECR_Overlap);
	default LightProximityOverlap.SphereRadius = 50.0;

	UPROPERTY(DefaultComponent, Attach = Pivot)
	UDarkPortalTargetComponent DarkPortalTargetComp;

	UPROPERTY(DefaultComponent)
	ULightBirdResponseComponent LightBirdResponseComp;
	default LightBirdResponseComp.bCanBeIlluminatedFromProximity = true;

	UPROPERTY(DefaultComponent)
	ULightBirdChargeComponent LightBirdChargeComp;

	UPROPERTY(DefaultComponent)
	UDarkPortalResponseComponent DarkPortalResponseComp;

	UPROPERTY(DefaultComponent)
	UDarkPortalFauxPhysicsReactionComponent DarkPortalFauxPhysicsReactionComp;

	FHazeAcceleratedFloat AcceleratedFloat;

	UPROPERTY(EditAnywhere)
	float TransitionSpeed = 1.0;

	UPROPERTY(EditAnywhere)
	float IdleRotationSpeed = 30.0;

	UPROPERTY(EditAnywhere)
	float ActiveRotationSpeed = 180.0;

	UPROPERTY(EditDefaultsOnly)
	UMaterialInterface CoreMaterial;

	UPROPERTY(BlueprintReadOnly)
	UMaterialInstanceDynamic CoreMID;

	UPROPERTY(EditDefaultsOnly)
	FName MaterialParameter = n"EmissiveColor";

	UPROPERTY(EditDefaultsOnly)
	FLinearColor EmissiveColor = FLinearColor(10.0, 10.0, 10.0, 1.0);

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		CoreMID = Material::CreateDynamicMaterialInstance(this, CoreMaterial);

		LightBirdResponseComp.OnIlluminated.AddUFunction(this, n"HandleIlluminated");
		LightBirdResponseComp.OnUnilluminated.AddUFunction(this, n"HandleUnilluminated");
		LightBirdChargeComp.OnFullyCharged.AddUFunction(this, n"HandleFullyCharged");
		LightBirdChargeComp.OnChargeDepleted.AddUFunction(this, n"HandleChargeDepleted");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		AcceleratedFloat.AccelerateTo((LightBirdResponseComp.IsIlluminated() ? 1.0 : 0.0), TransitionSpeed, DeltaSeconds);
		float RotationSpeed = Math::Lerp(IdleRotationSpeed, ActiveRotationSpeed, AcceleratedFloat.Value);

		CoreRotationPivot.AddLocalRotation(FRotator(0.0, RotationSpeed * DeltaSeconds, RotationSpeed * DeltaSeconds));
		RotationPivot1.AddLocalRotation(FRotator(0.0, RotationSpeed * DeltaSeconds, 0.0));
		RotationPivot2.AddLocalRotation(FRotator(0.0, 0.0, RotationSpeed * DeltaSeconds));
	
		CoreMID.SetVectorParameterValue(MaterialParameter, EmissiveColor * AcceleratedFloat.Value);
	}

	UFUNCTION()
	private void HandleIlluminated()
	{
	}

	UFUNCTION()
	private void HandleUnilluminated()
	{
	}

	UFUNCTION()
	private void HandleFullyCharged()
	{
	}

	UFUNCTION()
	private void HandleChargeDepleted()
	{
	}
};