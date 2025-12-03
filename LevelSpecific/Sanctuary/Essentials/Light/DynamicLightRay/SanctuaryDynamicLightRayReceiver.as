event void FSanctuaryDynamicLightRayReceiverSignature();

class ASanctuaryDynamicLightRayReceiver : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent LightRayResponseCollision;
	default LightRayResponseCollision.bHiddenInGame = true;
	default LightRayResponseCollision.bGenerateOverlapEvents = false;
	default LightRayResponseCollision.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Ignore);
	default LightRayResponseCollision.SetCollisionResponseToChannel(ECollisionChannel::ECC_Visibility, ECollisionResponse::ECR_Block);
//	default LightRayResponseCollision.SphereRadius = 50.0;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent RotationPivot1;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent RotationPivot2;

	UPROPERTY(DefaultComponent)
	ULightBirdResponseComponent LightBirdResponseComp;

	UPROPERTY(DefaultComponent)
	ULightBirdChargeComponent LightBirdChargeComp;

	UPROPERTY(DefaultComponent)
	USanctuaryDynamicLightRayResponseComponent LightRayResponseComp;
	default LightRayResponseComp.RespondingPrimitives.Add(LightRayResponseCollision);

	UPROPERTY(DefaultComponent)
	USanctuaryInterfaceComponent InterfaceComp;

	FHazeAcceleratedFloat AcceleratedFloat;
	UPROPERTY(EditAnywhere)
	float TransitionSpeed = 1.0;

	UPROPERTY(EditAnywhere)
	float IdleRotationSpeed = 30.0;

	UPROPERTY(EditAnywhere)
	float ActiveRotationSpeed = 180.0;

	UPROPERTY(EditDefaultsOnly)
	UMaterialInterface Material;

	UPROPERTY(BlueprintReadOnly)
	UMaterialInstanceDynamic MID;

	UPROPERTY(EditDefaultsOnly)
	FName MaterialParameter = n"EmissiveColor";

	UPROPERTY(EditDefaultsOnly)
	FLinearColor EmissiveColor = FLinearColor(10.0, 10.0, 10.0, 1.0);

	FSanctuaryDynamicLightRayReceiverSignature OnActivated();
	FSanctuaryDynamicLightRayReceiverSignature OnDeactivated();

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MID = Material::CreateDynamicMaterialInstance(this, Material);

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

		RotationPivot1.AddLocalRotation(FRotator(0.0, 0.0, RotationSpeed * DeltaSeconds));
		RotationPivot2.AddLocalRotation(FRotator(0.0, 0.0, -RotationSpeed * DeltaSeconds));

		MID.SetVectorParameterValue(MaterialParameter, EmissiveColor * AcceleratedFloat.Value);
	}

	UFUNCTION()
	private void HandleIlluminated()
	{
		OnActivated.Broadcast();
		InterfaceComp.TriggerActivate();
	}

	UFUNCTION()
	private void HandleUnilluminated()
	{
		OnDeactivated.Broadcast();
		InterfaceComp.TriggerDeactivate();
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