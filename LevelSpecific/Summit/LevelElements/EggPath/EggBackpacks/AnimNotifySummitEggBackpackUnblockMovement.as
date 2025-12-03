class UAnimNotifySummitEggBackpackUnblockMovement : UAnimNotifyState
{
	UFUNCTION(BlueprintOverride)
	FString GetNotifyName() const
	{
		return "EggBackpackUnblockMovement";
	}

	UFUNCTION(BlueprintOverride)
	bool NotifyBegin(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation, float TotalDuration,
					 FAnimNotifyEventReference EventReference) const
	{
		USummitEggBackpackComponent BackpackComp = USummitEggBackpackComponent::Get(MeshComp.Owner);
		if(BackpackComp == nullptr)
			return true;

		BackpackComp.bPlayerAnimUnblockRequested = true;
		return true;
	}
};