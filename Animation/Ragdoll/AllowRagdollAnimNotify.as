class UAnimNotifyAllowRagdoll : UAnimNotifyState
{
#if EDITOR
	default NotifyColor = FColor(255, 180, 0);
#endif

	UPROPERTY(EditAnywhere)
	FRagdollImpulse Impulse;
	default Impulse.Type = ERagdollImpulseType::MeshSpace;

	UFUNCTION(BlueprintOverride)
	FString GetNotifyName() const
	{
		return "AllowRagdoll";
	}

	UFUNCTION(BlueprintOverride)
	bool NotifyBegin(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation, float TotalDuration, FAnimNotifyEventReference EventReference) const
	{
		if (!IsValid(MeshComp.Owner))
			return false;
		auto RagdollComp = URagdollComponent::GetOrCreate(MeshComp.Owner);
		RagdollComp.bAllowRagdoll.Apply(true, this, EInstigatePriority::Low);
		if (Impulse.IsValid())
			RagdollComp.PendingImpulses.Add(this, Impulse);
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool NotifyEnd(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation, FAnimNotifyEventReference EventReference) const
	{
		if (!IsValid(MeshComp.Owner))
			return false;
		auto RagdollComp = URagdollComponent::GetOrCreate(MeshComp.Owner);
		RagdollComp.bAllowRagdoll.Clear(this);
		RagdollComp.PendingImpulses.Remove(this);
		return true;
	}
}
