UCLASS(Abstract)
class UTundraWalkingStickBaseCapability : UHazeCapability
{
	ATundraWalkingStick WalkingStick;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		WalkingStick = Cast<ATundraWalkingStick>(Owner);
	}
}