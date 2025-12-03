struct FDragonSwordCombatAttackAnimationData
{
	private bool bIsValid = false;
	private FDragonSwordAttackSequenceData Sequence_Internal;
	private int AttackIndex_Internal = -1;
	private int SequenceIndex_Internal = -1;

	FDragonSwordCombatAttackAnimationData(FDragonSwordAttackSequenceData InSequence, int InAttackIndex, int InSequenceIndex)
	{
		if(InSequence.Attacks.Num() == 0)
		{
			return;	
		}

		if(InAttackIndex < 0 || InAttackIndex >= InSequence.Attacks.Num())
		{
			return;
		}

		Sequence_Internal = InSequence;
		AttackIndex_Internal = InAttackIndex;
		SequenceIndex_Internal = InSequenceIndex;

		bIsValid = true;
	}

	bool IsValid() const
	{
		if(!bIsValid)
			return false;

		if(AttackIndex_Internal < 0)
			return false;

		if(SequenceIndex_Internal < 0)
			return false;

		return true;
	}

	void Invalidate()
	{
		bIsValid = false;
		AttackIndex_Internal = -1;
		SequenceIndex_Internal = -1;
	}

	FDragonSwordAttackSequenceData GetSequence() const property
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
		return SequenceIndex_Internal;
	}

	UDragonSwordAttackData GetAttackData() const property
	{
		check(IsValid());
		return Sequence_Internal.Attacks[AttackIndex_Internal];
	}

	float GetPlayLength() const property
	{
		return Sequence_Internal.Attacks[AttackIndex_Internal].Animation.Sequence.PlayLength;
	}
}