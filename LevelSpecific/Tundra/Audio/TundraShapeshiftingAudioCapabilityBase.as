UCLASS(Abstract)
class UTundraShapeshiftingAudioCapabilityBase : UHazePlayerCapability
{
	ETundraShapeshiftActiveShape ShapeshiftShape = ETundraShapeshiftActiveShape::Player;
	UTundraPlayerShapeshiftingComponent ShapeShiftComp;

	protected bool bHasDelayedDeactivation = false;
	protected float DelayTimer = 0.6;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		ShapeShiftComp = UTundraPlayerShapeshiftingComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		bHasDelayedDeactivation = false;
		DelayTimer = 0.5;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(ShapeshiftShape == ETundraShapeshiftActiveShape::Player)
			return false;

		return ShapeShiftComp.GetActiveShapeType() == ShapeshiftShape;
	}

	protected bool IsInWantedShape() const
	{
		return ShapeShiftComp.GetActiveShapeType() == ShapeshiftShape;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return bHasDelayedDeactivation && !IsInWantedShape();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!IsInWantedShape())
		{
			DelayTimer -= DeltaTime;

			if(DelayTimer <= 0.0)
				bHasDelayedDeactivation = true;
		}
	}
}