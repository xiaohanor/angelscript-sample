
UCLASS(Abstract)
class UCharacter_Boss_Summit_RubyKnight_Movement_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void OnCrystalBottomDeploy(FSummitKnightCrystalBottomParams Params){}

	UFUNCTION(BlueprintEvent)
	void OnCrystalBottomRetract(FSummitKnightCrystalBottomParams Params){}

	UFUNCTION(BlueprintEvent)
	void OnCrystalBottomShatter(FSummitKnightCrystalBottomParams Params){}

	UFUNCTION(BlueprintEvent)
	void OnSwoopTelegraph(FSummitKnightPlayerParams Params){}

	UFUNCTION(BlueprintEvent)
	void OnSwoopChargeEnd(){}

	UFUNCTION(BlueprintEvent)
	void OnSwoopAggroTelegraph(FSummitKnightPlayerParams Params){}

	UFUNCTION(BlueprintEvent)
	void OnSwoopAggroEnd(){}

	UFUNCTION(BlueprintEvent)
	void OnStartCirlingAngry(){}

	UFUNCTION(BlueprintEvent)
	void OnAlmostDeadReaction(){}

	UFUNCTION(BlueprintEvent)
	void OnHitByRoll(){}

	/* END OF AUTO-GENERATED CODE */

	private FVector CachedLeftHandLocation;
	private FVector CachedRightHandLocation;

	private float CachedLeftHandSpeed;
	private float CachedRightHandSpeed;
	private float CachedCombinedHandSpeed;
	private float CachedCombinedHandSpeedDelta;

	AAISummitKnight SummitKnight;

	const float MAX_HAND_MOVEMENT_SPEED = 6000;
	const float MAX_HAND_MOVEMENT_SPEED_DELTA = 3;

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		SummitKnight = Cast<AAISummitKnight>(HazeOwner);
	}

	UFUNCTION(BlueprintOverride)
	bool OverrideEmitterSceneAttachment(FName EmitterName, FName& ComponentName, AHazeActor& TargetActor,
										FName& BoneName, bool& bUseAttach)
	{
		TargetActor = HazeOwner;
		bUseAttach = true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		const FVector LeftHandLocation = SummitKnight.Mesh.GetSocketLocation(n"LeftHand");
		const FVector RightHandLocation = SummitKnight.Mesh.GetSocketLocation(n"RightHand");

		CachedLeftHandSpeed = (LeftHandLocation - CachedLeftHandLocation).Size() / DeltaSeconds;
		CachedRightHandSpeed = (RightHandLocation - CachedRightHandLocation).Size() / DeltaSeconds;

		CachedLeftHandLocation = LeftHandLocation;
		CachedRightHandLocation = RightHandLocation;

		const float CombinedHandSpeed = Math::Saturate(((CachedLeftHandSpeed + CachedRightHandSpeed) / 2) / MAX_HAND_MOVEMENT_SPEED);
		CachedCombinedHandSpeedDelta = Math::Saturate((Math::Abs(CombinedHandSpeed - CachedCombinedHandSpeed) / DeltaSeconds) / MAX_HAND_MOVEMENT_SPEED_DELTA);
		CachedCombinedHandSpeed = CombinedHandSpeed;
	}

	UFUNCTION(BlueprintPure, Meta = (CompactNodeTitle = "Arm Movement Speed Combined"))
	float GetArmMovementSpeedCombined()
	{
		return CachedCombinedHandSpeed;
	}

	UFUNCTION(BlueprintPure, Meta = (CompactNodeTitle = "Arm Movement Speed Delta Combined"))
	float GetArmMovementSpeedDeltaCombined()
	{
		return CachedCombinedHandSpeedDelta;
	}
}