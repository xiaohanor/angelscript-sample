class UBattlefieldHoverboardWallRunTransferSettings : UHazeComposableSettings
{
	UPROPERTY()
	float VerticalImpulse = 400.0;

	UPROPERTY()
	float HorizontalImpulse = 1200.0;

	UPROPERTY()
	float HorizontalDrag = 0.4;

	UPROPERTY()
	float Gravity = 1950.0;

	UPROPERTY()
	float TransferDistance = 2500.0;

	/**
	 * Block air jump during this time at the start of the transfer
	 * Intended to prevent accidental double-taps, but may cause lost inputs.
	 */
	UPROPERTY()
	float BlockAirJumpWindowTime = 0.0;

	// The acceptance tolerance from directly opposite
	const float WallRunEnterAcceptanceAngle = 25.0;
	const float WallRunEnterVelocityAngle = 15.0;
	const float WallRunEnterSpeed = 2400.0;

	// How much time the player doesn't have any input
	const float NoInputTime = 0.4;
	// After NoInputTime, Input will lerp in over this duration to 100%
	const float InputLerpTime = 0.5;

	// How much time the player won't rotate at all from activation
	const float NoRotationTime = 0.5;
	// How long the rotation speed interps in after NoRotationTime
	const float RotationLerpTime = 0.8;

	const float Duration = 1.5;
}