
//UCLASS(Abstract, hidecategories="StaticMesh Physics Collision Lighting Physics Activation Cooking Replication Input Actor HLOD Mobile AssetUserData")
class AParallaxRoomCapture : AHazeActor
{
	default bIsEditorOnlyActor = true;

#if EDITOR
    UPROPERTY(DefaultComponent)
    UBillboardComponent Billboard;
	default Billboard.bIsEditorOnly = true;
	default Billboard.bUseInEditorScaling = true;

    UPROPERTY(DefaultComponent)
	USceneCaptureComponentCube CaptureComp;

    //UPROPERTY(EditAnywhere)
	//UTextureCube TextureToConvert;

    UPROPERTY(EditAnywhere)
	TSoftObjectPtr<UTexture2D> Result;

    UPROPERTY()
	TSoftObjectPtr<UTextureRenderTarget2D> TargetTexture;

    UPROPERTY(EditAnywhere)
	float Exposure = 1;

    UPROPERTY()
	TSoftObjectPtr<UTextureRenderTargetCube> IntermediateTargetTexture;

    UPROPERTY()
	TSoftObjectPtr<UMaterialInterface> ConvertMaterial;

    UFUNCTION(BlueprintOverride)
    void ConstructionScript()
    {
		CaptureComp.bCaptureEveryFrame = false;
		CaptureComp.bCaptureOnMovement = false;

		//// Capture scene
		//CaptureComp.TextureTarget = IntermediateTargetTexture;
		//CaptureComp.CaptureScene();
//
		//// Transfer capture to final texture
		//if(ConvertMaterialDynamic == nullptr)
		//	ConvertMaterialDynamic = Material::CreateDynamicMaterialInstance(this, ConvertMaterial);
		//
		//ConvertMaterialDynamic.SetScalarParameterValue(n"Exposure", Exposure);
		//ConvertMaterialDynamic.SetTextureParameterValue(n"InputTexture", IntermediateTargetTexture);
		//Rendering::DrawMaterialToRenderTarget(TargetTexture, ConvertMaterialDynamic);
    }

	UFUNCTION(CallInEditor)
	void Capture()
	{
		// Capture scene
		CaptureComp.TextureTarget = IntermediateTargetTexture.EditorOnlyLoadSynchronous();
		CaptureComp.CaptureScene();

		// Transfer capture to final texture
		UMaterialInstanceDynamic ConvertMaterialDynamic;
		ConvertMaterialDynamic = Material::CreateDynamicMaterialInstance(this, ConvertMaterial.EditorOnlyLoadSynchronous());
		
		ConvertMaterialDynamic.SetScalarParameterValue(n"Exposure", Exposure);
		ConvertMaterialDynamic.SetTextureParameterValue(n"InputTexture", IntermediateTargetTexture.EditorOnlyLoadSynchronous());
		ConvertMaterialDynamic.SetVectorParameterValue(n"X", FLinearColor(-GetActorUpVector()));
		ConvertMaterialDynamic.SetVectorParameterValue(n"Y", FLinearColor(GetActorForwardVector()));
		ConvertMaterialDynamic.SetVectorParameterValue(n"Z", FLinearColor(-GetActorRightVector()));
		Rendering::DrawMaterialToRenderTarget(TargetTexture.EditorOnlyLoadSynchronous(), ConvertMaterialDynamic);

		//// Transfer capture to final texture
		//if(ConvertMaterialDynamic == nullptr)
		//	ConvertMaterialDynamic = Material::CreateDynamicMaterialInstance(this, ConvertMaterial);
		//
		//ConvertMaterialDynamic.SetTextureParameterValue(n"InputTexture", IntermediateTargetTexture);
		//Rendering::DrawMaterialToRenderTarget(TargetTexture, ConvertMaterialDynamic);
		
		//Editor::MessageDialog(EAppMsgType::Ok, FText::FromString("wopah"));
		
		//FString AssetPath = f"/Game/Environment/Prefabs/MergedMeshes/TestTexture";
		Result = Rendering::RenderTargetCreateStaticTexture2DEditorOnly(TargetTexture.EditorOnlyLoadSynchronous(), "Room Capture");
		Result = Cast<UTexture2D>(Editor::SaveAssetAsNewPath(Result.EditorOnlyLoadSynchronous()));
		
		//AssetTools::CreateAsset()
		//AssetRegistry::AssetCreated();
		
		TArray<UObject> Objects;
		Objects.Add(Result.EditorOnlyLoadSynchronous());
		Editor::SyncContentBrowserToAssets(Objects);
	}
#endif
}