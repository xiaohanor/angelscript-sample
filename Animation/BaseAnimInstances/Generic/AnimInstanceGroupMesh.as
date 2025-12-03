
UCLASS(Abstract)
class UAnimInstanceGroupMesh : UHazeAnimInstanceBase
{
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	AGroupMeshSplineActor GroupMeshSplineActor;

	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
		if(HazeOwningActor == nullptr)
			return;

		GroupMeshSplineActor = Cast<AGroupMeshSplineActor>(HazeOwningActor);
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		if(GroupMeshSplineActor == nullptr)
			return;

		ClearModifyBonesData();

		for (FHazeGroupMeshPerBaseBoneData& PerMeshData : GroupMeshSplineActor.MeshData)
		{
			FHazeModifyBoneData& ModifyBoneData = GetOrAddModifyBoneData(PerMeshData.BoneName);

			ModifyBoneData.ScaleMode = EHazeBoneModificationMode::Mode_Ignore;

			ModifyBoneData.TranslationMode = EHazeBoneModificationMode::Mode_Replace;
			ModifyBoneData.TranslationSpace = EBoneControlSpace::BCS_WorldSpace;

			ModifyBoneData.RotationMode = EHazeBoneModificationMode::Mode_Replace;
			ModifyBoneData.RotationSpace = EBoneControlSpace::BCS_WorldSpace;
		}
	}

    UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if(GroupMeshSplineActor == nullptr)
			return;

		for (int i = 0; i < GroupMeshSplineActor.MeshData.Num(); i++)
		{
			FHazeGroupMeshPerBaseBoneData& PerMeshData = GroupMeshSplineActor.MeshData[i];
			FHazeModifyBoneData& ModifyBoneData = GetOrAddModifyBoneData(PerMeshData.BoneName);

			ModifyBoneData.Translation = PerMeshData.BaseBoneWorldTransform.GetTranslation();
			ModifyBoneData.Rotation = PerMeshData.BaseBoneWorldTransform.Rotator();
		}
	}
}