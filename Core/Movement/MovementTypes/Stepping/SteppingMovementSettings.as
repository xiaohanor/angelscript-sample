enum ESteppingMovementBottomOfCapsuleMode
{
	/**
	 * Move down over edges.
	 */
	Rounded,

	/**
	 * Pretend that the bottom of our capsule is flat
	 * Extend the edge so that we keep walking along it instead of moving down over edges.
	 */
	Flat,

	/**
	 * Rounded if we find ground under the edge, otherwise flat.
	 */
	FlatExceptWhenGroundUnder,
};

enum ESteppingWalkOnUnstableEdgeHandling
{
	// We ignore unstable edge walking in the resolver, and instead let capabilities handle movement on them.
	Ignored,
	
	// Make the unstable edge ground invalid, making us airborne.
	Invalid,

	// Make the unstable edge ground unwalkable, making us slide off of it.
	Unwalkable,
};

enum ESteppingLandOnUnstableEdgeHandling
{
	// Don't handle landing on unstable edges, just count it as an edge.
	None,

	// Make the unstable edge ground unwalkable, making us slide off of it.
	Slide,

	// Move the shape out to outside the edge, but don't add any velocity. Will make us sneakily slide past the edge.
	Adjust,
};

/** 
 * Settings used by the USteppingMovementResolver
*/
class UMovementSteppingSettings : UHazeComposableSettings
{
	/** This is the cheapest version of the stepping resolver.
	 * This will perform sweeps, up the stairs. This requires a lot less trace validation
	 * If false, the movement will perform a real stepup over small steps, maintaining
	 * the horizontal movement but performing a lot more traces.
	 * 
	 * In more detail: This means that we don't move up on top of LowStepUp impacts, instead we sweep along their normals.
	 * This fails if the step up is too high, causing the impact to still be a wall.
	 */
	UPROPERTY()
	bool bSweepStep = true;

	/** The height that we can step up on obstacle on the ground */
	UPROPERTY()
	FMovementSettingsValue StepUpSize;
	default StepUpSize.Type = EMovementSettingsValueType::CollisionShapePercentage;
	default StepUpSize.Value = 1.0;

	/** The height that we will snap to the ground when hoovering over it */
	UPROPERTY()
	FMovementSettingsValue StepDownSize;
	default StepDownSize.Type = EMovementSettingsValueType::CollisionShapePercentage;
	default StepDownSize.Value = 1.0;

	/** If we are in air, we can specify to make the down trace
	 * smoother so we don't snap to the ground
	*/ 
	UPROPERTY()
	FMovementSettingsValue StepDownInAirSize;
	default StepDownInAirSize.Type = EMovementSettingsValueType::Value;
	default StepDownInAirSize.Value = 0.1;

	/** Can we stepup on impacts in front of us that don't have the tag "walkable" */
	UPROPERTY()
	bool bCanTriggerStepUpOnUnwalkableSurface = false;

	/**
	 * If enabled, moving into a wall will be redirected, else, all movement will be stopped and the velocity zeroed out
	 */
	UPROPERTY()
	bool bRedirectMovementOnWallImpacts = true;

	/** This will detect if we are moving on edges
	 * making it possible to create more accurate moves
	 * Comes with a heavy performance cost
	 */
	UPROPERTY()
	bool bPerformEdgeDetection = false;

	/**
	 * If true, the max unstable edge distance will always be set to 0, meaning that
	 * any distance from an edge will count as the edge being unstable.
	 */
	UPROPERTY()
	bool bForceAllEdgesAreUnstable = false;

	/**
	 * Determines how we redirect the impact normal that has detected an edge.
	 * This can make us "jump" out of the edge, more or less if we are walking on
	 * an angled slope
	 */
	UPROPERTY(meta = (EditCondition = "bPerformEdgeDetection"))
	EMovementEdgeNormalRedirectType EdgeRedirectType = EMovementEdgeNormalRedirectType::None;

	/**
	 * In stepping movement, we usually want to pretend that the bottom of the capsule is flat.
	 * This is because we don't want to be moving down over edges.
	 * However this does mean that we do a big snap once we have fully moved over the edge.
	 * With this setting, we can tweak how we want to handle.
	 */
	UPROPERTY()
	ESteppingMovementBottomOfCapsuleMode BottomOfCapsuleMode = ESteppingMovementBottomOfCapsuleMode::FlatExceptWhenGroundUnder;

	/**
	 * Previously we only extended edges when we were leaving ground.
	 * This could feel off when walking off an edge, then trying to walk up on the surface again, because you would then start falling.
	 */
	UPROPERTY()
	bool bOnlyFlatBottomOfCapsuleIfLeavingEdge = false;

	UPROPERTY()
	ESteppingWalkOnUnstableEdgeHandling WalkOnUnstableEdgeHandling = ESteppingWalkOnUnstableEdgeHandling::Ignored;

	/**
	 * If we previously were not on walkable ground,
	 * but now find walkable ground,
	 * and that ground is on an unstable edge,
	 * how should we handle that?
	 */
	UPROPERTY()
	ESteppingLandOnUnstableEdgeHandling LandOnUnstableEdgeHandling = ESteppingLandOnUnstableEdgeHandling::Slide;
}
