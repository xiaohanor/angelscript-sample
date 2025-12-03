UCLASS(Abstract)
class UBigCrackBirdBaseCapability : UHazeCapability
{
	ABigCrackBird Bird;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Bird = Cast<ABigCrackBird>(Owner);
	}
};