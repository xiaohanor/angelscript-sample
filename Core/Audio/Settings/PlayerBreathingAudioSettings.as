UCLASS(EditInlineNew)
class UPlayerBreathingAudioSettings : UHazeComposableSettings
{
	UPROPERTY(EditDefaultsOnly)
	bool bForceOpenMouth = false;
	
	UPROPERTY(EditDefaultsOnly)
	float OpenMouthFactor = 0;
	// Add any wanted settings!

	UPROPERTY(EditDefaultsOnly)
	float LowExertionCycleThreshold = 25.0;

	UPROPERTY(EditDefaultsOnly)
	float MidExertionCycleThreshold = 50.0;

	UPROPERTY(EditDefaultsOnly)
	float HighExertionCycleThreshold = 75.0;

}