class AMeltdownWorldSpinChasePlanes : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;
	
	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComponent;

	UPROPERTY(EditAnywhere)
	UMaterialInterface PostProcessMaterial;
	UMaterialInstanceDynamic PostProcessMaterialDynamic;

	UPROPERTY(DefaultComponent)
	UPostProcessComponent PostProcessComponent;
	default PostProcessComponent.bUnbound = true;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		PostProcessMaterialDynamic = Material::CreateDynamicMaterialInstance(this, PostProcessMaterial);
		if(PostProcessMaterialDynamic != nullptr)
		{
			FPostProcessSettings PPSettings;
			FWeightedBlendable WeightedBlendable;
			WeightedBlendable.Object = PostProcessMaterialDynamic;
			WeightedBlendable.Weight = 1.0;
			PostProcessComponent.Settings.WeightedBlendables.Array.Empty();
			PostProcessComponent.Settings.WeightedBlendables.Array.Add(WeightedBlendable);
		}
	}

	UFUNCTION(BlueprintCallable)
	void SetEffectEnabled()
	{
		AddActorDisable(this);
	}
	
	//UFUNCTION(BlueprintOverride)
	//void Tick(float DeltaSeconds)
	//{
	//	
	//}

	void SetPlane(int index, FVector EdgeLocation, FVector EdgeDirection, float InAnimationTime = 1)
	{
		float Radius = 100000;

		if(index == 0)
		{
			PostProcessMaterialDynamic.SetScalarParameterValue(n"whitespaceData_Radius", Radius - InAnimationTime * 3000);
			PostProcessMaterialDynamic.SetVectorParameterValue(n"whitespaceData_Center", FLinearColor(EdgeLocation - EdgeDirection * Radius));
		}
		else if(index == 1)
		{
			PostProcessMaterialDynamic.SetScalarParameterValue(n"whitespaceData_Radius2", Radius - InAnimationTime * 3000);
			PostProcessMaterialDynamic.SetVectorParameterValue(n"whitespaceData_Center2", FLinearColor(EdgeLocation - EdgeDirection * Radius));
		}
	}
};