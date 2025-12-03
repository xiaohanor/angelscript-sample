
class UScifiPlayerShieldBusterFieldCapability : UHazePlayerCapability
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
		if(Manager.PendingFieldImpacts.Num() > 0)
			return true;

		if(Manager.ActiveFieldBreakers.Num() > 0)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Manager.PendingFieldImpacts.Num() > 0)
			return false;

		if(Manager.ActiveFieldBreakers.Num() > 0)
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
		for(auto NewImpact : Manager.PendingFieldImpacts)
		{
			ApplyNewImpact(NewImpact);
		}
		Manager.PendingFieldImpacts.Reset();

		// Update all current impacts
		for(int i = Manager.ActiveFieldBreakers.Num() - 1; i >= 0; --i)
		{
			auto Breaker = Manager.ActiveFieldBreakers[i];

			auto BreakerSettings = Breaker.CurrentBreakingField.GetSettings();			

			float ActiveTime = Time::GetGameTimeSince(Breaker.LastImpactTime);
			if(ActiveTime <= BreakerSettings.Lifetime)
				continue;
			
			Breaker.CurrentBreakingField.RecoverField(Breaker);
			Manager.ActiveFieldBreakers.RemoveAtSwap(i);
		}
	}

	void ApplyNewImpact(FScifiShieldBusterPendingFieldImpactData NewImpact)
	{
		auto Field = UScifiShieldBusterField::Get(NewImpact.Impact.Actor);
		auto FieldTarget = Cast<UScifiShieldBusterFieldTargetableComponent>(NewImpact.Impact.Target);

		// Add breaker
		auto Breaker = UScifiShieldBusterInternalFieldBreaker();
		Breaker.CurrentBreakingField = Field;
		Breaker.LinkedTargetComponent = FieldTarget;
		Breaker.LastImpactTime = Time::GetGameTimeSeconds();
		Manager.ActiveFieldBreakers.Add(Breaker);

		Field.BreakField(Breaker);

		// Broadcast to the generic impact respons component
		Field.ImpactResponse.OnApplyImpact(Player, FieldTarget);
		
		// Trigger impact event
		FScifiPlayerShieldBusterOnImpactEventData ImpactData;
		ImpactData.ImpactLocation = NewImpact.Impact.ImpactLocation;
		ImpactData.ImpactTarget = NewImpact.Impact.Target;
		UScifiPlayerShieldBusterEventHandler::Trigger_OnImpact(Player, ImpactData);
	}
};