struct FGravityBladeCombatAttackAnimationData
{
	private bool bIsValid = false;
	private FGravityBladeAttackSequenceData Sequence_Internal;
	private bool bIsInteractionAttack_Internal = false;
	private int AttackIndex_Internal = -1;
	private int SequenceIndex_Internal = -1;

	FGravityBladeCombatAttackAnimationData(FGravityBladeAttackSequenceData InSequence, int InAttackIndex, bool bIsInteractionAttack = false, int InSequenceIndex = -1)
	{
		if(InSequence.Attacks.Num() == 0)
			return;

		if(InAttackIndex < 0 || InAttackIndex >= InSequence.Attacks.Num())
			return;

		Sequence_Internal = InSequence;
		AttackIndex_Internal = InAttackIndex;

		if(bIsInteractionAttack)
		{
			bIsInteractionAttack_Internal = true;
		}
		else
		{
			SequenceIndex_Internal = InSequenceIndex;
		}

		bIsValid = true;
	}

	bool IsValid() const
	{
		if(!bIsValid)
			return false;

		if(AttackIndex_Internal < 0)
			return false;

		if(SequenceIndex_Internal < 0 && !bIsInteractionAttack_Internal)
			return false;

		return true;
	}

	void Invalidate()
	{
		bIsValid = false;
		AttackIndex_Internal = -1;
		SequenceIndex_Internal = -1;
		bIsInteractionAttack_Internal = false;
	}

	bool IsInteractionAttack() const
	{
		check(IsValid());
		return bIsInteractionAttack_Internal;
	}

	FGravityBladeAttackSequenceData GetSequence() const property
	{
		check(IsValid());
		return Sequence_Internal;
	}

	int GetAttackIndex() const property
	{
		check(IsValid());
		return AttackIndex_Internal;
	}

	int GetSequenceIndex() const property
	{
		check(IsValid());
		check(!IsInteractionAttack());
		return SequenceIndex_Internal;
	}

	FGravityBladeCombatAttackAnimationWithMetaData GetAnimationWithMetaData() const property
	{
		check(IsValid());
		return Sequence_Internal.Attacks[AttackIndex_Internal];
	}

	FGravityBladeCombatAttackAnimationMetaData GetAttackMetaData() const property
	{
		check(IsValid());
		return Sequence_Internal.Attacks[AttackIndex_Internal].AttackMetaData;
	}
}