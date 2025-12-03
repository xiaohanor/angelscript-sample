
class UContextualCombatTargetingCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(n"Example");
	
	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 100;

	UPlayerTargetablesComponent PlayerTargetablesComponent;
	UPlayerContextualCombatTargetingComponent TargetingComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PlayerTargetablesComponent = UPlayerTargetablesComponent::Get(Player);
		TargetingComp = UPlayerContextualCombatTargetingComponent::Get(Player);

	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return false;
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
		PlayerTargetablesComponent.ShowWidgetsForTargetables(UContextualCombatTargetableComponent, TargetingComp.DefaultContextualCombatWidget);
	}
};