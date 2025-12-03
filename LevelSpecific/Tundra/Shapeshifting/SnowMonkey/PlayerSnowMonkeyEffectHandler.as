struct FTundraPlayerSnowMonkeyTransformParams
{
	UPROPERTY()
	float MorphTime;
}

struct FTundraPlayerSnowMonkeyPunchInteractEffectParams
{
	UPROPERTY()
	FVector PunchHandLocation;

	UPROPERTY()
	UPhysicalMaterial PhysMat;
}

struct FTundraPlayerSnowMonkeyBossPunchSlowMotionEffectParams
{
	UPROPERTY()
	float AccelerationDuration;
}

struct FTundraPlayerSnowMonkeyGroundSlamEffectParams
{
	UPROPERTY()
	bool bIsInSidescroller;
}

UCLASS(Abstract)
class UTundraPlayerSnowMonkeyEffectHandler : UHazeEffectEventHandler
{
	UPROPERTY(NotVisible, BlueprintReadOnly)
	ATundraPlayerSnowMonkeyActor SnowMonkeyActor;

	UPROPERTY(NotVisible, BlueprintReadOnly)
	AHazePlayerCharacter Player;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SnowMonkeyActor = Cast<ATundraPlayerSnowMonkeyActor>(Owner);
		Player = SnowMonkeyActor.Player;
	}

	UFUNCTION(BlueprintPure)
	USceneComponent GetMonkeyGroundComponent()
	{
		return Owner.RootComponent;
	}

    // Called when we transform into the gorilla (SnowGorilla.OnTransformedInto)
    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnTransformedInto(FTundraPlayerSnowMonkeyTransformParams Params) {}

 	// Called when we transform back into human form (SnowGorilla.OnTransformedOutOf)
    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnTransformedOutOf(FTundraPlayerSnowMonkeyTransformParams Params) {}

	// Called when an airborne or grounded groundslam starts (SnowGorilla.OnGroundSlamActivated)
    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnGroundSlamActivated() {}

	// Called when airborne groundslam move starts falling (SnowGorilla.OnGroundSlamStartedFalling)
    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnGroundSlamStartedFalling() {}

	// Called when the airborne groundslam has reached the ground (SnowGorilla.OnGroundSlamLanded)
    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnGroundSlamLanded(FTundraPlayerSnowMonkeyGroundSlamEffectParams Params) {}

	// Called when the airborne groundslam has reached the ground if the monkey is far away in view
    UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnGroundSlamLandedFarFromView(FTundraPlayerSnowMonkeyGroundSlamEffectParams Params) {}

	// Called when fists actually reaches the ground on grounded ground slam (SnowGorilla.OnGroundedGroundSlam)
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnGroundedGroundSlam(FTundraPlayerSnowMonkeyGroundSlamEffectParams Params) {}

	// Called when fists actually reaches the ground on grounded ground slam if the monkey is far away in view
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnGroundedGroundSlamFarFromView(FTundraPlayerSnowMonkeyGroundSlamEffectParams Params) {}

	// Called when a single punch interact is triggered (when input is pressed)
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPunchInteractSinglePunchTriggered() {}

	// Called when a multi punch interact is triggered (when input is pressed)
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPunchInteractMultiPunchTriggered() {}

	// Called when a single punch interact actually lands its punch.
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPunchInteractSinglePunch(FTundraPlayerSnowMonkeyPunchInteractEffectParams Params) {}

	// Called when a multi punch interact actually lands its punch.
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPunchInteractMultiPunch(FTundraPlayerSnowMonkeyPunchInteractEffectParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnFootstepTrace_Plant(FTundraMonkeyFootstepParams FootParams) {}
	
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnFootstepTrace_Release(FTundraMonkeyFootstepParams FootParams) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnFootstepTrace_Jump(FTundraMonkeyJumpLandParams JumpParams) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnFootstepTrace_Land(FTundraMonkeyJumpLandParams LandParams) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnFootstepTrace_Roll(FTundraMonkeyJumpLandParams RollParams) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnHangClimb_Grab() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnHangClimb_Start() {}
	
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnHangClimb_Stop() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPoleClimb_Grab() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnBossPunchSlowMotionEnter(FTundraPlayerSnowMonkeyBossPunchSlowMotionEffectParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnBossPunchSlowMotionExit(FTundraPlayerSnowMonkeyBossPunchSlowMotionEffectParams Params) {}
}
