class UAnimNotifyCopyAnimBoneTransforms : UAnimNotify
{

	UPROPERTY(EditAnywhere, meta = (ShowOnlyInnerProperties))
	FHazeCopyAnimBoneTransformData Data;

#if EDITOR
	default NotifyColor = FColor::FromHex("#ff8400");
#endif

	UFUNCTION(BlueprintOverride)
	FString GetNotifyName() const
	{
		return "Copy Transforms";
	}

	UFUNCTION(BlueprintOverride)
	bool Notify(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation, FAnimNotifyEventReference EventReference) const
	{
		auto AnimInstance = Cast<UHazeCharacterAnimInstance>(MeshComp.AnimInstance);
		if (AnimInstance != nullptr)
			AnimInstance.RequestCopyAnimBoneTransforms(Data);

		return true;
	}
}


class UAnimNotifyClearCopyAnimBoneTransform : UAnimNotify
{

	UPROPERTY(EditAnywhere)
	FName BoneName;

#if EDITOR
	default NotifyColor = FColor::FromHex("#ff5e00");
#endif

	UFUNCTION(BlueprintOverride)
	FString GetNotifyName() const
	{
		return "Clear Copied Transforms";
	}

	UFUNCTION(BlueprintOverride)
	bool Notify(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation, FAnimNotifyEventReference EventReference) const
	{
		auto AnimInstance = Cast<UHazeCharacterAnimInstance>(MeshComp.AnimInstance);
		if (AnimInstance != nullptr)
			AnimInstance.ClearCopyAnimBoneTransform(BoneName);

		return true;
	}
}


class UAnimNotifyClearAllCopyAnimBoneTransforms : UAnimNotify
{

#if EDITOR
	default NotifyColor = FColor::FromHex("#ff5e00");
#endif

	UFUNCTION(BlueprintOverride)
	FString GetNotifyName() const
	{
		return "Clear All Copied Transforms";
	}

	UFUNCTION(BlueprintOverride)
	bool Notify(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation, FAnimNotifyEventReference EventReference) const
	{
		auto AnimInstance = Cast<UHazeCharacterAnimInstance>(MeshComp.AnimInstance);
		if (AnimInstance != nullptr)
			AnimInstance.ClearAllCopyAnimBoneTransforms();

		return true;
	}
}


class UAnimNotifyStateCopyAnimBoneTransforms : UAnimNotifyState
{
	UPROPERTY(EditAnywhere, meta = (ShowOnlyInnerProperties))
	FHazeCopyAnimBoneTransformData Data;

	UPROPERTY(EditAnywhere)
	bool bResetOnEnd = true;

#if EDITOR
	default NotifyColor = FColor::FromHex("#ff8400");
#endif

	UFUNCTION(BlueprintOverride)
	FString GetNotifyName() const
	{
		return "Copy Transforms";
	}

	UFUNCTION(BlueprintOverride)
	bool NotifyBegin(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation, float TotalDuration, FAnimNotifyEventReference EventReference) const
	{
		auto AnimInstance = Cast<UHazeCharacterAnimInstance>(MeshComp.AnimInstance);
		if (AnimInstance != nullptr)
			AnimInstance.RequestCopyAnimBoneTransforms(Data);

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool NotifyEnd(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation, FAnimNotifyEventReference EventReference) const
	{
		if (bResetOnEnd)
		{
			auto AnimInstance = Cast<UHazeCharacterAnimInstance>(MeshComp.AnimInstance);
			if (AnimInstance != nullptr)
				AnimInstance.ClearCopyAnimBoneTransform(Data.ModifyBoneName);
		}

		return true;
	}

}