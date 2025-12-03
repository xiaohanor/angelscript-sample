UCLASS(Abstract)
class ADentistDancingLollipop : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, ShowOnActor)
	UDentistDancingComponent DancingRoot;

	UPROPERTY(DefaultComponent, Attach = "DancingRoot")
	UStaticMeshComponent MeshComp;

	UPROPERTY(EditDefaultsOnly)
	TArray<UMaterialInterface> Materials;

	UPROPERTY(EditAnywhere)
	int MaterialIndex = 0;

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnActorPlacedInEditor()
	{
		MaterialIndex = Math::RandRange(0, Materials.Num() - 1);
	}

	UFUNCTION(BlueprintOverride)
	void OnActorModifiedInEditor()
	{
		SetMaterialIndex(MaterialIndex);
	}
#endif

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}

	void SetMaterialIndex(int Index)
	{
		if(!Materials.IsValidIndex(MaterialIndex))
		{
			MaterialIndex = Math::Clamp(Index, 0, Materials.Num() - 1);
			return;
		}

		MaterialIndex = Index;

		MeshComp.SetMaterial(0, Materials[MaterialIndex]);
	}
};