class UDragonMovementAudioSettings : UHazeComposableSettings
{
	// Maxium cm/seconds that we track movement speed over
	UPROPERTY(EditDefaultsOnly, Meta = (ForceUnits = "cm"))
	float MovementVelocityRange = 1000.0;

	// Maxium cm/seconds that we track body movement relative to socket over
	UPROPERTY(EditDefaultsOnly, Meta = (ForceUnits = "cm"))
	float BodyMovementVelocityRange = 5000.0;
}