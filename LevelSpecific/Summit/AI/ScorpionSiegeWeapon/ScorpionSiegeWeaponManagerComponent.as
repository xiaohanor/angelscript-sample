class UScorpionSiegeWeaponManagerComponent : UActorComponent
{
	AScorpionSiegeWeapon Weapon;
	TArray<AScorpionSiegeOperator> Operators;

	private int ActiveOperatorsInternal = 0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Weapon = Cast<AScorpionSiegeWeapon>(Owner);
	}

	void Reset()
	{
		for(AScorpionSiegeOperator Operator: Operators)
		{
			Operator.OperationComp.bOperating = false;
		}
		Operators.Empty();
		ActiveOperatorsInternal = 0;
	}

	bool CanApproach()
	{
		return Operators.Num() < Weapon.WantedOperators;
	}

	void Approach(AScorpionSiegeOperator Operator)
	{
		if(!CanApproach()) return;
		Operator.OperationComp.TargetWeapon = Weapon;
		Operators.Add(Operator);
		Operator.OperationComp.OperatorSlot = Weapon.OperatorSlots[Operators.FindIndex(Operator)];
	}

	bool CanOperate(AScorpionSiegeOperator Operator)
	{
		return Operators.Contains(Operator) && ActiveOperatorsInternal < Weapon.WantedOperators;
	}

	bool Operate(AScorpionSiegeOperator Operator)
	{
		if(!CanOperate(Operator))
			return false;

		ActiveOperatorsInternal++;
		Operator.OperationComp.bOperating = true;
		return true;
	}

	int GetActiveOperators() property
	{
		return ActiveOperatorsInternal;
	}
}