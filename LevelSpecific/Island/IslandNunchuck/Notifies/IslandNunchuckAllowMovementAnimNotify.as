
/** This notify enables movement during an attack */
class UIslandNunchuckBlockMovementRotationAnimNotify : UAnimNotifyState
{
	UFUNCTION(BlueprintOverride)
	FString GetNotifyName() const
	{
		return "IslandNunchuck_BlockMovementRotation";
	}

	UFUNCTION(BlueprintOverride)
	bool NotifyBegin(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation, float TotalDuration, FAnimNotifyEventReference EventReference) const
	{
		auto MeleeComp = UPlayerIslandNunchuckUserComponent::Get(MeshComp.GetOwner());
		if (MeleeComp == nullptr)
			return true;
		
		MeleeComp.BlockMovementRotationCounter++;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool NotifyEnd(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation, FAnimNotifyEventReference EventReference) const
	{
		auto MeleeComp = UPlayerIslandNunchuckUserComponent::Get(MeshComp.GetOwner());
		if (MeleeComp == nullptr)
			return true;

		MeleeComp.BlockMovementRotationCounter--;
		return true;
	}
}