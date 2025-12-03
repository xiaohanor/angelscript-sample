class UGravityBladeCombatSpeedUpCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(GravityBladeTags::GravityBlade);
	default CapabilityTags.Add(GravityBladeCombatTags::GravityBladeCombat);

	default DebugCategory = GravityBlade::DebugCategory;

	default TickGroup = EHazeTickGroup::Input;
	default TickGroupOrder = 100;

	UGravityBladeUserComponent BladeComp;
	UGravityBladeCombatUserComponent CombatComp;
	UPlayerMovementComponent MoveComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		BladeComp = UGravityBladeUserComponent::Get(Owner);
		CombatComp = UGravityBladeCombatUserComponent::Get(Owner);
		MoveComp = UPlayerMovementComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!BladeComp.IsBladeEquipped())
			return false;

		if(!IsInAttack())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!BladeComp.IsBladeEquipped() && !CombatComp.ThrowBladeData.IsValid())
			return true;

		if(!IsInAttack())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float MinTime = 0.0;
		float MaxTime = 1.0;
		CombatComp.SpeedUpCurve.GetTimeRange(MinTime, MaxTime);

		if(CombatComp.SpeedUpDuration == 0.0)
			CombatComp.CurrentSpeedUpCurveTime = MaxTime;
		else
		{
			CombatComp.CurrentSpeedUpCurveTime += DeltaTime / CombatComp.SpeedUpDuration;
			if(CombatComp.CurrentSpeedUpCurveTime > MaxTime)
				CombatComp.CurrentSpeedUpCurveTime = MaxTime;
		}

		CombatComp.CurrentSpeedUpCurveValue = CombatComp.SpeedUpCurve.GetFloatValue(CombatComp.CurrentSpeedUpCurveTime);

		CombatComp.CurrentSpeedUpPlayRate = Math::Lerp(1.0, CombatComp.MaxSpeedUpPlayRate, CombatComp.CurrentSpeedUpCurveValue);
		CombatComp.CurrentSpeedUpStartTime = Math::Lerp(0.0, CombatComp.MaxSpeedUpStartTime, CombatComp.CurrentSpeedUpCurveValue);
		CombatComp.CurrentSpeedUpRushSpeedMultiplier = Math::Lerp(1.0, CombatComp.MaxRushSpeedMultiplier, CombatComp.CurrentSpeedUpCurveValue);
	}

	private bool IsInAttack() const
	{
		if(CombatComp.bInsideSettleWindow)
			return false;

		if(CombatComp.HasActiveAttack())
			return true;

		if(CombatComp.HasPendingAttack())
			return true;

		return false;
	}
}