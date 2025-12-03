class UAnimNotifyStateSpawnStaticMesh : UAnimNotifyState
{
	UPROPERTY(EditAnywhere)
	UStaticMesh Mesh;

	UPROPERTY(EditAnywhere)	
	FName SocketName = NAME_None;

	UPROPERTY(EditAnywhere)
	FTransform Offset;

#if EDITOR
	default NotifyColor = FColor::Cyan;
#endif


	UFUNCTION(BlueprintOverride)
	FString GetNotifyName() const
	{
		return "Spawn Static Mesh  ";
	}


	UFUNCTION(BlueprintOverride)
	bool NotifyBegin(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation, float TotalDuration, FAnimNotifyEventReference EventReference) const
	{
		if (Mesh == nullptr || Mesh == nullptr)
			return false;

		auto Component = UAnimStaticMeshSpawnerComponent::GetOrCreate(MeshComp.Owner);
		Component.SpawnStaticMesh(Animation, Mesh, MeshComp, SocketName, Offset);

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool NotifyEnd(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation, FAnimNotifyEventReference EventReference) const
	{
		if (Mesh == nullptr)
			return false;

		auto Component = UAnimStaticMeshSpawnerComponent::Get(MeshComp.Owner);
		if (Component != nullptr)
			Component.ClearStaticMesh(Animation);

		return true;
	}
}