class USanctuaryDynamicLightRayMeshComponent : UStaticMeshComponent
{
	default bGenerateOverlapEvents = false;
	default CollisionEnabled = ECollisionEnabled::NoCollision;
	default CollisionResponseToAllChannels = ECollisionResponse::ECR_Ignore;

	FHazeAcceleratedFloat AcceleratedFloat;
	float TransitionSpeed = 0.5;

	UPROPERTY(EditDefaultsOnly)
	UMaterialInterface Material;
	UMaterialInstanceDynamic MID;

	UPROPERTY(EditDefaultsOnly)
	FName MaterialParameter = n"EmissiveColor";

	UPROPERTY(EditDefaultsOnly)
	FName AlphaParameter = n"Opacity";

	UPROPERTY(EditDefaultsOnly)
	FLinearColor EmissiveColor = FLinearColor(10.0, 10.0, 10.0, 1.0);

	bool bIsEnabled = false;
	float Width = 0.2;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MID = Material::CreateDynamicMaterialInstance(this, Material);
		SetMaterial(0, MID);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		AcceleratedFloat.AccelerateTo((bIsEnabled ? 1.0 : 0.0), (bIsEnabled ? TransitionSpeed : TransitionSpeed * 0.5), DeltaSeconds);

		// @TODO: if its still visible below kinda_small_number size then we hide it instead.
		const float TargetRadius = Math::Max(AcceleratedFloat.Value * Width, KINDA_SMALL_NUMBER);
//		RelativeScale3D = FVector(TargetRadius, TargetRadius, RelativeScale3D.Z);;
		WorldScale3D = FVector(TargetRadius, TargetRadius, GetWorldScale().Z);;

		MID.SetVectorParameterValue(MaterialParameter, EmissiveColor * AcceleratedFloat.Value);
		MID.SetScalarParameterValue(AlphaParameter, AcceleratedFloat.Value * 0.5);
	}

	void Enable()
	{
		bIsEnabled = true;
	}

	void Disable()
	{
		bIsEnabled = false;
	}
};