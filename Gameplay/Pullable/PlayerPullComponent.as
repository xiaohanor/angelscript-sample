
class UPlayerPullComponent : UActorComponent
{
	/**
	 * The direction that the player wants to move in (by holding input)
	 * Will be 1 for wanting to go forward and -1 for wanting to go backward.
	 */
	UPROPERTY()
	float WantedPullDirection = 0.0;

	/**
	 * The actual movement direction that the pullable is currently moving on,
	 * this is decided by both players' inputs in a double pull, otherwise the same as WantedPullDirection.
	 */
	UPROPERTY()
	float ActiveTotalPullDirection = 0.0;

	/**
	 * Whether both players are currently pulling.
	 */
	UPROPERTY()
	bool bAreBothPlayersPulling = false;

	/**
	 * Whether both players are required to pull.
	 */
	UPROPERTY()
	bool bBothPlayersRequired = false;
};