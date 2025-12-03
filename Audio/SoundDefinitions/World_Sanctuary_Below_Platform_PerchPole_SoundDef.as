
UCLASS(Abstract)
class UWorld_Sanctuary_Below_Platform_PerchPole_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void StartPolePerch(){}

	/* END OF AUTO-GENERATED CODE */

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		auto PoleActor = Cast<APoleClimbActor>(HazeOwner);
		if(PoleActor != nullptr)
		{
			PoleActor.OnStartPoleClimb.AddUFunction(this, n"HandleClimbStarted");
			PoleActor.PerchPointComp.OnPlayerStartedPerchingEvent.AddUFunction(this, n"HandlePerchStarted");
		}	
	}

	UFUNCTION()
	private void HandleClimbStarted(AHazePlayerCharacter Player, APoleClimbActor PoleClimbActor)
	{
		StartPolePerch();
	}

	UFUNCTION()
	private void HandlePerchStarted(AHazePlayerCharacter Player, UPerchPointComponent PerchPoint)
	{
		StartPolePerch();
	}
}