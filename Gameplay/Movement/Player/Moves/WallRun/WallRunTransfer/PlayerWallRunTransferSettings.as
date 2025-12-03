class UPlayerWallRunTransferSettings : UHazeComposableSettings
{
	UPROPERTY()
	float MaxTransferDistance = 500.0;

	UPROPERTY()
	float TransferSpeed = 750.0;

	UPROPERTY()
	float TransferAccelerationDuration = 0.05;

	UPROPERTY()
	float TransferDecelerationDuration = 0.25;

	/**
	 * If nonzero, we have additional forward speed while transfering,
	 * so this becomes more of a 'dash' as well.
	 */
	UPROPERTY()
	float ExtraForwardSpeedDuringTransfer = 200.0;

	/**
	 * Block air jump during this time at the start of the transfer
	 * Intended to prevent accidental double-taps, but may cause lost inputs.
	 */
	UPROPERTY()
	float BlockAirJumpWindowTime = 0.0;

	// The acceptance tolerance from directly opposite
	const float WallRunEnterAcceptanceAngle = 25.0;
	const float WallRunEnterVelocityAngle = 15.0;
	const float WallRunEnterSpeed = 700.0;

	// How much time the player doesn't have any input
	const float NoInputTime = 0.4;
	// After NoInputTime, Input will lerp in over this duration to 100%
	const float InputLerpTime = 0.5;

	// How much time the player won't rotate at all from activation
	const float NoRotationTime = 0.5;
	// How long the rotation speed interps in after NoRotationTime
	const float RotationLerpTime = 0.8;
	
	/**
	 * The calculation for the vertical jump is slightly off-target (can only approximate a future trace),
	 * which usually results in us reaching the destination wall slightly higher up than we started.
	 * This looks weird, so instead we target a bit _below_ where we would otherwise end up.
	 */
	UPROPERTY()
	float TransferLostHeight = 50.0;
}