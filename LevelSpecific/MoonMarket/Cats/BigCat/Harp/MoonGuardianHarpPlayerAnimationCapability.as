class UMoonGuardianHarpPlayerAnimationCapability : UHazePlayerCapability
{
	default TickGroup = EHazeTickGroup::LastMovement;

	UMoonGuardianHarpPlayingComponent HarpComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		HarpComp = UMoonGuardianHarpPlayingComponent::Get(Player);
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

		Player.RequestLocomotion(n"Harp", this);
	}
};