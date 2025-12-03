class UAnimNotifyStoneBossWeakpointStabWindow : UAnimNotifyState
{
	UFUNCTION(BlueprintOverride)
	FString GetNotifyName() const
	{
		return "StoneBossWeakpointStabWindow";
	}

	UFUNCTION(BlueprintOverride)
	bool NotifyBegin(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation, float TotalDuration, FAnimNotifyEventReference EventReference) const
	{
		if (MeshComp.Owner == nullptr)
			return true;

		UStoneBossQTEWeakpointPlayerComponent WeakpointComp = UStoneBossQTEWeakpointPlayerComponent::Get(MeshComp.Owner);
		if (WeakpointComp == nullptr)
			return true;

		WeakpointComp.bIsInsideStabWindow = true;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool NotifyEnd(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation, FAnimNotifyEventReference EventReference) const
	{
		if (MeshComp.Owner == nullptr)
			return true;
		
		UStoneBossQTEWeakpointPlayerComponent WeakpointComp = UStoneBossQTEWeakpointPlayerComponent::Get(MeshComp.Owner);
		if (WeakpointComp == nullptr)
			return true;

		WeakpointComp.bIsInsideStabWindow = false;
		return true;
	}
}