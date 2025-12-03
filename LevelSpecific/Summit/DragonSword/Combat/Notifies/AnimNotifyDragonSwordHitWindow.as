class UAnimNotifyDragonSwordHitWindow : UAnimNotifyState
{
	UPROPERTY(EditAnywhere, Category = "Hit Data")
	EAnimHitPitch HitPitch = EAnimHitPitch::Center;

	UPROPERTY(EditAnywhere, Category = "Hit Data")
	EHazeCardinalDirection HitDirection = EHazeCardinalDirection::Forward;

	UFUNCTION(BlueprintOverride)
	FString GetNotifyName() const
	{
		return "DragonSwordHitWindow";
	}

	UFUNCTION(BlueprintOverride)
	bool NotifyBegin(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation, float TotalDuration, FAnimNotifyEventReference EventReference) const
	{
		if (MeshComp.Owner == nullptr)
			return true;
		
		UDragonSwordCombatUserComponent CombatComp = UDragonSwordCombatUserComponent::Get(MeshComp.Owner);
		if (CombatComp == nullptr)
			return true;

		CombatComp.bInsideHitWindow = true;

		CombatComp.HitPitch = HitPitch;

		CombatComp.HitDirection = HitDirection;

		UDragonSwordCombatEventHandler::Trigger_StartHitWindow(CombatComp.GetSwordComp().Weapon);

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool NotifyEnd(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation, FAnimNotifyEventReference EventReference) const
	{
		if (MeshComp.Owner == nullptr)
			return true;

		UDragonSwordCombatUserComponent CombatComp = UDragonSwordCombatUserComponent::Get(MeshComp.Owner);
		if (CombatComp == nullptr)
			return true;

		CombatComp.bInsideHitWindow = false;

		if (CombatComp.GetSwordComp().Weapon != nullptr)
			UDragonSwordCombatEventHandler::Trigger_StopHitWindow(CombatComp.GetSwordComp().Weapon);

		return true;
	}
}