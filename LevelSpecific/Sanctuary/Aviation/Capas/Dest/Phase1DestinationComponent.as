class USanctuaryCompanionAviationDestinationComponent : UActorComponent
{
	bool bShouldTriggerSwoopInAttack = false;
	bool bAttackClockwise = true;

	float GetSignClockwiseAttack() const
	{
		return bAttackClockwise ? 1.0 : -1.0;
	}

	// -----------------------------------

	bool bDevTriggerSwoopOutSequence = false;
	UFUNCTION(DevFunction, meta = (Category = "Aviation"))
	void DevTriggerSwoopOutSequence()
	{
		bDevTriggerSwoopOutSequence = true;
	}

	bool bDevTriggerSwoopOutNormal = false;
	// UFUNCTION(DevFunction, meta = (Category = "Aviation"))
	// void DevTriggerSwoopOutNormal()
	// {
	// 	bDevTriggerSwoopOutNormal = true;
	// }

	bool bDevTriggerSwoopInInitAttack = false;
	UFUNCTION(DevFunction, meta = (Category = "Aviation"))
	void DevTriggerSwoopInAttackSequence()
	{
		bDevTriggerSwoopInInitAttack = true;
	}
};