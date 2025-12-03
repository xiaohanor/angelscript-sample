class USkippingStonesThrowStoneStoneAnimNotify : UAnimNotify
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

		SkippingStonesComp.bShouldThrowStone = true;
		return true;
	}
};