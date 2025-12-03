
/** Capability used as base for all the shape shifting capabilities
 * This allows us to enable and disable the shapes when the tags are blocked
 */
class UTundraShapeShiftingCapabilityBase : UHazeMarkerCapability
{
	default CapabilityTags.Add(TundraShapeshiftingTags::ShapeshiftingShape);
	default CapabilityTags.Add(TundraShapeshiftingTags::Shapeshifting);

	default BlockExclusionTags.Add(TundraShapeshiftingTags::ShapeshiftingShape);

	default TickGroup = EHazeTickGroup::Input;
	default TickGroupOrder = 2;
	default SeparateInactiveTick(EHazeTickGroup::Input, 2, 1);
	
	ETundraShapeshiftShape ShapeType;
	AHazePlayerCharacter Player;
	UTundraPlayerShapeshiftingComponent ShapeshiftingComponent;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		ShapeshiftingComponent = UTundraPlayerShapeshiftingComponent::Get(Player);
	}
	
	UFUNCTION(BlueprintOverride)
	void OnMarkerBlocked()
	{
		ShapeshiftingComponent.AddShapeTypeBlocker(ShapeType, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnMarkerUnblocked()
	{
		ShapeshiftingComponent.RemoveShapeTypeBlockerInstigator(this);
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
}