struct FSoftSplitMeshData
{
	UPROPERTY(EditAnywhere, Meta = (UseComponentPicker, AllowedClasses = "/Script/Engine.PrimitiveComponent"))
	FComponentReference Component;
	UPROPERTY(EditAnywhere)
	FName SplitName;
}

class USoftSplitMeshRenderingComponent : UActorComponent
{
	UPROPERTY(EditAnywhere)
	TArray<FSoftSplitMeshData> Meshes;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TryRegister();
	}

	void TryRegister()
	{
		/*auto Manager = ASoftSplitManager::GetSoftSplitManger();
		if (Manager == nullptr)
		{
			SetComponentTickEnabled(true);
			return;
		}

		for (auto MeshData : Meshes)
		{
			auto Component = Cast<UPrimitiveComponent>(MeshData.Component.GetComponent(Owner));
			if (Component == nullptr)
				continue;
			Manager.SplitRenderComp.AddComponentToSplit(Component, MeshData.SplitName);
		}*/

		SetComponentTickEnabled(false);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		TryRegister();
	}
}