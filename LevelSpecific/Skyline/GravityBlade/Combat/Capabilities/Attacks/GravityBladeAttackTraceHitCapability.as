class UGravityBladeAttackTraceHitCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(GravityBladeTags::GravityBlade);

	default TickGroup = EHazeTickGroup::AfterGameplay;

	UGravityBladeUserComponent BladeComp;
	UGravityBladeCombatUserComponent CombatComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		BladeComp = UGravityBladeUserComponent::Get(Owner);
		CombatComp = UGravityBladeCombatUserComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!CombatComp.HasActiveAttack())
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!CombatComp.HasActiveAttack())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (CombatComp.bInsideHitWindow || CombatComp.bTriggerHitWindowFrame)
		{
			CombatComp.TraceForHitsForActiveAttack();
			CombatComp.bTriggerHitWindowFrame = false;

			FHazeFrameForceFeedback FF;
			FF.LeftMotor = ActiveDuration;
			FF.RightMotor = 1 - ActiveDuration * 2;
			Player.SetFrameForceFeedback(FF);
		}
	}
};