struct FIslandRedBlueForceFieldIgnoreCollisionMoveCompData
{
	FIslandRedBlueForceFieldIgnoreCollisionMoveCompData(UHazeMovementComponent In_MoveComp, float In_AdditionalCollisionShapeTolerance = 0.0, bool bIn_StayIgnoredWhenIgnoredOnce = false)
	{
		MoveComp = In_MoveComp;
		AdditionalCollisionShapeTolerance = In_AdditionalCollisionShapeTolerance;
		bStayIgnoredWhenIgnoredOnce = bIn_StayIgnoredWhenIgnoredOnce;
	}

	bool opEquals(FIslandRedBlueForceFieldIgnoreCollisionMoveCompData Other) const
	{
		return MoveComp == Other.MoveComp;
	}

	UHazeMovementComponent MoveComp;
	float AdditionalCollisionShapeTolerance = 0.0;
	bool bStayIgnoredWhenIgnoredOnce;
}

event void FIslandRedBlueForceFieldCollisionUnregisterMoveCompEvent(UHazeMovementComponent MoveComp);

UCLASS(NotBlueprintable, NotPlaceable)
class UIslandRedBlueForceFieldCollisionContainerComponent : UActorComponent
{
	FIslandRedBlueForceFieldCollisionUnregisterMoveCompEvent OnUnregisterMovementComponent;

	// These are all movement components that should ignore collision with the force field,
	// this is primarily the players but also any actors that has a UIslandRedBlueForceFieldCollisionComponent
	TArray<FIslandRedBlueForceFieldIgnoreCollisionMoveCompData> IgnoreCollisionMovementComponents;

	// These are all physics components that should be woken up when a force field procedural collision is modified.
	TArray<UPrimitiveComponent> PrimitivePhysicsComponents;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		IgnoreCollisionMovementComponents.Add(FIslandRedBlueForceFieldIgnoreCollisionMoveCompData(UHazeMovementComponent::Get(Game::Mio)));
		IgnoreCollisionMovementComponents.Add(FIslandRedBlueForceFieldIgnoreCollisionMoveCompData(UHazeMovementComponent::Get(Game::Zoe)));
	}
}