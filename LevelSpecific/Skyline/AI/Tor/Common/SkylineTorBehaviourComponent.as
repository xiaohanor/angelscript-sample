class USkylineTorBehaviourComponent : USceneComponent
{
	bool bIgnoreActivationRequirements;
	float CooldownTime;
	TMap<FName, FSkylineTorBehaviourComponentAttackIndexData> Indexes;

	int GetAttackIndex(FName CompoundName)
	{
		return Indexes[CompoundName].InternalAttackIndex;
	}

	void IncrementAttackIndex(FName CompoundName)
	{
		Indexes[CompoundName].InternalAttackIndex++;
		if(Indexes[CompoundName].InternalAttackIndex >= Indexes[CompoundName].MaxAttackIndex)
			Indexes[CompoundName].InternalAttackIndex = 0;
		CooldownTime = Time::GameTimeSeconds;
	}

	int GetNewAttackIndex(FName CompoundName)
	{
		if(!Indexes.Contains(CompoundName))
			Indexes.Add(CompoundName, FSkylineTorBehaviourComponentAttackIndexData());

		int Index = Indexes[CompoundName].MaxAttackIndex;
		Indexes[CompoundName].MaxAttackIndex++;
		return Index;
	}
}

struct FSkylineTorBehaviourComponentAttackIndexData
{
	int MaxAttackIndex;	
	int InternalAttackIndex;
}