namespace Pinball
{
	// Whether to allow the ball player to trigger the paddles with their controller
	bool UseTestInputShortcuts()
	{
#if EDITOR
		return true;
#else
		return false;
#endif

	}

	const bool bIgnoreCollisionWhenLaunched = true;

	const float PaddleMoveGraceTime = 0.1;	// Count the paddle as moving if the time since when it last moved is lower than this

	const float MaximumAllowedMoveSpeed = 4000;

	/**
	 * If enabled, we don't reload the level on game over, and instead handle cleanup ourselves.
	 */
	const bool bUseFastGameOver = false;
}