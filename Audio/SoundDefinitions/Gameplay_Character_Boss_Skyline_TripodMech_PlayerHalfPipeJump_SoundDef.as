
UCLASS(Abstract)
class UGameplay_Character_Boss_Skyline_TripodMech_PlayerHalfPipeJump_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	/* END OF AUTO-GENERATED CODE */

	ASkylineBoss TripodMech;

	UFUNCTION(BlueprintEvent)
	void OnHalfpipeJumpStarted(AGravityBikeFree GravityBike) {};

	UFUNCTION(BlueprintEvent)
	void OnHalfpipeJumpEnded(AGravityBikeFree GravityBike, bool bLanded) {};	

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		TripodMech = Cast<ASkylineBoss>(HazeOwner);

		TripodMech.LeftHalfPipeTrigger.OnHalfPipeJumpStarted.AddUFunction(this, n"OnHalfpipeJumpStarted");
		TripodMech.RightHalfPipeTrigger.OnHalfPipeJumpStarted.AddUFunction(this, n"OnHalfpipeJumpStarted");
		TripodMech.LeftHalfPipeTrigger.OnHalfPipeJumpEnded.AddUFunction(this, n"OnHalfpipeJumpEnded");
		TripodMech.RightHalfPipeTrigger.OnHalfPipeJumpEnded.AddUFunction(this, n"OnHalfpipeJumpEnded");		
	}
}