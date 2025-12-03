
UCLASS(Abstract)
class UVO_SideContent_AroundCombat_SoundDef : UHazeVOSoundDef
{
	UPROPERTY(EditInstanceOnly)
	AAIEnemySpawnerTrackerVolume SpawnerTracker;

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (SpawnerTracker != nullptr && SpawnerTracker.AnyEnemiesActive())
			return false;

		return true;
	}
}