UCLASS(Abstract)
class ARedSpacePressurePlateCable : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent CableRoot;

	UPROPERTY(EditDefaultsOnly)
	UMaterialInterface ActiveMaterial;

	UPROPERTY(EditDefaultsOnly)
	UMaterialInterface InactiveMaterial;

	bool bActive = false;

	TArray<AStaticMeshActor> Meshes;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TArray<AActor> AttachedActors;
		GetAttachedActors(AttachedActors);
		for (AActor Actor : AttachedActors)
		{
			AStaticMeshActor MeshActor = Cast<AStaticMeshActor>(Actor);
			if (MeshActor != nullptr)
				Meshes.Add(MeshActor);
		}
	}

	void Activate()
	{
		if (bActive)
			return;

		bActive = true;

		for (AStaticMeshActor Mesh : Meshes)
			Mesh.StaticMeshComponent.SetMaterial(0, ActiveMaterial);
	}

	void Deactivate()
	{
		if (!bActive)
			return;

		bActive = false;

		for (AStaticMeshActor Mesh : Meshes)
			Mesh.StaticMeshComponent.SetMaterial(0, InactiveMaterial);
	}
}