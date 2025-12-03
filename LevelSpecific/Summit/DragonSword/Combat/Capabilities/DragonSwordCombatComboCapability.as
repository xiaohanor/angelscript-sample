class UDragonSwordCombatComboCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	
	default CapabilityTags.Add(DragonSwordCapabilityTags::DragonSword);
	
	default CapabilityTags.Add(DragonSwordCapabilityTags::DragonSwordCombat);

	default DebugCategory = SummitDebugCapabilityTags::DragonSword;

	default TickGroup = EHazeTickGroup::AfterGameplay;
	default TickGroupOrder = 100;

	UDragonSwordCombatUserComponent CombatComp;
	UDragonSwordUserComponent SwordComp;
	UPlayerMovementComponent MoveComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		CombatComp = UDragonSwordCombatUserComponent::Get(Owner);
		SwordComp = UDragonSwordUserComponent::Get(Owner);
		MoveComp = UPlayerMovementComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!CombatComp.HasActiveCombo())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!CombatComp.HasActiveCombo())
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
		if(CombatComp.HasActiveCombo())
			CombatComp.ComboData.Invalidate();

		CombatComp.bIsAirDash = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!HasControl())
			return;

		if (CombatComp.bInsideComboGraceWindow)
		{
			if (Time::GetGameTimeSince(CombatComp.TimeWhenStartedComboGrace) > DragonSwordCombat::ComboGraceWindow)
				CombatComp.EndComboGrace();
			else
				return;
		}

		TArray<FDragonSwordCombatAttackTypeData> ComboAttackTypeDatas = CombatComp.ComboData.GetAttackTypeDatas();
		for(int i = 0; i < ComboAttackTypeDatas.Num(); i++)
		{
			switch(ComboAttackTypeDatas[i].ToType())
			{
				case EDragonSwordCombatAttackType::Air:
				case EDragonSwordCombatAttackType::AirRush:
				{
					if(!MoveComp.IsInAir())
 						CombatComp.ComboData.ResetCombo(ComboAttackTypeDatas[i]);

					break;
				}

				case EDragonSwordCombatAttackType::Dash:
				{
					if(CombatComp.bIsAirDash)
					{
						if(!MoveComp.IsInAir())
							CombatComp.ComboData.ResetCombo(ComboAttackTypeDatas[i]);
					}
					else
					{
						if(!CombatComp.HasActiveAttack() && !CombatComp.HasPendingAttack() && !CombatComp.bInsideSettleWindow)
							CombatComp.ComboData.ResetCombo(ComboAttackTypeDatas[i]);
					}

					break;
				}

				default:
				{
					if(!CombatComp.HasActiveAttack() && !CombatComp.HasPendingAttack() && !CombatComp.bInsideSettleWindow)
						CombatComp.ComboData.ResetCombo(ComboAttackTypeDatas[i]);

					break;
				}
			}
		}
	}
}