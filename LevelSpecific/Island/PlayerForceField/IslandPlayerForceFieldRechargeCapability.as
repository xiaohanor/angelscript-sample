class UIslandPlayerForceFieldRechargeCapability : UHazePlayerCapability
{
	UIslandForceFieldComponent ForceField;
	UIslandPlayerForceFieldUserComponent UserComp;

	const float ShieldRechargeRate = 0.5;
	const float ShieldDestroyedRechargeDelay = 5.0;
	const float ShieldUpRechargeDelay = 1.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		ForceField = UIslandForceFieldComponent::Get(Player);
		UserComp = UIslandPlayerForceFieldUserComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!ForceField.IsDamaged())
			return false;

		if(UserComp.bForceFieldIsDestroyed && Time::GetGameTimeSeconds() - UserComp.TimeOfLastForceFieldDamage < ShieldDestroyedRechargeDelay)
			return false;

		if(UserComp.bForceFieldActive && Time::GetGameTimeSeconds() - UserComp.TimeOfLastForceFieldDamage < ShieldUpRechargeDelay)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!ForceField.IsDamaged())
			return true;

		if(UserComp.bForceFieldIsDestroyed && Time::GetGameTimeSeconds() - UserComp.TimeOfLastForceFieldDamage < ShieldDestroyedRechargeDelay)
			return true;

		if(UserComp.bForceFieldActive && Time::GetGameTimeSeconds() - UserComp.TimeOfLastForceFieldDamage < ShieldUpRechargeDelay)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		ForceField.Replenish(ShieldRechargeRate * DeltaTime);
		if(!UserComp.bForceFieldActive)
			ForceField.Reset();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if(ForceField.IsFull())
			UserComp.bForceFieldIsDestroyed = false;
	}
}