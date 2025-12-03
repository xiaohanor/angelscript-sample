class UAdultDragonTurnBackSettings : UHazeComposableSettings
{
	// Speed of the rolling (measured in degrees per second)
	UPROPERTY()
	float RollingSpeed = 720;

	// Speed of the pitching (measured in degrees per second)
	UPROPERTY()
	float PitchSpeed = 720;

	// Delay before the turn back starts (Camera still stops instantly)
	UPROPERTY()
	float TurnBackDelay = 0.5;

	// Time to blend to the stopped camera (Start of the turn back)
	UPROPERTY()
	float StoppedCameraBlendDuration = 0.5;

	// Time to blend to the normal camera (End of the turn back)
	// BROKEN RIGHT NOW, LEAVE AT 0
	UPROPERTY()
	float NormalCameraBlendDuration = 0;
}