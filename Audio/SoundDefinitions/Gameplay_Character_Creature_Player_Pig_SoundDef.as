
UCLASS(Abstract)
class UGameplay_Character_Creature_Player_Pig_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	/* END OF AUTO-GENERATED CODE */

	UFUNCTION(BlueprintEvent)
	void OnFootstep_Front(FPigFootstepParams Params) {};

	UFUNCTION(BlueprintEvent)
	void OnFootstep_Back(FPigFootstepParams Params) {};

	UFUNCTION(BlueprintEvent)
	void OnFootstep_Release(FPigFootstepParams Params) {};

	UFUNCTION(BlueprintEvent)
	void OnFootstep_Jump(FPigJumpLandParams Params) {};

	UFUNCTION(BlueprintEvent)
	void OnFootstep_Land(FPigJumpLandParams Params) {};

	UPROPERTY(EditDefaultsOnly, Category = Movement)
	TMap<FName, UHazeAudioEvent> SurfaceAddEvents;

	UPROPERTY(EditDefaultsOnly, Category = Movement, Meta = (ForceUnits = "times"))
	float HeadMovementMultiplier = 1.0;

	private float CachedNormalizedMovementSpeed = 0.0;
	private float CachedNormalizedHeadMovement = 0.0;

	private FVector LastHeadLocation;
	private FVector LastPigLocation;

	private const float MOVEMENT_SPEED_DELTA_RANGE = 1050;
	private const float HEAD_MOVEMENT_DELTA_RANGE = 3000;

	// UFUNCTION(BlueprintOverride)
	// bool OverrideEmitterSceneAttachment(FName EmitterName, FName& ComponentName, AHazeActor& TargetActor,
	// 									FName& BoneName, bool& bUseAttach)
	// {
	// 	bUseAttach = false;
	// 	return false;
	// }

	UFUNCTION(BlueprintPure)
	float GetFallingSpeed()
	{
		return 0.0;
	}

	UFUNCTION(BlueprintPure, Meta = (CompactNodeTitle = "Movement Speed"))
	float GetNormalizedMovementSpeed()
	{
		return CachedNormalizedMovementSpeed;
	}

	UFUNCTION(BlueprintPure, Meta = (CompactNodeTitle = "Head Relative Movement Speed"))
	float GetNormalizedHeadMovement()
	{
		return CachedNormalizedHeadMovement * HeadMovementMultiplier;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		const FVector PigRootLocation = PlayerOwner.ActorCenterLocation;
		const float MovementSpeed = (PigRootLocation - LastPigLocation).Size() / DeltaSeconds;
		CachedNormalizedMovementSpeed = Math::Min(1, MovementSpeed / MOVEMENT_SPEED_DELTA_RANGE);

		const FVector HeadLocation = PlayerOwner.Mesh.GetSocketLocation(MovementAudio::Pigs::HeadSocketName);
		const float HeadMovementSpeed = (HeadLocation - LastHeadLocation).Size() / DeltaSeconds;
		CachedNormalizedHeadMovement = Math::Min(1, HeadMovementSpeed / HEAD_MOVEMENT_DELTA_RANGE);

		LastPigLocation = PigRootLocation;
		LastHeadLocation = HeadLocation;

	}
}