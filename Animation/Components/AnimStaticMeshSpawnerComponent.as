/** Used for spawning static meshes through AnimNotifies, for example during gestures */
class UAnimStaticMeshSpawnerComponent : UActorComponent
{
	private TMap<UObject, AStaticMeshActor> SpawnedMeshes;

	// TODO: Options to dither in/out the mesh could be nice
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{

	}


	UFUNCTION(BlueprintCallable)
	void SpawnStaticMesh(UObject Instigator, UStaticMesh Mesh, USkeletalMeshComponent SkelMeshComp, FName SocketName = NAME_None, FTransform Offset = FTransform::Identity)
	{
		auto MeshActor = AStaticMeshActor::Spawn(Name = n"AnimStaticMesh");
		MeshActor.SetMobility(EComponentMobility::Movable);
		MeshActor.StaticMeshComponent.SetMobility(EComponentMobility::Movable);

		MeshActor.StaticMeshComponent.SetStaticMesh(Mesh);
		
		MeshActor.AttachToComponent(SkelMeshComp, SocketName, EAttachmentRule::SnapToTarget);
		MeshActor.AddActorLocalTransform(Offset);

		MeshActor.SetActorEnableCollision(false);
		
		SpawnedMeshes.Add(Instigator, MeshActor);
	}


	UFUNCTION(BlueprintCallable)
	void ClearStaticMesh(UObject Instigator) 
	{
		AStaticMeshActor MeshActor;
		SpawnedMeshes.Find(Instigator, MeshActor);
		if (MeshActor != nullptr)
			RemoveMeshActor(MeshActor);
	}


	UFUNCTION(BlueprintCallable)
	void ClearAllStaticMeshes() 
	{
		for (auto& SpawnedMesh : SpawnedMeshes)
			RemoveMeshActor(SpawnedMesh.Value);
		
	}


	private void RemoveMeshActor(AStaticMeshActor MeshActor)
	{
		MeshActor.DestroyActor();
	}
};