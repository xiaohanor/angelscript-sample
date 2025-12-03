class AAbyssPath : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = Root)
	UEditorBillboardComponent VisualComp;
	default VisualComp.SetWorldScale3D(FVector(5));
	default VisualComp.SpriteName = "S_TriggerBox";
#endif

	UPROPERTY(EditInstanceOnly)
	APropLine PathPropLine;

	UPROPERTY(EditInstanceOnly)
	AAcidStatue AcidStatue;

	UPROPERTY(EditDefaultsOnly)
	FLinearColor TargetColor;
	FLinearColor OriginalColor;
	FLinearColor OriginalPreviewColor;

	TArray<UMaterialInstanceDynamic> DynamicMaterials;
	bool bAbyssPathOn;

	float TimeActive;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		PathPropLine.AddActorDisable(this);
		PathPropLine.AddActorCollisionBlock(this);
		AcidStatue.OnCraftTempleAcidStatueActivated.AddUFunction(this, n"OnCraftTempleAcidStatueActivated");
		AcidStatue.OnCraftTempleAcidStatueDeactivated.AddUFunction(this, n"OnCraftTempleAcidStatueDeactivated");
		TArray<UStaticMeshComponent> MeshCompArray;
		PathPropLine.GetComponentsByClass(MeshCompArray);

		for (UStaticMeshComponent MeshComp : MeshCompArray)
		{
			UMaterialInstanceDynamic Mat = Material::CreateDynamicMaterialInstance(this, MeshComp.GetMaterial(0));
			MeshComp.SetMaterial(0, Mat);
			DynamicMaterials.Add(Mat);
			OriginalColor = Mat.GetVectorParameterValue(n"Color");
			OriginalPreviewColor = Mat.GetVectorParameterValue(n"Preview_Color");
		}

		SetActorTickEnabled(false);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		TimeActive += DeltaSeconds;
		float Alpha = Math::Saturate(TimeActive / AcidStatue.Duration);
		FLinearColor Color = Math::Lerp(OriginalColor, TargetColor, Alpha);
		FLinearColor PreviewColor = Math::Lerp(OriginalPreviewColor, TargetColor, Alpha);

		for (UMaterialInstanceDynamic& Mat : DynamicMaterials)
		{
			Mat.SetVectorParameterValue(n"Color", Color);
			Mat.SetVectorParameterValue(n"Preview_Color", PreviewColor);
		}
	}

	UFUNCTION()
	private void OnCraftTempleAcidStatueActivated()
	{
		TimeActive = 0.0;
		bAbyssPathOn = true;
		PathPropLine.RemoveActorDisable(this);
		PathPropLine.RemoveActorCollisionBlock(this);
		SetActorTickEnabled(true);
	}

	UFUNCTION()
	private void OnCraftTempleAcidStatueDeactivated()
	{
		bAbyssPathOn = false;
		PathPropLine.AddActorDisable(this);
		PathPropLine.AddActorCollisionBlock(this);
		SetActorTickEnabled(false);
	}
};