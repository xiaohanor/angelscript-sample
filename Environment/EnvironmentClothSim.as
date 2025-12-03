UCLASS()
class UEnvironmentClothSimComponent : UStaticMeshComponent
{
	default bTickInEditor = true;
	default this.SetBoundsScale(BoundsScale);

	UPROPERTY(EditAnywhere)
	UMaterialInterface ClothMaterial;

	UPROPERTY(EditAnywhere)
	UMaterialInterface ClothSimMaterial;
	
	UPROPERTY(EditAnywhere)
	UMaterialInterface CopyTextureMaterial;

	UPROPERTY(EditAnywhere)
	UMaterialInterface CopyDataMaterial;
	
	UPROPERTY(EditAnywhere)
	float Gravity = -1;

	UPROPERTY(EditAnywhere)
	float WindStrength = 1;

	UPROPERTY(EditAnywhere)
	float CullDistanceMultiplier = 1;

	float PinningStrength = 1;

	UPROPERTY(EditAnywhere)
	float BoundsScale = 2;

	UPROPERTY(EditAnywhere)
	bool bCastShadow = false;

	UPROPERTY(EditAnywhere)
	bool bWindIsLocalSpace = false;

	int InitDelayCounter = 10;
	

#if EDITOR
	UPROPERTY(EditAnywhere, Transient)
	TWeakObjectPtr<UTextureRenderTarget2D> DebugPosition;
	UPROPERTY(EditAnywhere, Transient)
	TWeakObjectPtr<UTextureRenderTarget2D> DebugData0;
	UPROPERTY(EditAnywhere, Transient)
	TWeakObjectPtr<UTextureRenderTarget2D> DebugData1;
	UPROPERTY(EditAnywhere, Transient)
	TWeakObjectPtr<UTextureRenderTarget2D> DebugData2;
	UPROPERTY(EditAnywhere, Transient)
	TWeakObjectPtr<UTextureRenderTarget2D> DebugData3;

	UPROPERTY(EditAnywhere, Transient)
	TWeakObjectPtr<UMaterialInterface> DebugClothSimMaterialDynamic;

	UPROPERTY(EditAnywhere, Transient)
	TWeakObjectPtr<UMaterialInterface> DebugCopyDataMaterialDynamic;
#endif

	// These three variables are used by EnvironmentClothSimSingleton
	FVector LastPosition;
	float PlaneSizeX;

	UPROPERTY()
	float PlaneSizeY;

	UPROPERTY(VisibleAnywhere, Transient)
	int ClothIndex = -1;

	UPROPERTY()
	UMaterialInstanceDynamic MeshMaterialDynamic;

	bool bClothStateDirty = true;
	private bool bRegisteredToSubsytem = false;

	UFUNCTION(BlueprintOverride)
	void OnActorDisabled()
	{
		if (bRegisteredToSubsytem)
		{
			UEnvironmentClothSimSubsystem::Get().RemoveCloth(this);
			bRegisteredToSubsytem = false;
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnActorEnabled()
	{
		if (!bRegisteredToSubsytem)
			RegisterToSubsystem();
	}

	UFUNCTION()
	void SetCullingDistance()
	{
		float dist = Editor::GetDefaultCullingDistance(this) * CullDistanceMultiplier;
		this.SetCullDistance(dist);
	}
    
	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		if (bRegisteredToSubsytem)
			UEnvironmentClothSimSubsystem::Get().RemoveCloth(this);
		bRegisteredToSubsytem = false;
	}

	void MarkClothStateDirty()
	{
		bClothStateDirty = true;
	}
	
	UFUNCTION()
	void SetPinningStrength(float Strength)
	{
		if (Strength == PinningStrength)
			return;

		PinningStrength = Strength;
		bClothStateDirty = true;
		if(Strength == 0)
		{
			// set bounds scale to something huge
			SetBoundsScale(100.0);
		}
		else
		{
			SetBoundsScale(BoundsScale);
		}
	}
	
#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnComponentModifiedInEditor()
	{
		if(ClothSimMaterial == nullptr)
			ClothSimMaterial = Cast<UMaterialInterface>(LoadObject(nullptr, "/Game/MasterMaterials/Generated/Compute/Compute_EnvironmentClothSimGlobal_Inst.Compute_EnvironmentClothSimGlobal_Inst"));
		if(CopyTextureMaterial == nullptr)
			CopyTextureMaterial = Cast<UMaterialInterface>(LoadObject(nullptr, "/Game/MasterMaterials/Generated/Compute/Compute_CopyTexture2D.Compute_CopyTexture2D"));
		if(CopyDataMaterial == nullptr)
			CopyDataMaterial = Cast<UMaterialInterface>(LoadObject(nullptr, "/Game/MasterMaterials/Generated/Compute/Compute_EnvironmentClothSimCopyData.Compute_EnvironmentClothSimCopyData"));
		if(this.StaticMesh == nullptr)
			this.StaticMesh = Cast<UStaticMesh>(LoadObject(nullptr, "/Game/Environment/Blueprints/EnvironmentClothSim/Cloth.Cloth"));

		SetBoundsScale(BoundsScale);
		SetCastShadow(bCastShadow);
		SetCullingDistance();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		// BeginPlay doesn't run in editor worlds, so we need to register it here
		if (!bRegisteredToSubsytem && GetWorld().WorldType == EWorldType::Editor)
			RegisterToSubsystem();
	}
#endif

    UFUNCTION(BlueprintOverride)
	void BeginPlay()
    {
		InitDelayCounter = 10;
		if (!Owner.IsActorDisabled())
			RegisterToSubsystem();
		SetBoundsScale(BoundsScale);
		SetCastShadow(bCastShadow);
		SetCullingDistance();
		SceneComponent::BindOnSceneComponentMoved(this, FOnSceneComponentMoved(this, n"OnMoved"));
	}

	UFUNCTION()
	private void OnMoved(USceneComponent MovedComponent, bool bIsTeleport)
	{
		bClothStateDirty = true;
	}

	void RegisterToSubsystem()
	{
		UEnvironmentClothSimSubsystem SimulationSingleton = UEnvironmentClothSimSubsystem::Get();
		if (SimulationSingleton == nullptr)
			return;

		bRegisteredToSubsytem = true;

		if (ClothMaterial == nullptr)
			ClothMaterial = GetMaterial(0);
		if (MeshMaterialDynamic == nullptr || GetMaterial(0) != MeshMaterialDynamic)
			MeshMaterialDynamic = CreateDynamicMaterialInstance(0, ClothMaterial);
		if (MeshMaterialDynamic == nullptr)
			return;

		PlaneSizeX = GetWorldScale().X * 100;
		PlaneSizeY = GetWorldScale().Z * 100;
		bClothStateDirty = true;
		InitDelayCounter = 10;

		SimulationSingleton.AddCloth(this);

		MeshMaterialDynamic.SetTextureParameterValue(n"PositionsGlobal", UEnvironmentClothSimSubsystem::Get().CurrentPosition);
		MeshMaterialDynamic.SetTextureParameterValue(n"PinningMaskGlobal", UEnvironmentClothSimSubsystem::Get().PinningMask);
	}

	void UpdateClothIndex(int NewClothIndex)
	{
		ClothIndex = NewClothIndex;
		bClothStateDirty = true;

		UEnvironmentClothSimSubsystem SimulationSingleton = UEnvironmentClothSimSubsystem::Get();
		int x = ClothIndex % SimulationSingleton.ClothCountSideLength;
		int y = Math::IntegerDivisionTrunc(ClothIndex, SimulationSingleton.ClothCountSideLength);
		MeshMaterialDynamic.SetVectorParameterValue(n"transform", FLinearColor(x, y, x + 1, y + 1) / float(SimulationSingleton.ClothCountSideLength));
	}

	UFUNCTION(BlueprintCallable)
	void SetNewClothMaterial(UMaterialInterface NewMaterialInterface)
	{
		ClothMaterial = NewMaterialInterface;
		MeshMaterialDynamic = this.CreateDynamicMaterialInstance(0, NewMaterialInterface);

		UEnvironmentClothSimSubsystem SimulationSingleton = UEnvironmentClothSimSubsystem::Get();
		UpdateClothIndex(ClothIndex);

		MeshMaterialDynamic.SetTextureParameterValue(n"PositionsGlobal", UEnvironmentClothSimSubsystem::Get().CurrentPosition);
		MeshMaterialDynamic.SetTextureParameterValue(n"PinningMaskGlobal", UEnvironmentClothSimSubsystem::Get().PinningMask);
	}
}