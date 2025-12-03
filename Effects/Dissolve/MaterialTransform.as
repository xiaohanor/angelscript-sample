class AMaterialTransform : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;
	
	UPROPERTY(DefaultComponent)
	UMaterialTransformTickInEditor TickInEditorComponent;
	
	UPROPERTY(EditAnywhere, Interp)
	AStaticMeshActor Target;

	UPROPERTY(EditAnywhere, Interp)
	int MaterialIndex;

	UPROPERTY(EditAnywhere, Interp)
	int Index = 0;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		Update();
	}

	UFUNCTION()
	void TickInEdtor(float DeltaSeconds)
	{
		Update();
	}

	void Update()
	{
		if(Target == nullptr)
			return;

		if(Index == 0)
		{
			Target.StaticMeshComponent.SetVectorParameterValueOnMaterialIndex(MaterialIndex, n"MaterialTransform_Location", GetActorLocation());
			Target.StaticMeshComponent.SetVectorParameterValueOnMaterialIndex(MaterialIndex, n"MaterialTransform_Forward", GetActorForwardVector());
			Target.StaticMeshComponent.SetVectorParameterValueOnMaterialIndex(MaterialIndex, n"MaterialTransform_Right", GetActorRightVector());
			Target.StaticMeshComponent.SetVectorParameterValueOnMaterialIndex(MaterialIndex, n"MaterialTransform_Scale", GetActorScale3D());
		}
		else
		{
			Target.StaticMeshComponent.SetVectorParameterValueOnMaterialIndex(MaterialIndex, FName("MaterialTransform" + Index + "_Location"), GetActorLocation());
			Target.StaticMeshComponent.SetVectorParameterValueOnMaterialIndex(MaterialIndex, FName("MaterialTransform" + Index + "_Forward"), GetActorForwardVector());
			Target.StaticMeshComponent.SetVectorParameterValueOnMaterialIndex(MaterialIndex, FName("MaterialTransform" + Index + "_Right"), GetActorRightVector());
			Target.StaticMeshComponent.SetVectorParameterValueOnMaterialIndex(MaterialIndex, FName("MaterialTransform" + Index + "_Scale"), GetActorScale3D());
		}
	}
};

class UMaterialTransformTickInEditor : USceneComponent
{
	default bTickInEditor = true;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(Owner == nullptr)
			return;

		AMaterialTransform MaterialTransform =  Cast<AMaterialTransform>(Owner);

		if(MaterialTransform == nullptr)
			return;

		MaterialTransform.TickInEdtor(DeltaSeconds);
	}
}