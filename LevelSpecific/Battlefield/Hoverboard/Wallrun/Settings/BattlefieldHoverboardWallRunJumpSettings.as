class UBattlefieldHoverboardWallRunJumpSettings : UHazeComposableSettings
{
	UPROPERTY()
	float VerticalImpulse = 1015.0;

	UPROPERTY()
	float HorizontalImpulse = 725.0;

	const float HorizontalVelocityInterpSpeed = 2400.0;

	UPROPERTY()
	float GravityStart = 3000.0;

	UPROPERTY()
	float GravityEnd = 1950.0;

	UPROPERTY()
	float GravityLerpTime = 0.45;

	// Maximum duration of the move
	const float Duration = 1.0;

	/* Input
		How long the player doesn't have input for, and how the input lerps in after this time
	*/
	const float NoInputTime = 0.0;
	const float InputLerpTime = 0.25;

	/* Forward input correction
		If input is within this range relative to forward on the wall, input will be corrected
		Minus is into the wall
	*/
	const float InputCorrectionAngleMinimum = -17.5;
	const float InputCorrectionAngleMaximum = 5.0;

	/* FacingRotation
		How long the player doesn't rotate for, and how the rotation scale lerps in after this time
	*/
	// How much time the player won't rotate at all from activation
	const float NoFacingRotationTime = 0.25;
	// How long the rotation speed interps in after NoRotationTime
	const float FacingRotationLerpTime = 0.65;

	const float FacingRotationInterpSpeed = 340.0;
}