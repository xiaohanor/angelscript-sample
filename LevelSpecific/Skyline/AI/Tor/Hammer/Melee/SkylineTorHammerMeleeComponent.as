event void FSkylineTorHammerMeleeComponentDealDamageEvent();

class USkylineTorHammerMeleeComponent : UActorComponent
{
	ESkylineTorHammerMeleeMode Mode;
	FSkylineTorHammerMeleeComponentDealDamageEvent OnDealDamage;
	bool bFirstAttack;

	UFUNCTION()
	void DealDamage()
	{
		OnDealDamage.Broadcast();
	}
}

enum ESkylineTorHammerMeleeMode
{
	Swing,
	Whirl,
	Smash
}