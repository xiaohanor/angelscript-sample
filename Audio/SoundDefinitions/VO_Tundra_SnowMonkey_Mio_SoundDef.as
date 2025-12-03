
UCLASS(Abstract)
class UVO_Tundra_SnowMonkey_Mio_SoundDef : UHazeVOSoundDef
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void OnPoleClimb_Grab(){}

	UFUNCTION(BlueprintEvent)
	void OnHangClimb_Grab(){}

	UFUNCTION(BlueprintEvent)
	void OnFootstepTrace_Roll(FTundraMonkeyJumpLandParams TundraMonkeyJumpLandParams){}

	UFUNCTION(BlueprintEvent)
	void OnFootstepTrace_Land(FTundraMonkeyJumpLandParams TundraMonkeyJumpLandParams){}

	UFUNCTION(BlueprintEvent)
	void OnFootstepTrace_Jump(FTundraMonkeyJumpLandParams TundraMonkeyJumpLandParams){}

	UFUNCTION(BlueprintEvent)
	void OnFootstepTrace_Release(FTundraMonkeyFootstepParams TundraMonkeyFootstepParams){}

	UFUNCTION(BlueprintEvent)
	void OnFootstepTrace_Plant(FTundraMonkeyFootstepParams TundraMonkeyFootstepParams){}

	UFUNCTION(BlueprintEvent)
	void OnPunchInteractMultiPunch(FTundraPlayerSnowMonkeyPunchInteractEffectParams TundraPlayerSnowMonkeyPunchInteractEffectParams){}

	UFUNCTION(BlueprintEvent)
	void OnPunchInteractSinglePunch(FTundraPlayerSnowMonkeyPunchInteractEffectParams TundraPlayerSnowMonkeyPunchInteractEffectParams){}

	UFUNCTION(BlueprintEvent)
	void OnPunchInteractMultiPunchTriggered(){}

	UFUNCTION(BlueprintEvent)
	void OnPunchInteractSinglePunchTriggered(){}

	UFUNCTION(BlueprintEvent)
	void OnGroundSlamStartedFalling(){}

	UFUNCTION(BlueprintEvent)
	void OnGroundSlamActivated(){}

	UFUNCTION(BlueprintEvent)
	void OnTransformedOutOf(FTundraPlayerSnowMonkeyTransformParams TundraPlayerSnowMonkeyTransformParams){}

	UFUNCTION(BlueprintEvent)
	void OnTransformedInto(FTundraPlayerSnowMonkeyTransformParams TundraPlayerSnowMonkeyTransformParams){}

	UFUNCTION(BlueprintEvent)
	void OnGroundSlamLandedFarFromView(FTundraPlayerSnowMonkeyGroundSlamEffectParams TundraPlayerSnowMonkeyGroundSlamEffectParams){}

	UFUNCTION(BlueprintEvent)
	void OnGroundedGroundSlamFarFromView(FTundraPlayerSnowMonkeyGroundSlamEffectParams TundraPlayerSnowMonkeyGroundSlamEffectParams){}

	UFUNCTION(BlueprintEvent)
	void OnHangClimb_Start(){}

	UFUNCTION(BlueprintEvent)
	void OnHangClimb_Stop(){}

	UFUNCTION(BlueprintEvent)
	void OnBossPunchSlowMotionEnter(FTundraPlayerSnowMonkeyBossPunchSlowMotionEffectParams TundraPlayerSnowMonkeyBossPunchSlowMotionEffectParams){}

	UFUNCTION(BlueprintEvent)
	void OnBossPunchSlowMotionExit(FTundraPlayerSnowMonkeyBossPunchSlowMotionEffectParams TundraPlayerSnowMonkeyBossPunchSlowMotionEffectParams){}

	UFUNCTION(BlueprintEvent)
	void OnGroundSlamLanded(FTundraPlayerSnowMonkeyGroundSlamEffectParams TundraPlayerSnowMonkeyGroundSlamEffectParams){}

	UFUNCTION(BlueprintEvent)
	void OnGroundedGroundSlam(FTundraPlayerSnowMonkeyGroundSlamEffectParams TundraPlayerSnowMonkeyGroundSlamEffectParams){}

	/* END OF AUTO-GENERATED CODE */

}