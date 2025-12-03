class UDentistToothCannonLockedInCannonCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default BlockExclusionTags.Add(Dentist::Cannon::DentistCannonBlockExclusionTag);

	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 50;

	UDentistToothPlayerComponent PlayerComp;
	UDentistToothCannonComponent CannonComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PlayerComp = UDentistToothPlayerComponent::Get(Player);
		CannonComp = UDentistToothCannonComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!CannonComp.IsInCannon())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!CannonComp.IsInCannon())
			return true;

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
		TickMeshRotation(DeltaTime);
	}

	void TickMeshRotation(float DeltaTime)
	{
		if(Dentist::Cannon::bApplyRotation)
			PlayerComp.SetMeshWorldRotation(Player.ActorQuat, this, 2, DeltaTime);
	}
};