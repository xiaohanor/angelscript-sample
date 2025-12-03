event void FSanctuaryWeeperFreezeSignature();
event void FSanctuaryWeeperUnfreezeSignature();

class USanctuaryWeeperFreezeComponent : UActorComponent
{
	private bool bFrozen;
	bool bPermanentFreeze;
	FSanctuaryWeeperFreezeSignature OnFreeze;
	FSanctuaryWeeperFreezeSignature OnUnfreeze;

	void Freeze()
	{
		bool bCurrentFrozen = bFrozen;
		bFrozen = true;
		if(!bCurrentFrozen)
			OnFreeze.Broadcast();		
	}

	void Unfreeze()
	{
		bool bCurrentFrozen = bFrozen;
		bFrozen = false;
		if(bCurrentFrozen)
			OnUnfreeze.Broadcast();		
	}

	bool IsFrozen()
	{
		return bFrozen;
	}
}