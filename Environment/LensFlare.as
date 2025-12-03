
class UDataAssetLensFlare : UDataAsset
{
    UPROPERTY()
    UTexture2D Texture;

    UPROPERTY()
    float Scale = 1000;

    UPROPERTY()
    FLinearColor Tint = FLinearColor(1, 1, 1, 1);

    UPROPERTY()
    bool ChromaHoop = false;

    UPROPERTY()
    float ChromaHoopOpacity = 1;
}

UCLASS(Abstract)
class ALensFlare : AHazeActor
{
    UPROPERTY(DefaultComponent, RootComponent)
    USceneComponent Root;
	default Root.bVisualizeComponent = true;

    UPROPERTY(DefaultComponent)
    UStaticMeshComponent Flare;
    default Flare.CollisionProfileName = n"NoCollision";
	default Flare.CastShadow = false;

    UPROPERTY(DefaultComponent)
    UStaticMeshComponent Hoop;
    default Hoop.CollisionProfileName = n"NoCollision";
	default Hoop.CastShadow = false;

	UPROPERTY(DefaultComponent, Attach = Root, BlueprintHidden, NotEditable)
	UArrowComponent Arrow;

    UPROPERTY(EditAnywhere)
    UDataAssetLensFlare Preset;// = Asset("/Game/Blueprints/Environment/LensFlare/DA_Flare_Simple.DA_Flare_Simple");

	UPROPERTY(EditAnywhere)
    bool Omnidirectional = true;

	UPROPERTY(EditAnywhere)
    float FadeDistance = 1.0;

	UPROPERTY(EditAnywhere)
    bool bScaleWithDistance = false;

	UPROPERTY(EditAnywhere)
    bool bDebug = false;

	UPROPERTY()
    UStaticMesh FlareMesh;// = Asset("/Game/Blueprints/Environment/LensFlare/Flare_Mesh.Flare_Mesh");
	UPROPERTY()
    UStaticMesh HoopMesh;// = Asset("/Game/Blueprints/Environment/LensFlare/Flare_HoopMesh.Flare_HoopMesh");

	UPROPERTY()
    UMaterial FlareMaterial;// = Asset("/Game/Blueprints/Environment/LensFlare/LensFlareMaterial.LensFlareMaterial");
	UPROPERTY()
    UTexture2D HoopTexture;// = Asset("/Game/Blueprints/Environment/LensFlare/Flare_Hoop.Flare_Hoop");

    UPROPERTY(EditAnywhere)
    UMaterialInstanceDynamic HoopMaterialDynamic;
    UPROPERTY(EditAnywhere)
    UMaterialInstanceDynamic FlareMaterialDynamic;

    UFUNCTION()
	void SetTint(FLinearColor Tint)
	{
        FlareMaterialDynamic.SetVectorParameterValue(n"Tint", Tint);
	}


    UFUNCTION(BlueprintOverride)
    void ConstructionScript()
    {
		if(Preset == nullptr)
			return;
        FVector ForwardVector = GetActorRotation().GetForwardVector();
		float AverageScale = (GetActorScale3D().X + GetActorScale3D().Y + GetActorScale3D().Z) / 3.0;
		SetActorScale3D(FVector(AverageScale,AverageScale,AverageScale));

        FlareMaterialDynamic = Material::CreateDynamicMaterialInstance(this, FlareMaterial);
        Flare.SetStaticMesh(FlareMesh);
        Flare.SetMaterial(0, FlareMaterialDynamic);
        FlareMaterialDynamic.SetTextureParameterValue(n"TexFlare", Preset.Texture);
        FlareMaterialDynamic.SetScalarParameterValue(n"Scale", Preset.Scale * 0.01 * AverageScale);
        FlareMaterialDynamic.SetScalarParameterValue(n"bScaleWithDistance", bScaleWithDistance ? 1 : 0);

        FlareMaterialDynamic.SetScalarParameterValue(n"HazeToggle_Omnidirectional", Omnidirectional ? 1 : 0);
        FlareMaterialDynamic.SetVectorParameterValue(n"Tint", Preset.Tint);
        FlareMaterialDynamic.SetVectorParameterValue(n"BlueprintForward", FLinearColor(ForwardVector.X, ForwardVector.Y, ForwardVector.Z, 0));
        //Flare.SetWorldRotation(FRotator(0, 0, 0));

		float fadeDist = FadeDistance * Preset.Scale * GetActorScale3D().X * 10;
		FlareMaterialDynamic.SetScalarParameterValue(n"MaxDrawDistance", fadeDist);
		FlareMaterialDynamic.SetScalarParameterValue(n"MaxDrawDistanceFadeRange", fadeDist);
		FlareMaterialDynamic.SetScalarParameterValue(n"HazeToggle_Debug", bDebug ? 1 : 0);
		
		Flare.SetCullDistance(fadeDist);
		Hoop.SetCullDistance(fadeDist);

        Hoop.SetVisibility(Preset.ChromaHoop);
        if(Preset.ChromaHoop)
        {
            HoopMaterialDynamic = Material::CreateDynamicMaterialInstance(this, FlareMaterial);
            Hoop.SetStaticMesh(HoopMesh);
            Hoop.SetMaterial(0, HoopMaterialDynamic);
            HoopMaterialDynamic.SetTextureParameterValue(n"TexFlare", HoopTexture);
            HoopMaterialDynamic.SetScalarParameterValue(n"HazeToggle_IsHoop", 1.0);
        	HoopMaterialDynamic.SetVectorParameterValue(n"Tint", FLinearColor(Preset.ChromaHoopOpacity,Preset.ChromaHoopOpacity,Preset.ChromaHoopOpacity,Preset.ChromaHoopOpacity));
			
            HoopMaterialDynamic.SetVectorParameterValue(n"BlueprintForward", FLinearColor(ForwardVector.X, ForwardVector.Y, ForwardVector.Z, 0));
        	HoopMaterialDynamic.SetScalarParameterValue(n"HazeToggle_Omnidirectional", Omnidirectional ? 1 : 0);
        	//Hoop.SetWorldRotation(FRotator(0, 0, 0));
			HoopMaterialDynamic.SetScalarParameterValue(n"MaxDrawDistance", fadeDist);
			HoopMaterialDynamic.SetScalarParameterValue(n"MaxDrawDistanceFadeRange", fadeDist);
			HoopMaterialDynamic.SetScalarParameterValue(n"HazeToggle_Debug", bDebug ? 1 : 0);
        }
    }
    
    UFUNCTION(BlueprintOverride)
	void BeginPlay()
    {

    }

    UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
    {

    }
}