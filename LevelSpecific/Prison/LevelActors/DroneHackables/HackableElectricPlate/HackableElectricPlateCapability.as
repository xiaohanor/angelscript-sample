class UHackableElectricPlateCapability : UHazeCapability
{
	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 5;

	AHackableElectricPlate ElectricPlate;
	AHazePlayerCharacter Player;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		ElectricPlate = Cast<AHackableElectricPlate>(Owner);
		Player = Drone::GetSwarmDronePlayer();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!ElectricPlate.HijackTargetableComp.IsHijacked())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!ElectricPlate.HijackTargetableComp.IsHijacked())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Print("Zap");
	}
}