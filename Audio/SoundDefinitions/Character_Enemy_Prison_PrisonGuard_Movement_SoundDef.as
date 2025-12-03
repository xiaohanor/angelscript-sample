
UCLASS(Abstract)
class UCharacter_Enemy_Prison_PrisonGuard_Movement_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void OnRespawn(){}

	UFUNCTION(BlueprintEvent)
	void OnDeath(FPrisonGuardDamageParams Params){}

	UFUNCTION(BlueprintEvent)
	void OnAttackStart(FPrisonGuardAttackParams Params){}

	UFUNCTION(BlueprintEvent)
	void OnAttackStop(FPrisonGuardAttackParams Params){}

	UFUNCTION(BlueprintEvent)
	void OnStunnedStart(FPrisonGuardDamageParams Params){}

	UFUNCTION(BlueprintEvent)
	void OnStunnedStop(){}

	/* END OF AUTO-GENERATED CODE */

	UPROPERTY(NotVisible)
	UHazeAudioEmitter LeftFootEmitter;

	UPROPERTY(NotVisible)
	UHazeAudioEmitter RightFootEmitter;

	UPROPERTY(NotVisible)
	UHazeAudioEmitter HipsEmitter;

	UPROPERTY(EditDefaultsOnly)
	float AttenuationScaling = 8000;

	FVector GetLeftArmLocation() const property
	{
		return PrisonGuard.Mesh.GetSocketLocation(n"LeftHand");
	}

	FVector GetRightArmLocation() const property
	{
		return PrisonGuard.Mesh.GetSocketLocation(n"RightHand");
	}

	FVector TrackedLeftArmLocation;
	FVector TrackedRightArmLocation;
	float TrackedLeftHandSpeed = 0.0;
	float TrackedRightHandSpeed = 0.0;

	const float MAX_TRACKED_ARM_SPEED = 600;

	UPROPERTY(BlueprintReadOnly, NotVisible)
	AAIPrisonGuard PrisonGuard;

	UFUNCTION(BlueprintOverride)
	bool OverrideEmitterSceneAttachment(FName EmitterName, FName& ComponentName, AHazeActor& TargetActor,
										FName& BoneName, bool& bUseAttach)
	{
		TargetActor = HazeOwner;
		bUseAttach = false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		PrisonGuard = Cast<AAIPrisonGuard>(HazeOwner);
		LeftFootEmitter.AttachEmitterTo(PrisonGuard.Mesh, n"LeftToeBase");
		RightFootEmitter.AttachEmitterTo(PrisonGuard.Mesh, n"RightToeBase");
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		const FVector LeftArmVelo = (LeftArmLocation - TrackedLeftArmLocation);
		TrackedLeftHandSpeed = (LeftArmVelo.Size() / DeltaSeconds) / MAX_TRACKED_ARM_SPEED;

		const FVector RightArmVelo = (RightArmLocation - TrackedRightArmLocation);
		TrackedRightHandSpeed = (RightArmVelo.Size() / DeltaSeconds) / MAX_TRACKED_ARM_SPEED;

		TrackedLeftArmLocation = LeftArmLocation;
		TrackedRightArmLocation = RightArmLocation;
	}

	UFUNCTION(BlueprintPure, Meta = (CompactNodeTitle = "Combined Arm Movement Normalized"))
	float GetCombinedArmMovementNormalized()
	{
		return Math::Saturate((TrackedLeftHandSpeed + TrackedRightHandSpeed) / 2);
	}
}