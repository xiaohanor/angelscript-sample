class UDentistToothAnimationCapability : UHazePlayerCapability
{
	default TickGroup = EHazeTickGroup::LastMovement;
	default CapabilityTags.Add(n"ToothAnimation");

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
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
		if(Player.Mesh.CanRequestLocomotion())
			Player.Mesh.RequestLocomotion(Dentist::Feature, this);
	}
};