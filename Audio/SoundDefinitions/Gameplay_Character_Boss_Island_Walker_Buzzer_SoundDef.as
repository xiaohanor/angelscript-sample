
UCLASS(Abstract)
class UGameplay_Character_Boss_Island_Walker_Buzzer_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void OnSpawnedMinion(FIslandWalkerSpawnedMinionEventData Data){}

	/* END OF AUTO-GENERATED CODE */

	AAIIslandWalker Walker;

	UPROPERTY(BlueprintReadWrite)
	bool bSpawnFinished = false;

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		Walker = Cast<AAIIslandWalker>(HazeOwner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return Walker.SpawnPattern.IsActivePattern() == true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return Walker.SpawnPattern.IsActivePattern() == false;
	}
}