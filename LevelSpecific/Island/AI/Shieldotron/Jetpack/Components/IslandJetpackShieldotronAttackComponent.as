enum EIslandJetpackShieldotronAttack
{	
	LemonHorizontal,
	LemonVertical,
	OrbAttack
}

class UIslandJetpackShieldotronAttackComponent : UActorComponent
{
	float NextAttackTime = 0;	
	int CurrentAttackIndex = 0;
	const int NumAttacks = 2;

	UIslandJetpackShieldotronSettings Settings;
	TMap<EIslandJetpackShieldotronAttack,int> AttackIndexLookupTable;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Settings = UIslandJetpackShieldotronSettings::GetSettings(Cast<AHazeActor>(Owner));
		//AttackIndexLookupTable.Add(EIslandJetpackShieldotronAttack::OrbAttack, 0);
		AttackIndexLookupTable.Add(EIslandJetpackShieldotronAttack::LemonHorizontal, 0);
		AttackIndexLookupTable.Add(EIslandJetpackShieldotronAttack::LemonVertical, 1);
	}

	void NextAttackIncrement()
	{
		CurrentAttackIndex = (CurrentAttackIndex + 1) % NumAttacks;
		check(CurrentAttackIndex >= 0, "CurrentAttackIndex out of bounds");
		NextAttackTime = Time::GameTimeSeconds + Math::RandRange(Settings.GeneralAttackMinCooldown, Settings.GeneralAttackMaxCooldown);
	}

	void NextAttackAfter(EIslandJetpackShieldotronAttack Attack)
	{
		int AttackIndex = -1;
		AttackIndexLookupTable.Find(Attack, AttackIndex);
		check(AttackIndex >= 0, "AttackIndex out of bounds");

		CurrentAttackIndex = (AttackIndex + 1) % NumAttacks;
		check(CurrentAttackIndex >= 0, "CurrentAttackIndex out of bounds");
		
		// Only cooldown between orbs and lemons
		if (CurrentAttackIndex != 2)
			NextAttackTime = Time::GameTimeSeconds + Math::RandRange(Settings.GeneralAttackMinCooldown, Settings.GeneralAttackMaxCooldown);
	}

	EIslandJetpackShieldotronAttack GetCurrentAttack()
	{
		EIslandJetpackShieldotronAttack Attack = EIslandJetpackShieldotronAttack(CurrentAttackIndex);
		return Attack;
	}

	bool CanAttack(EIslandJetpackShieldotronAttack Attack)
	{
		if (Time::GameTimeSeconds < NextAttackTime)
			return false;
		if (Attack != GetCurrentAttack())
			return false;

		return true;
	}
	
};