class UDentistToothDoubleCannonActiveCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::BeforeGameplay;

	UDentistToothDoubleCannonComponent CannonComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		CannonComp = UDentistToothDoubleCannonComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!IsActivelyInCannon())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!IsActivelyInCannon())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.BlockCapabilitiesExcluding(CapabilityTags::Movement, Dentist::DoubleCannon::DentistDoubleCannonBlockExclusionTag, this);
		Player.BlockCapabilities(Dentist::Tags::Dash, this);
		Player.BlockCapabilities(Dentist::Tags::GroundPound, this);
		Player.BlockCapabilities(Dentist::Tags::Jump, this);
		Player.BlockCapabilities(Dentist::Tags::Ragdoll, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(CapabilityTags::Movement, this);
		Player.UnblockCapabilities(Dentist::Tags::Dash, this);
		Player.UnblockCapabilities(Dentist::Tags::GroundPound, this);
		Player.UnblockCapabilities(Dentist::Tags::Jump, this);
		Player.UnblockCapabilities(Dentist::Tags::Ragdoll, this);
	}
	
	bool IsActivelyInCannon() const
	{
		if(CannonComp.IsInCannon())
			return true;

		if(CannonComp.IsLaunched())
			return true;

		return false;
	}
};