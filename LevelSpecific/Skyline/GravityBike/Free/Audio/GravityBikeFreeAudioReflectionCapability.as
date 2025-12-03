class UGravityBikeFreeAudioReflectionCapability : UHazePlayerCapability
{
	UGravityBikeFreeDriverComponent DriverComp;
	UAudioReflectionComponent ReflectionComponent;

	AGravityBikeFree GravityBike = nullptr;
	UGravityBikeFreeMovementComponent MoveComp = nullptr;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		ReflectionComponent = UAudioReflectionComponent::Get(Player);
		DriverComp = UGravityBikeFreeDriverComponent::Get(Player);
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
		GravityBike = DriverComp.GetGravityBike();
		MoveComp = UGravityBikeFreeMovementComponent::Get(GravityBike);

		ReflectionComponent.AddActorToIgnore(GravityBike);
		ReflectionComponent.SetMovementComponentOverride(MoveComp);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		ReflectionComponent.RemoveActorToIgnore(GravityBike);
		ReflectionComponent.ClearMovementComponentOverride();
	}
}
