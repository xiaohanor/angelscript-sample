UCLASS(Abstract)
class UGameplay_Gadget_Player_Nunchucks_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void AttackImpact(FIslandNunchuckEffectHandlerAttackImpactData Data){}

	UFUNCTION(BlueprintEvent)
	void NunchuckDeactivated(){}

	UFUNCTION(BlueprintEvent)
	void NunchuckActivated(){}

	UFUNCTION(BlueprintEvent)
	void AttackCompleted(FIslandNunchuckAttackData Data){}

	UFUNCTION(BlueprintEvent)
	void AttackStarted(FIslandNunchuckAttackData Data){}

	/* END OF AUTO-GENERATED CODE */

	UPROPERTY()
	UPlayerIslandNunchuckUserComponent NunchuckComponent;

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		GetNunchuckComponent();
	}

	// Cache or Get NunchuckComponent so we can use it during SD attachment-setup.
	UFUNCTION(BlueprintPure)
	UPlayerIslandNunchuckUserComponent GetNunchuckComponent()
	{
		if (NunchuckComponent != nullptr)
			return NunchuckComponent;

		NunchuckComponent = UPlayerIslandNunchuckUserComponent::Get(PlayerOwner);

		return NunchuckComponent;
	}


}