
class UScifiPlayerGravityGrenadeGenericTargetCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(n"GravityGrenade");
	
	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 110;

	default DebugCategory = n"GravityGrenade";

	UScifiPlayerGravityGrenadeManagerComponent Manager;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Manager = UScifiPlayerGravityGrenadeManagerComponent::Get(Player);
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

	void ApplyNewImpact(FScifiPlayerGravityGrenadeWeaponImpact NewImpact)
	{
		// Broadcast to the generic impact respons component
		if(NewImpact.Actor != nullptr)
		{
			auto ImpactResponse = UScifiGravityGrenadeImpactResponseComponent::Get(NewImpact.Actor);
			ImpactResponse.OnApplyImpact(Player, NewImpact.Target);
		}

		// Trigger impact event
		FScifiPlayerGravityGrenadeOnImpactEventData ImpactData;
		ImpactData.ImpactLocation = NewImpact.ImpactLocation;
		ImpactData.ImpactTarget = NewImpact.Target;
		UScifiPlayerGravityGrenadeEventHandler::Trigger_OnImpact(Player, ImpactData);
	}
}