class UAnimNotifyGravityBladeHitWindow : UAnimNotifyState
{
	UPROPERTY(EditAnywhere, Category = "Hit Data")
	bool bGuaranteeHitTargetEnemyImmediately = false;

	UPROPERTY(EditAnywhere, Category = "Hit Data")
	EAnimHitPitch HitPitch = EAnimHitPitch::Center;

	UPROPERTY(EditAnywhere, Category = "Hit Data")
	EHazeCardinalDirection HitDirection = EHazeCardinalDirection::Forward;

	UPROPERTY(EditAnywhere, Category = "Hit Data")
	float KnockbackMultiplier = 1.0;

	UPROPERTY(EditAnywhere, Category = "Hit Data")
	float KnockbackExtraDistance = 0.0;

	UFUNCTION(BlueprintOverride)
	FString GetNotifyName() const
	{
		return "GravityBladeHitWindow";
	}

	UFUNCTION(BlueprintOverride)
	bool NotifyBegin(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation, float TotalDuration, FAnimNotifyEventReference EventReference) const
	{
		if (MeshComp.Owner == nullptr)
			return true;
		UGravityBladeCombatUserComponent CombatComp = UGravityBladeCombatUserComponent::Get(MeshComp.Owner);
		if (CombatComp == nullptr)
			return true;

		CombatComp.bInsideHitWindow = true;
		CombatComp.bTriggerHitWindowFrame = true;
		CombatComp.bHitWindowGuaranteeHitTargetEnemyImmediately = bGuaranteeHitTargetEnemyImmediately;
		CombatComp.HitWindowPushbackMultiplier = KnockbackMultiplier;
		CombatComp.HitWindowExtraPushback = KnockbackExtraDistance;

		CombatComp.ClearPreviousHitActors();

		CombatComp.HitPitch = HitPitch;

		CombatComp.HitDirection = HitDirection;

		UGravityBladeCombatEventHandler::Trigger_StartHitWindow(CombatComp.GetBladeComp().Blade);

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

		CombatComp.bInsideHitWindow = false;

		if (CombatComp.GetBladeComp().Blade != nullptr)
			UGravityBladeCombatEventHandler::Trigger_StopHitWindow(CombatComp.GetBladeComp().Blade);

		return true;
	}
}