
/**
 * 
 */
class USimpleMovementSettings : UHazeComposableSettings
{
	/** If true, we will keep the horizontal velocity size hitting a ground impact
	 * This makes us keep the velocity going up hills.
	 * Else, we will loose the horizontal part and only keep the vertical part of the movement
	*/ 
	UPROPERTY()	
	bool bMaintainMovementSizeOnGroundedRedirects = false;

	/**
	 * If set, we will float this much above the surface (in the WorldUp direction)
	 * This can help with moving over uneven terrain.
	 * NOTE: Contrary to FloatingResolver, no validation is performed. Ceilings and slanted walls
	 * may intersect with the shape when floating, and cause penetration.
	 */
	UPROPERTY()
	FMovementSettingsValue FloatingHeight = FMovementSettingsValue::MakeDisabled();
}