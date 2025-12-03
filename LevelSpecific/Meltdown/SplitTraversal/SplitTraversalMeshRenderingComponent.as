struct FSplitTraversalMeshData
{
	UPROPERTY(EditAnywhere, Meta = (UseComponentPicker, AllowedClasses = "/Script/Engine.SceneComponent"))
	FComponentReference Component;
	UPROPERTY(EditAnywhere)
	FName SplitName;

	USceneComponent ComponentRef;
	FTransform RelativeTransform;
}

class USplitTraversalMeshRenderingComponent : UActorComponent
{
	default PrimaryComponentTick.TickGroup = ETickingGroup::TG_PostPhysics;

	UPROPERTY(EditAnywhere)
	TArray<FSplitTraversalMeshData> Meshes;

	ASplitTraversalManager Manager;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}

	UFUNCTION()
	void MoveComponentToScifiOffsetInEditor(USceneComponent Component)
	{
		FVector WorldLocation = Component.AttachParent.WorldLocation + FVector(500000.0, 0.0, 0.0);
		Component.RelativeLocation = Component.AttachParent.WorldTransform.InverseTransformPosition(WorldLocation);
	}

	void TryRegister()
	{
		Manager = ASplitTraversalManager::GetSplitTraversalManager();
		if (Manager == nullptr)
			return;

		for (FSplitTraversalMeshData& MeshData : Meshes)
		{
			auto Component = Cast<USceneComponent>(MeshData.Component.GetComponent(Owner));
			if (Component == nullptr)
				continue;
			if (MeshData.SplitName != n"Scifi")
				continue;

			MeshData.ComponentRef = Component;
			MeshData.RelativeTransform = Component.RelativeTransform;
			MeshData.RelativeTransform.SetLocation(FVector::ZeroVector);
			Component.SetAbsolute(true, true, true);
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (Manager == nullptr)
			TryRegister();
		if (Manager == nullptr)
			return;

		for (FSplitTraversalMeshData& MeshData : Meshes)
		{
			if (MeshData.ComponentRef == nullptr)
				continue;
			if (MeshData.SplitName != n"Scifi")
				continue;

			USceneComponent Component = MeshData.ComponentRef;

			FTransform ParentTransform = Owner.ActorTransform;
			FTransform ComponentTransform = MeshData.RelativeTransform * ParentTransform;
			ComponentTransform.SetLocation(Manager.Position_FantasyToScifi(ComponentTransform.Location));

			Component.WorldTransform = ComponentTransform;
		}
	}
}