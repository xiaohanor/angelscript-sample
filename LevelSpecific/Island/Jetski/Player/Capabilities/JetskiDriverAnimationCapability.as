class UJetskiDriverAnimationCapability : UHazePlayerCapability
{
	default TickGroup = EHazeTickGroup::LastMovement;

	UJetskiDriverComponent DriverComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DriverComp = UJetskiDriverComponent::Get(Player);
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
	void TickActive(float DeltaTime)
	{
		if(!Player.Mesh.CanRequestLocomotion())
            return;

        Player.Mesh.RequestLocomotion(n"Jetski", this);
	}
}