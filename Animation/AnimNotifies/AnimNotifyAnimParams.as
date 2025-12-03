class UAnimNotifySetAnimBoolParam : UAnimNotify
{

	UPROPERTY(EditAnywhere)
	const FName Tag;

	UPROPERTY(EditAnywhere)
	const bool Value = true; // TODO: Update var name to `bValue` in the next project, too late now.

#if EDITOR
	default NotifyColor = FColor::Red;
#endif

	UFUNCTION(BlueprintOverride)
	FString GetNotifyName() const
	{
		return "AnimBoolParam";
	}

	UFUNCTION(BlueprintOverride)
	bool Notify(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation, FAnimNotifyEventReference EventReference) const
	{
		auto HazeSkelMeshComp = Cast<UHazeSkeletalMeshComponentBase>(MeshComp);
		if (HazeSkelMeshComp != nullptr)
			HazeSkelMeshComp.SetAnimBoolParam(Tag, Value);

		return true;
	}
}


class UAnimNotifySetAnimFloatParam : UAnimNotify
{

	UPROPERTY(EditAnywhere)
	const FName Tag;

	UPROPERTY(EditAnywhere)
	const float Value;

#if EDITOR
	default NotifyColor = FColor::Green;
#endif

	UFUNCTION(BlueprintOverride)
	FString GetNotifyName() const
	{
		return "AnimFloatParam";
	}

	UFUNCTION(BlueprintOverride)
	bool Notify(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation, FAnimNotifyEventReference EventReference) const
	{
		auto HazeSkelMeshComp = Cast<UHazeSkeletalMeshComponentBase>(MeshComp);
		if (HazeSkelMeshComp != nullptr)
			HazeSkelMeshComp.SetAnimFloatParam(Tag, Value);

		return true;
	}
}

class UAnimNotifySetAnimIntParam : UAnimNotify
{

	UPROPERTY(EditAnywhere)
	const FName Tag;

	UPROPERTY(EditAnywhere)
	const int Value;

#if EDITOR
	default NotifyColor = FColor::Cyan;
#endif

	UFUNCTION(BlueprintOverride)
	FString GetNotifyName() const
	{
		return "AnimIntParam";
	}

	UFUNCTION(BlueprintOverride)
	bool Notify(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation, FAnimNotifyEventReference EventReference) const
	{
		auto HazeSkelMeshComp = Cast<UHazeSkeletalMeshComponentBase>(MeshComp);
		if (HazeSkelMeshComp != nullptr)
			HazeSkelMeshComp.SetAnimIntParam(Tag, Value);

		return true;
	}
}

class UAnimNotifyStateSetAnimBoolParam : UAnimNotifyState
{

	UPROPERTY(EditAnywhere)
	const FName Tag;

	// Set the BoolParam to `false` when we leave the set range
	UPROPERTY(EditAnywhere)
	bool bResetOnEnd = true;

#if EDITOR
	default NotifyColor = FColor::Red;
#endif

	UFUNCTION(BlueprintOverride)
	FString GetNotifyName() const
	{
		return "AnimBoolParam";
	}

	UFUNCTION(BlueprintOverride)
	bool NotifyBegin(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation, float TotalDuration, FAnimNotifyEventReference EventReference) const
	{
		auto HazeSkelMeshComp = Cast<UHazeSkeletalMeshComponentBase>(MeshComp);
		if (HazeSkelMeshComp != nullptr)
			HazeSkelMeshComp.SetAnimBoolParam(Tag, true);

		return true;
	}


	UFUNCTION(BlueprintOverride)
	bool NotifyEnd(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation, FAnimNotifyEventReference EventReference) const
	{
		if (bResetOnEnd)
		{
			auto AnimInstance = Cast<UHazeAnimInstanceBase>(MeshComp.AnimInstance);
			if (AnimInstance != nullptr)
			{
				// Consume the AnimBoolParam
				AnimInstance.ClearAnimBoolParam(Tag);
			}
		}

		return true;
	}

}