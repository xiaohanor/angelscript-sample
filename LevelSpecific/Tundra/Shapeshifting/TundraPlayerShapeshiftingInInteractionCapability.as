class UTundraPlayerShapeshiftingInInteractionCapability : UHazePlayerCapability
{
	default TickGroup = EHazeTickGroup::BeforeMovement;

	UTundraPlayerShapeshiftingComponent ShapeshiftingComp;
	UPlayerInteractionsComponent InteractionsComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		ShapeshiftingComp = UTundraPlayerShapeshiftingComponent::Get(Player);
		InteractionsComp = UPlayerInteractionsComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(InteractionsComp.ActiveInteraction == nullptr)
			return false;

		if(InteractionsComp.ActiveInteraction.IsA(UTundraShapeshiftingInteractionComponent))
			return false;

		if(InteractionsComp.ActiveInteraction.IsA(UTundraShapeshiftingOneShotInteractionComponent))
			return false;

		if(ShapeshiftingComp.CurrentShapeType == ETundraShapeshiftShape::Player)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.TundraSetPlayerShapeshiftingShape(ETundraShapeshiftShape::Player);
	}
}