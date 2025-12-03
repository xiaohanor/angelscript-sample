struct FDragonSwordCombatAttackTypeData
{
	private bool bIsValid_Internal = false;
	private EDragonSwordAttackMovementType MovementType_Internal;

	FDragonSwordCombatAttackTypeData(EDragonSwordAttackMovementType InMovementType, bool bInIsRush = false)
	{
		MovementType_Internal = InMovementType;
		bIsValid_Internal = true;
	}

	FDragonSwordCombatAttackTypeData(EDragonSwordCombatAttackType InAttackType)
	{
		switch (InAttackType)
		{
			case EDragonSwordCombatAttackType::Air:
				MovementType_Internal = EDragonSwordAttackMovementType::Air;
				break;

			case EDragonSwordCombatAttackType::Dash:
				MovementType_Internal = EDragonSwordAttackMovementType::Dash;
				break;

			case EDragonSwordCombatAttackType::Ground:
				MovementType_Internal = EDragonSwordAttackMovementType::Ground;
				break;

			case EDragonSwordCombatAttackType::Charge:
				MovementType_Internal = EDragonSwordAttackMovementType::Charge;
				break;

			case EDragonSwordCombatAttackType::Sprint:
				MovementType_Internal = EDragonSwordAttackMovementType::Sprint;
				break;

			default:
				check(false);
				return;
		}

		bIsValid_Internal = true;
	}

	bool IsValid() const
	{
		return bIsValid_Internal;
	}

	bool IsRegularAttack() const
	{
		return true;
	}

	bool IsAir() const
	{
		check(IsValid());
		return MovementType_Internal == EDragonSwordAttackMovementType::Air;
	}

	bool IsDash() const
	{
		check(IsValid());
		return MovementType_Internal == EDragonSwordAttackMovementType::Dash;
	}

	bool IsGround() const
	{
		check(IsValid());
		return MovementType_Internal == EDragonSwordAttackMovementType::Ground;
	}

	bool IsSprint() const
	{
		check(IsValid());
		return MovementType_Internal == EDragonSwordAttackMovementType::Sprint;
	}

	bool IsCharge() const
	{
		check(IsValid());
		return MovementType_Internal == EDragonSwordAttackMovementType::Charge;
	}

	EDragonSwordAttackMovementType GetMovementType() const
	{
		check(IsValid());
		return MovementType_Internal;
	}

	EDragonSwordCombatAttackType ToType() const
	{
		if (!bIsValid_Internal)
			return EDragonSwordCombatAttackType::INVALID;

		switch (MovementType_Internal)
		{
			case EDragonSwordAttackMovementType::Air:
			{
				return EDragonSwordCombatAttackType::Air;
			}

			case EDragonSwordAttackMovementType::Dash:
			{
				return EDragonSwordCombatAttackType::Dash;
			}

			case EDragonSwordAttackMovementType::Ground:
			{
				return EDragonSwordCombatAttackType::Ground;
			}

			case EDragonSwordAttackMovementType::Sprint:
			{
				return EDragonSwordCombatAttackType::Sprint;
			}

			case EDragonSwordAttackMovementType::Charge:
				return EDragonSwordCombatAttackType::Charge;

			default:
				break;
		}

		check(false);
		return EDragonSwordCombatAttackType::INVALID;
	}
}

enum EDragonSwordCombatAttackType
{
	INVALID,

	Ground,
	GroundRush,

	Air,
	AirRush,

	Dash,
	DashRush,

	Sprint,

	Jump,

	Charge
}