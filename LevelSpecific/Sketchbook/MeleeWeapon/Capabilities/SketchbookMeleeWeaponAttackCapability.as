struct FSketchbookMeleeWeaponAttackActivateParams
{
	FVector AttackDirection;
};

class USketchbookMeleeWeaponAttackCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	USketchbookMeleeAttackPlayerComponent AttackComp;
	USketchbookMeleeWeaponPlayerComponent WeaponComp;
	UPlayerMovementComponent MoveComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		AttackComp = USketchbookMeleeAttackPlayerComponent::Get(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FSketchbookMeleeWeaponAttackActivateParams& Params) const
	{
		// Have some input buffering
		if(!WasActionStartedDuringTime(Sketchbook::Melee::Attack, 0.1))
			return false;

		if(AttackComp.CurrentWeapon == nullptr)
			return false;

		if(!AttackComp.CanAttack())
			return false;

		const FVector HorizontalInput = MoveComp.MovementInput.VectorPlaneProject(FVector::UpVector);
		if(!HorizontalInput.IsNearlyZero())
		{
			// If we are giving input, use that direction
			Params.AttackDirection = HorizontalInput.GetSafeNormal();
		}
		else
		{
			Params.AttackDirection = Player.ActorForwardVector;
		}

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(AttackComp.CurrentWeapon == nullptr)
			return true;

		if(ActiveDuration >= AttackComp.AnimData.BlockAttackDuration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FSketchbookMeleeWeaponAttackActivateParams Params)
	{
		// Prevent the input buffering from triggering another attack
		Player.ConsumeButtonInputsRelatedTo(Sketchbook::Melee::Attack);

		WeaponComp = AttackComp.CurrentWeapon;

		FSketchbookMeleeAttackData AttackData = FSketchbookMeleeAttackData(WeaponComp.GetWeaponAttackLocation(), Params.AttackDirection, Player);
		AttackComp.Attack(AttackData);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}
};