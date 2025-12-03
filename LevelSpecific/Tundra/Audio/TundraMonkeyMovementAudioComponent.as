class UTundraMonkeyMovementAudioComponent : UHazeMovementAudioComponent
{
	UPROPERTY(EditDefaultsOnly)
	UAudioTundraMonkeyFootTraceSettings FootTraceSettings = nullptr; 

	UPROPERTY(EditDefaultsOnly)
	UAudioTundraMonkeyFootTraceSettings HandTraceSettings = nullptr; 

	access MovementScript = private, UTundraMonkeyFootstepTraceAudioCapability;

	access:MovementScript
	bool bIsActive = false;

	bool IsInMonkeyForm() const
	{
		return bIsActive;
	}
}