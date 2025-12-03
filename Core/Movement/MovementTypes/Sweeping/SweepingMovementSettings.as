/**
 *
 */
class UMovementSweepingSettings : UHazeComposableSettings
{
	/**
	 * If enabled, moving into the ground will be redirected, else, all movement will be stopped and the velocity zeroed out
	 */
	UPROPERTY()
	bool bRedirectMovementOnGroundImpacts = true;

	/**
	 * If enabled, moving into a wall will be redirected, else, all movement will be stopped and the velocity zeroed out
	 */
	UPROPERTY()
	bool bRedirectMovementOnWallImpacts = true;

	/**
	 * If enabled, moving into the ceiling will be redirected, else, all movement will be stopped and the velocity zeroed out
	 */
	UPROPERTY()
	bool bRedirectMovementOnCeilingImpacts = true;

	/** If the actor is grounded, we can use this to probe for the ground with a longer distance making the actor 'sticky' with the ground. */
	UPROPERTY()
	FMovementSettingsValue RemainOnGroundMinTraceDistance = FMovementSettingsValue::MakeDisabled();

	/** This will detect if we are moving on edges
	 * making it possible to create more accurate moves
	 * Comes with a heavy performance cost
	 */
	UPROPERTY()
	bool bPerformEdgeDetection = false;

	/**
	 * Determines how we redirect the impact normal that has detected an edge.
	 * This can make us "jump" out of the edge, more or less if we are walking on
	 * an angled slope
	 */
	UPROPERTY(meta = (EditCondition = "bPerformEdgeDetection"))
	EMovementEdgeNormalRedirectType EdgeRedirectType = EMovementEdgeNormalRedirectType::None;

	/**
	 * If we previously were not on walkable ground, but now find walkable ground, and that ground is on an unstable edge, should we set
	 * the ground to be unwalkable?
	 */
	UPROPERTY()
	bool bConsiderLandingOnUnstableEdgeAsUnwalkableGround = true;
}