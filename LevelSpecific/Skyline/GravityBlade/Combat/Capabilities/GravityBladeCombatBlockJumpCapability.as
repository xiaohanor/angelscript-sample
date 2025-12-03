class UGravityBladeCombatBlockJumpCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default CapabilityTags.Add(GravityBladeTags::GravityBlade);
	
	default CapabilityTags.Add(GravityBladeCombatTags::GravityBladeCombat);

	default DebugCategory = GravityBlade::DebugCategory;

	default TickGroup = EHazeTickGroup::Input;
	default TickGroupOrder = 100;

	UGravityBladeCombatUserComponent CombatComp;
	UGravityBladeUserComponent BladeComp;
	UPlayerMovementComponent MoveComp;
	UPlayerJumpComponent JumpComp;

	bool bBlockJumpAndDash = false;
	bool bShouldDecreaseInputBuffer = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		CombatComp = UGravityBladeCombatUserComponent::Get(Owner);
		BladeComp = UGravityBladeUserComponent::Get(Owner);
		MoveComp = UPlayerMovementComponent::Get(Owner);
		JumpComp = UPlayerJumpComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!BladeComp.IsBladeEquipped())
			return false;

		if(!CombatComp.HasActiveAttack())
			return false;

		if(!CombatComp.ActiveAttackData.IsRushAttack())
			return false;

		if(CombatComp.HasActiveAttack() && CombatComp.bInsideComboWindow)
			return false;

		if(CombatComp.IsDashing())
			return false;

		if(CombatComp.IsAirDashing())
			return false;

		if(JumpComp.IsJumping())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!BladeComp.IsBladeEquipped() && !CombatComp.ThrowBladeData.IsValid())
			return true;

		if(!CombatComp.HasActiveAttack())
			return true;

		if(CombatComp.bInsideComboWindow)
			return true;

		if(CombatComp.bInsideSettleWindow)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.BlockCapabilities(PlayerMovementTags::Dash, this);
		Player.BlockCapabilities(PlayerMovementTags::AirDash, this);
		Player.BlockCapabilities(PlayerMovementTags::RollDash, this);

		Player.BlockCapabilities(PlayerMovementTags::Jump, this);
		Player.BlockCapabilities(PlayerMovementTags::AirJump, this);

		UPlayerStepDashSettings::SetInputBufferWindow(Player, GravityBladeCombat::InputBufferTime, this);
		UPlayerJumpSettings::SetInputBufferWindow(Player, GravityBladeCombat::InputBufferTime, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(PlayerMovementTags::Dash, this);
		Player.UnblockCapabilities(PlayerMovementTags::AirDash, this);
		Player.UnblockCapabilities(PlayerMovementTags::RollDash, this);

		Player.UnblockCapabilities(PlayerMovementTags::Jump, this);
		Player.UnblockCapabilities(PlayerMovementTags::AirJump, this);

		bShouldDecreaseInputBuffer = true;
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if(JumpComp.IsJumping() || CombatComp.IsDashing() || CombatComp.IsAirDashing())
		{
			if(CombatComp.HasPendingAttack() && ShouldInvalidate(CombatComp.PendingAttackData.MovementType))
			{
				CombatComp.PendingAttackData.Invalidate();
			}

			if(CombatComp.HasActiveAttack() && ShouldInvalidate(CombatComp.ActiveAttackData.MovementType))
			{
				CombatComp.ActiveAttackData.Invalidate();
			}
		}

		if(!IsActive() && bShouldDecreaseInputBuffer)
		{
			UPlayerStepDashSettings::ClearInputBufferWindow(Player, this);
			UPlayerJumpSettings::ClearInputBufferWindow(Player, this);
		}
	}

	bool ShouldInvalidate(EGravityBladeAttackMovementType MovementType)
	{
		if(JumpComp.IsJumping() || CombatComp.IsDashing() || CombatComp.IsAirDashing())
		{
			switch(MovementType)
			{
				case EGravityBladeAttackMovementType::Air:
				case EGravityBladeAttackMovementType::AirHover:
				case EGravityBladeAttackMovementType::AirSlam:
				{
					if(JumpComp.IsJumping())
						return false;

					if(CombatComp.IsAirDashing())
						return false;

					break;
				}
				
				case EGravityBladeAttackMovementType::Ground:
					break;

				case EGravityBladeAttackMovementType::GroundRush:
					break;

				case EGravityBladeAttackMovementType::AirRush:
					break;
				
				case EGravityBladeAttackMovementType::OpportunityAttack:
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