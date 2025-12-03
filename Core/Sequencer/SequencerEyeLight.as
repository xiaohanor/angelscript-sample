
UCLASS(Abstract, HideCategories = "Rendering Debug Activation Cooking Actor Tags LOD Collision")
class ASequencerEyeLight : AActor 
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;
	
	UPROPERTY(DefaultComponent, ShowOnActor)
	USequencerEyeLightComponent SequencerEyeLight;
	
	UPROPERTY(EditAnywhere)
	UMaterial Char_Eye;
	
	UPROPERTY(EditAnywhere, Interp)
	FLinearColor Color = FLinearColor(1,1,1,1);
	
	UPROPERTY(EditAnywhere, Interp)
	float Roughness = 0.5;

	UPROPERTY(EditAnywhere, Interp)
	float Brightness = 1.0;
	
	UPROPERTY(EditAnywhere, Interp)
	float AttenuationRadius = 1000.0;
	
	UPROPERTY(EditAnywhere, Interp)
	AActor Target0;

	UPROPERTY(EditAnywhere, Interp)
	AActor Target1;
	
	void TickInEditor()
	{
		SetMeshParameters(Target0);
		SetMeshParameters(Target1);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		SetMeshParameters(Target0);
		SetMeshParameters(Target1);
	}

	void SetMeshParameters(AActor Target)
	{
		if(Target == nullptr)
			return;
		
		USkinnedMeshComponent SkinnedMeshComponent = Target.GetComponentByClass(USkinnedMeshComponent);

		if(SkinnedMeshComponent == nullptr)
			return;

		for (int i = 0; i < SkinnedMeshComponent.Materials.Num(); i++)
		{
			if(SkinnedMeshComponent.Materials[i] == nullptr)
				continue;

			auto BaseMaterial = SkinnedMeshComponent.GetMaterial(i).BaseMaterial;
			if(BaseMaterial == Char_Eye)
			{
				SkinnedMeshComponent.SetScalarParameterValueOnMaterialIndex(i, n"FakeLight_AttenuationRadius", AttenuationRadius);
				SkinnedMeshComponent.SetScalarParameterValueOnMaterialIndex(i, n"FakeLight_Brightness", Brightness);
				SkinnedMeshComponent.SetScalarParameterValueOnMaterialIndex(i, n"FakeLight_Roughness", Roughness);
				SkinnedMeshComponent.SetColorParameterValueOnMaterialIndex(i, n"FakeLight_Color", Color);
				SkinnedMeshComponent.SetColorParameterValueOnMaterialIndex(i, n"FakeLight_Location", FLinearColor(GetActorLocation()));
				
			}
		}
	}
}

class USequencerEyeLightComponent : USceneComponent
{
	default bTickInEditor = true;
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		Cast<ASequencerEyeLight>(Owner).TickInEditor();
	}
};

