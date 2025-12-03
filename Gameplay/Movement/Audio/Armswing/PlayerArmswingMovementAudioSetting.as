class UPlayerArmswingMovementAudioSettings : UHazeMovementAudioSettings
{
	UPROPERTY(EditDefaultsOnly, Meta = (ForceUnits = "db"))
	float MakeUpGain = 0.0;

	UPROPERTY(EditDefaultsOnly, Meta = (ForceUnits = "cent"))
	float Pitch = 0.0;

	// Armswing velocity type (Left, Right, Combined)

	// The raw range of movement we should normalize left arm movements over
	UPROPERTY(EditDefaultsOnly, Meta = (ForceUnits = "cm"))
	float LeftArmNormalizationRange = 1000.0;
	
	// The raw range of movement we should normalize right arm movements over
	UPROPERTY(EditDefaultsOnly, Meta = (ForceUnits = "cm"))
	float RightArmNormalizationRange = 1000.0;

	UPROPERTY(EditDefaultsOnly, Meta = (ForceUnits = "seconds"))
	float ArmswingVelocitySlewAttack = 0.1;

	UPROPERTY(EditDefaultsOnly, Meta = (ForceUnits = "seconds"))
	float ArmswingVelocitySlewRelease = 0.3;
}