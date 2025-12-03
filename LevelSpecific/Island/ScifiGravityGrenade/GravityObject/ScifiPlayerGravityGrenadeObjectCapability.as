
class UScifiPlayerGravityGrenadeObjectCapability : UHazePlayerCapability
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
		if(Manager.PendingGravityObjectImpacts.Num() > 0)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Manager.PendingGravityObjectImpacts.Num() > 0)
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
		for(auto NewImpact : Manager.PendingGravityObjectImpacts)
		{
			ApplyNewImpact(NewImpact);
		}
		Manager.PendingGravityObjectImpacts.Reset();

	}

	void ApplyNewImpact(FScifiGravityGrenadePendingGravityObjectImpactData NewImpact)
	{
		auto ImpactComponent = UScifiGravityGrenadeImpactResponseComponent::Get(NewImpact.Impact.Actor);
		auto Target = Cast<UScifiGravityGrenadeTargetableComponent>(NewImpact.Impact.Target);

		auto GravityGrenadeObject = Cast<AScifiGravityGrenadeObject>(NewImpact.Impact.Actor);

		GravityGrenadeObject.OnImpact(Player, Target);

		// Broadcast to the generic impact respons component
		ImpactComponent.OnApplyImpact(Player, Target);
		
		// Trigger impact event
		FScifiPlayerGravityGrenadeOnImpactEventData ImpactData;
		ImpactData.ImpactLocation = NewImpact.Impact.ImpactLocation;
		ImpactData.ImpactTarget = NewImpact.Impact.Target;
		UScifiPlayerGravityGrenadeEventHandler::Trigger_OnImpact(Player, ImpactData);
	}
};