
UCLASS(Abstract)
class UGravityBladeFlameEventHandler : UGravityBladeCombatEventHandler
{
	// Called when the flame is added to the blade
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void FlameOn() { }

	// Called when the flame is removed
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void FlameOff() { }

	UFUNCTION(BlueprintPure)
	bool IsSwinging() const 
	{
		auto UserComp = UGravityBladeCombatUserComponent::Get(Game::Mio);
		if(UserComp == nullptr)
			return false;

		return UserComp.HasActiveAttack();
	}
}