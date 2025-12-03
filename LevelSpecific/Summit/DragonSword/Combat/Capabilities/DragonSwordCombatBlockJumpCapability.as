class UDragonSwordCombatBlockJumpCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default CapabilityTags.Add(DragonSwordCapabilityTags::DragonSword);

	default CapabilityTags.Add(DragonSwordCapabilityTags::DragonSwordCombat);

	default DebugCategory = SummitDebugCapabilityTags::DragonSword;

	default TickGroup = EHazeTickGroup::Input;
	default TickGroupOrder = 100;

	UDragonSwordCombatUserComponent CombatComp;
	UDragonSwordUserComponent SwordComp;
	UPlayerMovementComponent MoveComp;
	UPlayerJumpComponent JumpComp;

	bool bBlockJumpAndDash = false;
	bool bShouldDecreaseInputBuffer = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		CombatComp = UDragonSwordCombatUserComponent::Get(Owner);
		SwordComp = UDragonSwordUserComponent::Get(Owner);
		MoveComp = UPlayerMovementComponent::Get(Owner);
		JumpComp = UPlayerJumpComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!SwordComp.IsWeaponEquipped())
			return false;

		if (!CombatComp.HasActiveAttack())
			return false;

		if (CombatComp.bInsideComboWindow)
			return false;

		if (CombatComp.bInsideSettleWindow)
			return false;

		if (CombatComp.IsDashing())
			return false;

		if (CombatComp.IsAirDashing())
			return false;

		if (JumpComp.IsJumping())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!SwordComp.IsWeaponEquipped())
			return true;

		if (!CombatComp.HasActiveAttack())
			return true;

		if (CombatComp.bInsideComboWindow)
			return true;

		if (CombatComp.bInsideSettleWindow)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.BlockCapabilities(PlayerMovementTags::Jump, this);
		Player.BlockCapabilities(PlayerMovementTags::AirJump, this);

		UPlayerStepDashSettings::SetInputBufferWindow(Player, DragonSwordCombat::InputBufferTime, this);
		UPlayerJumpSettings::SetInputBufferWindow(Player, DragonSwordCombat::InputBufferTime, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(PlayerMovementTags::Jump, this);
		Player.UnblockCapabilities(PlayerMovementTags::AirJump, this);

		bShouldDecreaseInputBuffer = true;
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (JumpComp.IsJumping() || CombatComp.IsDashing() || CombatComp.IsAirDashing())
		{
			if (CombatComp.HasPendingAttack() && ShouldInvalidate(CombatComp.PendingAttackData.AttackTypeData))
			{
				CombatComp.PendingAttackData.Invalidate();
			}

			if (CombatComp.HasActiveAttack() && ShouldInvalidate(CombatComp.ActiveAttackData.AttackTypeData))
			{
				CombatComp.ActiveAttackData.Invalidate();
			}
		}

		if (!IsActive() && bShouldDecreaseInputBuffer)
		{
			UPlayerStepDashSettings::ClearInputBufferWindow(Player, this);
			UPlayerJumpSettings::ClearInputBufferWindow(Player, this);
		}
	}

	bool ShouldInvalidate(FDragonSwordCombatAttackTypeData AttackTypeData)
	{
		if (JumpComp.IsJumping() || CombatComp.IsDashing() || CombatComp.IsAirDashing())
		{
			switch (AttackTypeData.GetMovementType())
			{
					// case EDragonSwordAttackMovementType::Air:
					// {
					// 	if(JumpComp.IsJumping())
					// 		return false;

					// 	if(CombatComp.IsAirDashing())
					// 		return false;
					// }

				case EDragonSwordAttackMovementType::Dash:
				{
					if (CombatComp.IsDashing())
						return false;

					if (CombatComp.IsAirDashing())
						return false;

					return true;
				}

				case EDragonSwordAttackMovementType::Ground:
					break;

				case EDragonSwordAttackMovementType::Sprint:
					break;

				default:
					break;
			}

			return true;
		}
		else
		{
			return false;
		}
	}
}