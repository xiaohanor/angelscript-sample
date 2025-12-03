
UCLASS(Abstract)
class UWorld_Skyline_Shared_Interactable_GravityBladeTargetable_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	/* END OF AUTO-GENERATED CODE */

	UGravityBladeCombatTargetComponent TargetComp;
	UGravityBladeCombatResponseComponent CombatResponseComp;
	UGravityBladeGrappleResponseComponent GrappleResponseComp;

	bool GetbIsGrappleable() const property
	{
		return GrappleResponseComp != nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		TargetComp = UGravityBladeCombatTargetComponent::Get(HazeOwner);
		CombatResponseComp = UGravityBladeCombatResponseComponent::Get(HazeOwner);
		GrappleResponseComp = UGravityBladeGrappleResponseComponent::Get(HazeOwner);

	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		if(!CombatResponseComp.IsResponseComponentDisabled())
			OnBladeTargetActivate();

		if(CombatResponseComp != nullptr)
		{
			CombatResponseComp.OnResponseEnabled.AddUFunction(this, n"OnBladeTargetActivate");
			CombatResponseComp.OnResponseDisabled.AddUFunction(this, n"OnBladeTargetDeactivate");
			CombatResponseComp.OnHit.AddUFunction(this, n"OnBladeHit");
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if(CombatResponseComp != nullptr)
		{
			CombatResponseComp.OnResponseEnabled.Unbind(this, n"OnBladeTargetActivate");
			CombatResponseComp.OnResponseDisabled.Unbind(this, n"OnBladeTargetDeactivate");
			CombatResponseComp.OnHit.Unbind(this, n"OnBladeHit");
		}
	}

	UFUNCTION(BlueprintEvent)
	void OnBladeTargetActivate() {}

	UFUNCTION(BlueprintEvent)
	void OnBladeTargetDeactivate() {}

	UFUNCTION(BlueprintEvent)
	void OnBladeHit(UGravityBladeCombatUserComponent UserComp, FGravityBladeHitData HitData) {}
}