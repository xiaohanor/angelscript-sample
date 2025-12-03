class USkippingStonesPickupStoneAnimNotify : UAnimNotify
{
	UFUNCTION(BlueprintOverride)
	bool Notify(
		USkeletalMeshComponent MeshComp,
		UAnimSequenceBase Animation,
	    FAnimNotifyEventReference EventReference) const
	{
		auto SkippingStonesComp = USkippingStonesPlayerComponent::Get(MeshComp.Owner);
		if(SkippingStonesComp == nullptr)
			return false;

		SkippingStonesComp.bShouldPickUpStone = true;
		return true;
	}
};