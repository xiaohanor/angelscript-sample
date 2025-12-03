class AGravityBladeAirAttackAllowHoverVolume : APlayerTrigger
{
	void TriggerOnPlayerEnter(AHazePlayerCharacter Player) override
	{
		Super::TriggerOnPlayerEnter(Player);

		auto CombatComp = UGravityBladeCombatUserComponent::Get(Player);
		if (CombatComp != nullptr)
			CombatComp.AllowAirAttackHover.Apply(true, this);
	}

	void TriggerOnPlayerLeave(AHazePlayerCharacter Player) override
	{
		Super::TriggerOnPlayerLeave(Player);
		
		auto CombatComp = UGravityBladeCombatUserComponent::Get(Player);
		if (CombatComp != nullptr)
			CombatComp.AllowAirAttackHover.Clear(this);
	}
}