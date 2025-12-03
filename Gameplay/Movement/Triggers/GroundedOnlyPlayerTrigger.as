/**
 * Triggers for players, but only if they are currently grounded.
 * Players not grounded are not considered to be inside the volume even if they are physically overlapping it.
 * 
 * Note: Will send Enter/Leave events every time a player jumps inside the volume and then lands!
 */ 
UCLASS(HideCategories = "Collision Rendering Input Actor LOD Cooking Debug WorldPartition HLOD DataLayers", ComponentWrapperClass)
class AGroundedOnlyPlayerTrigger : AConditionalPlayerTrigger
{
	bool IsPlayerConditionMet(AHazePlayerCharacter Player) const override
	{
		UPlayerMovementComponent MoveComp = UPlayerMovementComponent::Get(Player);
		return MoveComp.IsOnWalkableGround();
	}
}