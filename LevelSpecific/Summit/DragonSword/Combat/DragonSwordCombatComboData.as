struct FDragonSwordCombatComboDataEntry
{
	bool bIsValid;
	FDragonSwordCombatAttackTypeData AttackTypeData;
	int Length = 0;
	int AttackIndex = 0;

	FDragonSwordCombatComboDataEntry(FDragonSwordCombatAttackTypeData InAttackTypeData, int InComboLength, int InAttackIndex = 0)
	{
		AttackTypeData = InAttackTypeData;
		Length = InComboLength;
		AttackIndex = InAttackIndex;
		check(Length > 0);
		bIsValid = true;
	}

	bool HasFinishedCombo() const
	{
		return AttackIndex >= (Length - 1);
	}

	void Reset()
	{
		bIsValid = false;
		AttackIndex = 0;
	}
}

enum EDragonSwordCombatComboResult
{
	Stop,
	Continue,
	Reset
}

struct FDragonSwordCombatComboData
{
	private bool bIsValid = false;
	private TArray<FDragonSwordCombatComboDataEntry> ComboEntries_Internal;
	private FDragonSwordCombatComboDataEntry MostRecentComboEntry_Internal;
	private UDragonSwordCombatUserComponent CombatComp_Internal;

	FDragonSwordCombatComboData(FDragonSwordCombatAttackData InAttackData, UDragonSwordCombatUserComponent CombatComp)
	{
		if (!InAttackData.IsValid())
			return;

		AddAttack(InAttackData);
		CombatComp_Internal = CombatComp;

		bIsValid = true;
	}

	bool IsValid() const
	{
		if (!bIsValid)
			return false;

		if (ComboEntries_Internal.Num() == 0)
			return false;

		bool bHadValidCombo = false;
		for (auto& Combo : ComboEntries_Internal)
		{
			if (Combo.bIsValid)
			{
				bHadValidCombo = true;
				break;
			}
		}

		return bHadValidCombo;
	}

	void Invalidate()
	{
		check(bIsValid);
		bIsValid = false;
		ComboEntries_Internal.Reset();
		MostRecentComboEntry_Internal.bIsValid = false;
	}

	void AddAttack(FDragonSwordCombatAttackData InAttackData)
	{
		int Index;
		int ComboLength = InAttackData.AnimationData.Sequence.Attacks.Num();
		auto AttackTypeDataType = InAttackData.AttackTypeData.ToType();
		if (Find(AttackTypeDataType, Index))
		{
			if (ComboEntries_Internal[Index].AttackIndex == ComboEntries_Internal[Index].Length - 1)
				ComboEntries_Internal[Index].AttackIndex = 0;
			else
				ComboEntries_Internal[Index].AttackIndex++;

			// Do this since we might be in a new sequence with a different length
			ComboEntries_Internal[Index].Length = ComboLength;

			MostRecentComboEntry_Internal = ComboEntries_Internal[Index];
		}
		else
		{
			if (AttackTypeDataType == EDragonSwordCombatAttackType::Dash && HasMostRecentAttack() && MostRecentAttackType.ToType() == EDragonSwordCombatAttackType::DashRush)
			{
				int Length = ComboLength;
				FDragonSwordCombatComboDataEntry Entry(InAttackData.AttackTypeData, Length, 1);
				ComboEntries_Internal.Add(Entry);
				MostRecentComboEntry_Internal = Entry;
			}
			else
			{
				int Length = ComboLength;
				FDragonSwordCombatComboDataEntry Entry(InAttackData.AttackTypeData, Length, InAttackData.AnimationData.AttackIndex);
				ComboEntries_Internal.Add(Entry);
				MostRecentComboEntry_Internal = Entry;
			}
		}
	}

	void ResetCombo(FDragonSwordCombatAttackTypeData InAttackTypeData)
	{
		int Index = 0;
		if (Find(InAttackTypeData.ToType(), Index))
		{
			ComboEntries_Internal[Index].Reset();
		}
		else
		{
			return;
		}
	}

	bool CanContinueCombo(EDragonSwordCombatAttackType InAttackType) const
	{
		EDragonSwordCombatAttackType OutAttackType;
		int OutAttackIndex;
		int OutSequenceIndex;
		bool bCanContinue = CanContinueCombo(FDragonSwordCombatAttackTypeData(InAttackType), OutAttackType, OutAttackIndex, OutSequenceIndex);

		if (InAttackType != OutAttackType)
			return false;

		return bCanContinue;
	}

	bool CanContinueCombo(EDragonSwordCombatAttackType InAttackType, EDragonSwordCombatAttackType&out OutAttackType, int&out OutAttackIndex, int&out OutSequenceIndex) const
	{
		return CanContinueCombo(FDragonSwordCombatAttackTypeData(InAttackType), OutAttackType, OutAttackIndex, OutSequenceIndex);
	}

	bool CanContinueCombo(FDragonSwordCombatAttackTypeData InAttackTypeData, EDragonSwordCombatAttackType&out OutAttackType, int&out OutAttackIndex, int&out OutSequenceIndex) const
	{
		EDragonSwordCombatAttackType CustomComboAttackType;
		const EDragonSwordCombatComboResult ComboResult = GetContinueCombo_Internal(InAttackTypeData, CustomComboAttackType, OutAttackIndex);

		// If CanContinueCombo_Internal returned a custom attack type, use that
		OutAttackType = CustomComboAttackType != EDragonSwordCombatAttackType::INVALID ? CustomComboAttackType : InAttackTypeData.ToType();

		EDragonSwordAttackMovementType MovementType = FDragonSwordCombatAttackTypeData(OutAttackType).GetMovementType();
		OutSequenceIndex = CombatComp_Internal.GetSequenceIndexForType(MovementType);

		switch (ComboResult)
		{
			case EDragonSwordCombatComboResult::Continue:
			{
				int Index;
				if (Find(OutAttackType, Index))
				{
					FDragonSwordAttackDefinition AttackDef = CombatComp_Internal.GetAttackDefinitionFromAttackType(OutAttackType);
					const auto& It = ComboEntries_Internal[Index];
					if (AttackDef.bCanWrap && It.AttackIndex == It.Length - 1)
					{
						// If we can wrap we want to continue but prwogress to a new sequence and start from index 0.
						OutAttackIndex = 0;
						OutSequenceIndex = CombatComp_Internal.ProgressToNextSequenceForType(MovementType);
						return true;
					}

					if (MostRecentComboEntry_Internal.AttackTypeData.ToType() != OutAttackType)
						OutAttackIndex = 0;
					else
						OutAttackIndex = (It.AttackIndex + 1);
				}

				// In some cases the first attack in the attack type might start out at -1 so in that case we just progress to next
				if (OutSequenceIndex == -1)
				{
					OutSequenceIndex = CombatComp_Internal.ProgressToNextSequenceForType(MovementType);
				}

				return true;
			}

			case EDragonSwordCombatComboResult::Reset:
			{
				OutAttackIndex = 0;
				OutSequenceIndex = CombatComp_Internal.ProgressToNextSequenceForType(MovementType);
				return true;
			}

			case EDragonSwordCombatComboResult::Stop:
			{
				OutAttackType = EDragonSwordCombatAttackType::INVALID;
				OutAttackIndex = -1;
				return false;
			}
			default:
				return false;
		}
	}

	private EDragonSwordCombatComboResult GetContinueCombo_Internal(FDragonSwordCombatAttackTypeData InAttackTypeData, EDragonSwordCombatAttackType&out OutAttackType, int&out OutAttackIndex) const
	{
		check(IsValid());

		OutAttackType = EDragonSwordCombatAttackType::INVALID;
		OutAttackIndex = 0;

		if (InAttackTypeData.IsCharge() && HasAttack(InAttackTypeData.ToType()))
			return EDragonSwordCombatComboResult::Stop;

		if (MostRecentAttackType.ToType() == InAttackTypeData.ToType())
		{
			if (HasTypeFinishedCombo(InAttackTypeData.ToType()))
			{
				if (InAttackTypeData.IsSprint())
				{
					// Reset to Ground attacks if we are finished with sprint attacks
					OutAttackType = EDragonSwordCombatAttackType::Ground;
					return EDragonSwordCombatComboResult::Reset;
				}
				else
				{
					return EDragonSwordCombatComboResult::Stop;
				}
			}
			else
			{
				return EDragonSwordCombatComboResult::Continue;
			}
		}
		else
		{
			// This is a new attack type, check if it can follow the previous attack
			switch (InAttackTypeData.ToType())
			{
				case EDragonSwordCombatAttackType::Air:
				{
					if (HasTypeFinishedCombo(EDragonSwordCombatAttackType::Air))
					{
						return EDragonSwordCombatComboResult::Stop;
					}
					else if (MostRecentAttackType.ToType() == EDragonSwordCombatAttackType::AirRush)
					{
						OutAttackIndex = 1;
						return EDragonSwordCombatComboResult::Continue;
					}
					break;
				}

				case EDragonSwordCombatAttackType::AirRush:
				{
					if (HasTypeFinishedCombo(EDragonSwordCombatAttackType::AirRush))
					{
						return EDragonSwordCombatComboResult::Stop;
					}
					break;
				}

				case EDragonSwordCombatAttackType::Dash:
				{
					if (MostRecentAttackType.ToType() == EDragonSwordCombatAttackType::Air)
					{
						return EDragonSwordCombatComboResult::Reset;
					}

					if (MostRecentAttackType.ToType() == EDragonSwordCombatAttackType::DashRush)
					{
						if (HasTypeFinishedCombo(EDragonSwordCombatAttackType::Dash))
						{
							return EDragonSwordCombatComboResult::Stop;
						}
						else
						{
							OutAttackIndex = 1;
							return EDragonSwordCombatComboResult::Continue;
						}
					}
					break;
				}

				case EDragonSwordCombatAttackType::DashRush:
				{
					if (HasTypeFinishedCombo(MostRecentAttackType.ToType()))
						return EDragonSwordCombatComboResult::Stop;
					else
						return EDragonSwordCombatComboResult::Continue;
				}

				case EDragonSwordCombatAttackType::Ground:
				{
					if (MostRecentAttackType.ToType() == EDragonSwordCombatAttackType::GroundRush)
					{
						OutAttackIndex = 1;
						return EDragonSwordCombatComboResult::Continue;
					}
					break;
				}

				case EDragonSwordCombatAttackType::GroundRush:
					break;

				case EDragonSwordCombatAttackType::Charge:
					return EDragonSwordCombatComboResult::Stop;

				case EDragonSwordCombatAttackType::Jump:
					break;

				case EDragonSwordCombatAttackType::Sprint:
					break;
				default:
					break;
			}

			return EDragonSwordCombatComboResult::Continue;
		}
	}

	private bool HasTypeFinishedCombo(EDragonSwordCombatAttackType InAttackType) const
	{
		FDragonSwordAttackDefinition AttackDef = CombatComp_Internal.GetAttackDefinitionFromAttackType(InAttackType);
		if (AttackDef.bCanWrap)
			return false;

		int Index = 0;
		if (Find(InAttackType, Index))
		{
			return ComboEntries_Internal[Index].HasFinishedCombo();
		}
		else
		{
			return false;
		}
	}

	private int GetTypeAttackIndex(EDragonSwordCombatAttackType InAttackType) const
	{
		int Index = 0;
		if (Find(InAttackType, Index))
		{
			return ComboEntries_Internal[Index].AttackIndex;
		}
		else
		{
			return -1;
		}
	}

	private bool Find(EDragonSwordCombatAttackType InAttackType, int&out Index) const
	{
		for (int i = 0; i < ComboEntries_Internal.Num(); i++)
		{
			if (ComboEntries_Internal[i].AttackTypeData.ToType() == InAttackType)
			{
				Index = i;
				return true;
			}
		}

		Index = 0;
		return false;
	}

	bool HasAttack(EDragonSwordCombatAttackType InAttackType) const
	{
		int Index = 0;
		return Find(InAttackType, Index);
	}

	bool HasAttack(EDragonSwordAttackMovementType InAttackMovementType) const
	{
		for (int i = 0; i < ComboEntries_Internal.Num(); i++)
		{
			if (ComboEntries_Internal[i].AttackTypeData.GetMovementType() == InAttackMovementType)
				return true;
		}

		return false;
	}

	TArray<FDragonSwordCombatAttackTypeData> GetAttackTypeDatas() const
	{
		TArray<FDragonSwordCombatAttackTypeData> _AttackTypeDatas;
		for (int i = 0; i < ComboEntries_Internal.Num(); i++)
		{
			_AttackTypeDatas.Add(ComboEntries_Internal[i].AttackTypeData);
		}
		return _AttackTypeDatas;
	}

	bool HasMostRecentAttack() const
	{
		if (!IsValid())
			return false;

		return MostRecentComboEntry_Internal.bIsValid;
	}

	FDragonSwordCombatAttackTypeData GetMostRecentAttackType() const property
	{
		check(IsValid());
		return MostRecentComboEntry_Internal.AttackTypeData;
	}

	int GetMostRecentAttackIndex() const property
	{
		check(IsValid());
		return MostRecentComboEntry_Internal.AttackIndex;
	}

	FDragonSwordCombatComboDataEntry GetComboEntry(EDragonSwordCombatAttackType InAttackType) const
	{
		int Index = 0;
		if (Find(InAttackType, Index))
		{
			return ComboEntries_Internal[Index];
		}
		else
		{
			return FDragonSwordCombatComboDataEntry();
		}
	}
}