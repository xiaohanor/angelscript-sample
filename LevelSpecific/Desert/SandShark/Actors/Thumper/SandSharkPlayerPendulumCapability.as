struct FSandSharkPendulumActivatedParams
{
	USandSharkPendulumComponent PendulumComp;
}
class USandSharkPlayerPendulumCapability : UHazeCapability
{
	default CapabilityTags.Add(n"Interaction");
	default CapabilityTags.Add(n"BlockedByCutscene");
	default CapabilityTags.Add(n"BlockedWhileDead");

	default DebugCategory = n"Interaction";
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default TickGroup = EHazeTickGroup::Input;
	default TickGroupOrder = 29;

	AHazePlayerCharacter Player;
	UDesertPlayerPendulumComponent PendulumUserComponent;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		PendulumUserComponent = UDesertPlayerPendulumComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FSandSharkPendulumActivatedParams& Params) const
	{
		if (PendulumUserComponent.CurrentPendulum == nullptr)
			return false;

		if (!WasActionStarted(ActionNames::Interaction))
			return false;

		Params.PendulumComp = PendulumUserComponent.CurrentPendulum;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FSandSharkPendulumActivatedParams Params)
	{
		auto CurrentPendulum = Params.PendulumComp;
		CurrentPendulum.DoPlayerPress(Player);
	}
}