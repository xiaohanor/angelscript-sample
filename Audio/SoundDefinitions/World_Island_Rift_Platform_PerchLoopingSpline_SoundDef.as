
UCLASS(Abstract)
class UWorld_Island_Rift_Platform_PerchLoopingSpline_SoundDef : USpot_Tracking_SoundDef
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void OnStartMoving(){}

	/* END OF AUTO-GENERATED CODE */

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		Super::ParentSetup();
		
		if (SpotSpline != nullptr)
		{
			EffectEvent::LinkActorToReceiveEffectEventsFrom(
				HazeOwner, 
				Cast<AHazeActor>(SpotSpline.GetActorDependency().Get()));
		}
	}

}