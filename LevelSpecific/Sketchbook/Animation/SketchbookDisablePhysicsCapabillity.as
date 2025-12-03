class USketchbookDisablePhysicsCapabillity : UHazePlayerCapability
{
	default TickGroup = EHazeTickGroup::Movement;

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
		auto PhysAnimComp = UHazePhysicalAnimationComponent::GetOrCreate(Owner);
		PhysAnimComp.Disable(this, 0);

		Player.Mesh.SetDisablePostProcessBlueprint(true);
		Player.Mesh.AllowClothActors = false;
		Player.Mesh.bDisableClothSimulation = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		auto PhysAnimComp = UHazePhysicalAnimationComponent::GetOrCreate(Owner);
		PhysAnimComp.ClearDisable(this, 0);

		Player.Mesh.SetDisablePostProcessBlueprint(false);
		Player.Mesh.AllowClothActors = true;
		Player.Mesh.bDisableClothSimulation = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
	}
};