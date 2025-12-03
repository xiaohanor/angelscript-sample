struct FAcidPuddleParams
{
	TSubclassOf<AAcidPuddle> PuddleClass;
	FVector Location;
	FVector PuddleNormal;
	float Radius;
	float Duration;
};

enum EAcidPuddleType
{
	OnFloor,
	OnWall
};

 UCLASS(Abstract)
class AAcidPuddle : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UHazeDecalComponent Decal;
	default Decal.RelativeRotation = FRotator(90.0, 0.0, 0.0);

	UPROPERTY()
	FName DecalMaterialLifetimeParam;
	UPROPERTY()
	float DecalMaterialLifetimeMinValue = 0.0;
	UPROPERTY()
	float DecalMaterialLifetimeMaxValue = 1.0;

	EAcidPuddleType PuddleType;
	FAcidPuddleParams PuddleParams;
	UAcidManagerComponent AcidManager;
	bool bStartedFading = false;
	float LifeTimer = 0.0;
	int AcidAreaId = -1;
	UMaterialInstanceDynamic DynamicMaterial;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SceneComponent::BindOnSceneComponentMoved(RootComponent, FOnSceneComponentMoved(this, n"OnMoved"));
		DynamicMaterial = Decal.CreateDynamicMaterialInstance();
	}

	UFUNCTION(BlueprintPure)
	float GetLifetimePercentage() const
	{
		return LifeTimer / PuddleParams.Duration;
	}

	UFUNCTION()
	private void OnMoved(USceneComponent MovedComponent, bool bIsTeleport)
	{
		if (AcidAreaId != -1)
		{
			auto Manager = Acid::GetAcidManager();
			Manager.RemovePuddleFromArea(this);
			Manager.AddPuddleToArea(this);
		}
	}

	void Init(FAcidPuddleParams Params)
	{
		bStartedFading = false;
		PuddleParams = Params;
		LifeTimer = 0.0;

		Decal.SetFadeOut(0.0, 0.0, false);
		Decal.ResetFade();

		if (Params.PuddleNormal.DotProduct(FVector::UpVector) >= 0.5)
			PuddleType = EAcidPuddleType::OnFloor;
		else
			PuddleType = EAcidPuddleType::OnWall;

		FRotator Rotation = FRotator::MakeFromZ(Params.PuddleNormal);
		Rotation.Yaw = Math::RandRange(0.0, 360.0);

		SetActorLocationAndRotation(
			Params.Location,
			Rotation,
		);
		Decal.SetWorldScale3D(FVector(Params.Radius / 100.0));

		if (DecalMaterialLifetimeParam != NAME_None && DynamicMaterial != nullptr)
		{
			DynamicMaterial.SetScalarParameterValue(
				DecalMaterialLifetimeParam,
				Math::Lerp(DecalMaterialLifetimeMinValue, DecalMaterialLifetimeMaxValue, GetLifetimePercentage()),
			);
			DynamicMaterial.SetVectorParameterValue(n"Forward", FLinearColor(Rotation.ForwardVector));
			DynamicMaterial.SetVectorParameterValue(n"Up", FLinearColor(Rotation.UpVector));
			DynamicMaterial.SetVectorParameterValue(n"Right", FLinearColor(Rotation.RightVector));
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		LifeTimer += DeltaSeconds;

		if (LifeTimer > PuddleParams.Duration - 0.5)
		{
			if (!bStartedFading)
			{
				Decal.SetFadeOut(0.0, 0.5, false);
				bStartedFading = true;
			}

			if (LifeTimer > PuddleParams.Duration)
				AcidManager.ReturnToPool(this);
		}

		if (DecalMaterialLifetimeParam != NAME_None && DynamicMaterial != nullptr)
		{
			DynamicMaterial.SetScalarParameterValue(
				DecalMaterialLifetimeParam,
				Math::Lerp(DecalMaterialLifetimeMinValue, DecalMaterialLifetimeMaxValue, GetLifetimePercentage()),
			);
		}
	}
};