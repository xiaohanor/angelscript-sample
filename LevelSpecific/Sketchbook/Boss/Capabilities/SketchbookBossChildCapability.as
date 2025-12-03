UCLASS(Abstract)
class USketchbookBossChildCapability : UHazeChildCapability
{
	ASketchbookBoss Boss;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Boss = Cast<ASketchbookBoss>(Owner);
	}
}