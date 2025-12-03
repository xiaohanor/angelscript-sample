class UAnimNotifyGravityBladeSpeedUpWindow : UAnimNotifyState
{
	UFUNCTION(BlueprintOverride)
	FString GetNotifyName() const
	{
		return "GravityBladeSpeedUpWindow";
	}

	UFUNCTION(BlueprintOverride)
	bool NotifyBegin(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation, float TotalDuration, FAnimNotifyEventReference EventReference) const
	{
		UGravityBladeCombatUserComponent CombatComp = UGravityBladeCombatUserComponent::Get(MeshComp.Owner);
		if (CombatComp == nullptr)
			return true;

		CombatComp.bInsideSpeedUpWindow = true;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool NotifyEnd(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation, FAnimNotifyEventReference EventReference) const
	{
		UGravityBladeCombatUserComponent CombatComp = UGravityBladeCombatUserComponent::Get(MeshComp.Owner);
		if (CombatComp == nullptr)
			return true;

		CombatComp.bInsideSpeedUpWindow = false;

		return true;
	}
}