
class UDataAssetGodray : UDataAsset
{
    UPROPERTY()
	EGodrayType Type;

	UPROPERTY()
	FLinearColor Color = FLinearColor(0.442708, 0.363321, 0.175, 1);

    UPROPERTY()
    float CloseFadeDistance = 2000.0;

    UPROPERTY()
    float AngleFade = 1.0;

    UPROPERTY()
    float WorldClipHeight = 300000.0;

    UPROPERTY()
    bool bTwoSided = false;
	
	UPROPERTY(Category="Procedual")
    float Tiling = 4;

    UPROPERTY(Category="Procedual")
    float Speed = 0.5;

    UPROPERTY(Category="Procedual", Meta = (EditCondition="Type == EGodrayType::Procedual2", EditConditionHides))
    float Angle = 0.2;

    UPROPERTY(Category="Procedual")
    float GlowStrength = 0.025;

	UPROPERTY(Meta = (EditCondition="Type == EGodrayType::Texture", EditConditionHides))
	UTexture2D Texture;
}

enum EGodrayType
{
    Texture,
    Procedual1,
    Procedual2
};

enum EGodrayRotationType
{
    Godray,
    Billboard,
	Plane,
};

UCLASS(Abstract, hidecategories="StaticMesh Physics Collision Lighting Physics Activation Cooking Replication Input Actor HLOD Mobile AssetUserData")
class AGodray : AHazeActor
{
    UPROPERTY(DefaultComponent, RootComponent, ShowOnActor)
    UGodrayComponent Component;

    UPROPERTY(DefaultComponent)
    UBillboardComponent Billboard;
	default Billboard.bIsEditorOnly = true;
#if EDITOR
	default Billboard.bUseInEditorScaling = true;
#endif
	
    UFUNCTION(BlueprintOverride)
    void ConstructionScript()
    {
		Component.ConstructionScript_Hack();
    }
}

UCLASS(hidecategories="StaticMesh Physics Collision Lighting Physics Activation Cooking Replication Input Actor HLOD Mobile AssetUserData")
class UGodrayComponent : UStaticMeshComponent
{
	access EditOnly = private, * (editdefaults, readonly);

	default bCastDynamicShadow = false;
	default bCanEverAffectNavigation = false;
	default CollisionProfileName = n"NoCollision";

	UPROPERTY()
	access:EditOnly
	UMaterialInterface GodrayTexture;
	UPROPERTY()
	access:EditOnly
	UMaterialInterface GodrayProcedual1;
	UPROPERTY()
	access:EditOnly
	UMaterialInterface GodrayProcedual2;
	UPROPERTY()
	access:EditOnly
	UMaterialInterface TwoSidedGodrayTexture;
	UPROPERTY()
	access:EditOnly
	UMaterialInterface TwoSidedGodrayProcedual1;
	UPROPERTY()
	access:EditOnly
	UMaterialInterface TwoSidedGodrayProcedual2;
	
    UPROPERTY()
	access:EditOnly
    UMaterialInstanceDynamic GodrayMaterialInstanceDynamic;

    UPROPERTY()
	access:EditOnly
	UStaticMesh Mesh;

	UPROPERTY(EditAnywhere)
	access:EditOnly
	UDataAssetGodray Template;

	UPROPERTY(EditAnywhere)
	access:EditOnly
	float Opacity = 1.0;
	
	UPROPERTY(EditAnywhere)
	access:EditOnly
	EGodrayRotationType Rotation;

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnComponentModifiedInEditor()
	{
		if(Template != nullptr)
		{
			Template.OnAssetChanged.Clear();
			Template.OnAssetChanged.AddUFunction(this, n"UpdateDynamicMaterialInstance");
		}
		EditorInit();
		UpdateDynamicMaterialInstance();
	}

	UFUNCTION(BlueprintOverride)
	private void OnActorOwnerModifiedInEditor()
	{
		if(Template != nullptr)
		{
			Template.OnAssetChanged.Clear();
			Template.OnAssetChanged.AddUFunction(this, n"UpdateDynamicMaterialInstance");
		}
		EditorInit();
		UpdateDynamicMaterialInstance();
	}

	UFUNCTION(BlueprintOverride)
	void OnComponentCompiledInBlueprint()
	{
		EditorInit();
	}

	UFUNCTION()
	void EditorInit()
	{
		Mesh = Cast<UStaticMesh>(Editor::LoadAsset(n"/Game/Environment/Blueprints/Godray/GodrayCard.GodrayCard"));
		GodrayTexture = Cast<UMaterialInterface>(Editor::LoadAsset(n"/Game/MasterMaterials/Generated/Effect/Effect_Godray.Effect_Godray"));
		GodrayProcedual1 = Cast<UMaterialInterface>(Editor::LoadAsset(n"/Game/MasterMaterials/Generated/Effect/Effect_GodrayProcedural1.Effect_GodrayProcedural1"));
		GodrayProcedual2 = Cast<UMaterialInterface>(Editor::LoadAsset(n"/Game/MasterMaterials/Generated/Effect/Effect_GodrayProcedural2.Effect_GodrayProcedural2"));
		TwoSidedGodrayTexture = Cast<UMaterialInterface>(Editor::LoadAsset(n"/Game/MasterMaterials/Generated/Effect/Effect_Godray_TwoSided.Effect_Godray_TwoSided"));
		TwoSidedGodrayProcedual1 = Cast<UMaterialInterface>(Editor::LoadAsset(n"/Game/MasterMaterials/Generated/Effect/Effect_GodrayProcedural1_TwoSided.Effect_GodrayProcedural1_TwoSided"));
		TwoSidedGodrayProcedual2 = Cast<UMaterialInterface>(Editor::LoadAsset(n"/Game/MasterMaterials/Generated/Effect/Effect_GodrayProcedural2_TwoSided.Effect_GodrayProcedural2_TwoSided"));
		
		SetStaticMesh(Mesh);
	}
#endif

	UMaterialInterface GetBaseMaterial() const
	{
		if (Template == nullptr)
			return nullptr;
		else if (Template.Type == EGodrayType::Texture)
			return Template.bTwoSided ? TwoSidedGodrayTexture : GodrayTexture;
		else if(Template.Type == EGodrayType::Procedual1)
			return Template.bTwoSided ? TwoSidedGodrayProcedual1 : GodrayProcedual1;
		else if(Template.Type == EGodrayType::Procedual2)
			return Template.bTwoSided ? TwoSidedGodrayProcedual2 : GodrayProcedual2;
		else
			return nullptr;
	}

	UFUNCTION()
	void UpdateDynamicMaterialInstance()
	{
		if(Template == nullptr)
			return;

		if (StaticMesh == nullptr)
			return;

		if (GodrayMaterialInstanceDynamic == nullptr || GodrayMaterialInstanceDynamic.Parent != GetBaseMaterial())
			GodrayMaterialInstanceDynamic = CreateDynamicMaterialInstance(0, GetBaseMaterial(), n"GodrayDynamicMaterial");

		if (GodrayMaterialInstanceDynamic == nullptr)
			return;

		SetMaterial(0, GodrayMaterialInstanceDynamic);
		GodrayMaterialInstanceDynamic.SetVectorParameterValue(n"Tint", Template.Color * Opacity);
		GodrayMaterialInstanceDynamic.SetTextureParameterValue(n"Texture", Template.Texture);
		
		GodrayMaterialInstanceDynamic.SetScalarParameterValue(n"Tiling", Template.Tiling);
		GodrayMaterialInstanceDynamic.SetScalarParameterValue(n"Speed", Template.Speed);

        FVector Scale = GetWorldScale();
        float MaxScale = Math::Max(Scale.X, Math::Max(Scale.Y, Scale.Z));
		GodrayMaterialInstanceDynamic.SetScalarParameterValue(n"Scale", MaxScale * 10);

		GodrayMaterialInstanceDynamic.SetScalarParameterValue(n"CloseFadeDistance", Template.CloseFadeDistance);
		GodrayMaterialInstanceDynamic.SetScalarParameterValue(n"WorldClipHeight", Template.WorldClipHeight);
		
		GodrayMaterialInstanceDynamic.SetScalarParameterValue(n"Angle", Template.Angle);
		GodrayMaterialInstanceDynamic.SetScalarParameterValue(n"AngleFade", Template.AngleFade);
		GodrayMaterialInstanceDynamic.SetScalarParameterValue(n"GlowStrength", Template.GlowStrength);
		
		GodrayMaterialInstanceDynamic.SetScalarParameterValue(n"Rotation", float(Rotation));
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		UpdateDynamicMaterialInstance();
		if (GodrayMaterialInstanceDynamic == nullptr && Template != nullptr)
			devError("Godray materials are configured incorrectly");

		this.SetCastShadow(false);
	}

	/* Update the dynamic mat when the Godray is loaded in the level at least once
		because it is dependent on a DataAsset which might have changed */
	bool Loaded = false;
	
    UFUNCTION()
    void ConstructionScript_Hack()
    {
		#if EDITOR
		
		if(Template != nullptr)
		{
			Template.OnAssetChanged.Clear();
			Template.OnAssetChanged.AddUFunction(this, n"UpdateDynamicMaterialInstance");
		}
		EditorInit();
		this.SetCastShadow(false);
		#endif
    }

	void SetGodrayOpacity(float GodrayOpacity)
	{
		if (IsValid(GodrayMaterialInstanceDynamic))
			GodrayMaterialInstanceDynamic.SetVectorParameterValue(n"Tint", Template.Color * GodrayOpacity);
	}
}
