class USoftSplitValveDoorCapability : UInteractionCapability
{
	default TickGroup = EHazeTickGroup::BeforeMovement;

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (Player.Mesh.CanRequestLocomotion())
			Player.Mesh.RequestLocomotion(n"ValvePush", this);
	}
};