class UAnimNotifyGravityBladeSettleWindow : UAnimNotifyState
{
	UFUNCTION(BlueprintOverride)
	FString GetNotifyName() const
	{
		return "GravityBladeSettleWindow";
	}

	UFUNCTION(BlueprintOverride)
	bool NotifyBegin(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation, float TotalDuration, FAnimNotifyEventReference EventReference) const
	{
		if (MeshComp.Owner == nullptr)
			return true;
		UGravityBladeCombatUserComponent CombatComp = UGravityBladeCombatUserComponent::Get(MeshComp.Owner);
		if (CombatComp == nullptr)
			return true;

		CombatComp.bInsideSettleWindow = true;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool NotifyEnd(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation, FAnimNotifyEventReference EventReference) const
	{
		if (MeshComp.Owner == nullptr)
			return true;
		UGravityBladeCombatUserComponent CombatComp = UGravityBladeCombatUserComponent::Get(MeshComp.Owner);
		if (CombatComp == nullptr)
			return true;

		CombatComp.bInsideSettleWindow = false;

		return true;
	}
}