class UTundraPlayerShapeshiftingDeathResponseCapability : UHazePlayerCapability
{
	UPlayerHealthComponent HealthComp;
	UTundraPlayerShapeshiftingComponent ShapeshiftingComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		HealthComp = UPlayerHealthComponent::Get(Player);
		ShapeshiftingComp = UTundraPlayerShapeshiftingComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!HealthComp.bHasFinishedDying)
			return false;

		if(ShapeshiftingComp.CurrentShapeType == ETundraShapeshiftShape::Player)
			return false;

		if(ShapeshiftingComp.IsSpawnAsHumanBlocked())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!HealthComp.bHasFinishedDying)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		FShapeShiftTriggerData Data;
		Data.bUseEffect = false;
		Data.Type = ETundraShapeshiftShape::Player;
		ShapeshiftingComp.SetCurrentShape(Data);
	}
}