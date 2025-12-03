
UCLASS(Abstract)
class UWorld_Village_Shared_Platform_Wobbly_PerchPole_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void PlayerKnockedOff(){}

	UFUNCTION(BlueprintEvent)
	void StopWobbling(){}

	UFUNCTION(BlueprintEvent)
	void PlayerJumpedOff(){}

	UFUNCTION(BlueprintEvent)
	void PlayerLanded(){}

	/* END OF AUTO-GENERATED CODE */

	AVillageWobblyPerchPole PerchPole;

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		PerchPole = Cast<AVillageWobblyPerchPole>(HazeOwner);
	}

	UFUNCTION()
	void LandTriggered()
	{
		if (PerchPole.PlayersOnPole.Num() == 1)
			OnStartLandingLoops();
	}

	UFUNCTION()
	void RemovalTriggered()
	{
		if (PerchPole.PlayersOnPole.Num() == 0)
			OnStopLandingLoops();
	}

	UFUNCTION(BlueprintEvent)
	void OnStartLandingLoops() {}

	UFUNCTION(BlueprintEvent)
	void OnStopLandingLoops() {}
}