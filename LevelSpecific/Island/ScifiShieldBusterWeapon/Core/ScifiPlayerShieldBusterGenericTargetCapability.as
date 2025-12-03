
class UScifiPlayerShieldBusterGenericTargetCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(n"ShieldBuster");
	
	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 110;

	default DebugCategory = n"ShieldBuster";

	UScifiPlayerShieldBusterManagerComponent Manager;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Manager = UScifiPlayerShieldBusterManagerComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(Manager.PendingTargetGenericImpacts.Num() > 0)
			return true;
	
		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Manager.PendingTargetGenericImpacts.Num() > 0)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{

	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{

	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Apply all new impacts
		for(auto NewImpact : Manager.PendingTargetGenericImpacts)
		{
			ApplyNewImpact(NewImpact);
		}
		Manager.PendingTargetGenericImpacts.Reset();
	}

	void ApplyNewImpact(FScifiPlayerShieldBusterWeaponImpact NewImpact)
	{
		// Broadcast to the generic impact respons component
		if(NewImpact.Actor != nullptr)
		{
			auto ImpactResponse = UScifiShieldBusterImpactResponseComponent::Get(NewImpact.Actor);
			ImpactResponse.OnApplyImpact(Player, NewImpact.Target);
		}

		// Trigger impact event
		FScifiPlayerShieldBusterOnImpactEventData ImpactData;
		ImpactData.ImpactLocation = NewImpact.ImpactLocation;
		ImpactData.ImpactTarget = NewImpact.Target;
		UScifiPlayerShieldBusterEventHandler::Trigger_OnImpact(Player, ImpactData);
	}
}