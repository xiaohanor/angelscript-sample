
UCLASS(Abstract)
class UWorld_Skyline_Highway_Interactable_CargoDoor_SpinLock_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void OnGravityWhipReleased(){}

	UFUNCTION(BlueprintEvent)
	void OnGravityWhipGrabbed(){}

	UFUNCTION(BlueprintEvent)
	void OnOpen(){}

	UFUNCTION(BlueprintEvent)
	void OnLockSprintBroken(FSkylineCargoDoorLockSprintBrokenParams Params){}

	/* END OF AUTO-GENERATED CODE */

	UFUNCTION(BlueprintEvent)
	void OnHitLeftConstraint(float Strength) {}

	UFUNCTION(BlueprintEvent)
	void OnHitRightConstraint(float Strength) {}

	ASkylineCargoDoorSpinLock SpinLock;
	AHazePlayerCharacter Player;

	UPROPERTY(NotVisible)
	UHazeAudioEmitter LeftSprintEmitter;

	UPROPERTY(NotVisible)
	UHazeAudioEmitter RightSprintEmitter;

	float LastRotationValue = 0;
	float LastRotationVelocity;

	UFUNCTION(BlueprintOverride)
	bool OverrideEmitterSceneAttachment(FName EmitterName, FName& ComponentName, AHazeActor& TargetActor,
										FName& BoneName, bool& bUseAttach)
	{
		if(EmitterName == n"DefaultEmitter")
		{
			bUseAttach = true;
			return true;
		}

		bUseAttach = false;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		SpinLock = Cast<ASkylineCargoDoorSpinLock>(HazeOwner);
		Player = Game::GetZoe();

		LeftSprintEmitter.AudioComponent.AttachToComponent(SpinLock.LockSprints[1].MovingPivot);
		RightSprintEmitter.AudioComponent.AttachToComponent(SpinLock.LockSprints[0].MovingPivot);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		SpinLock.RotateComp.OnMinConstraintHit.AddUFunction(this, n"OnHitLeftConstraint");
		SpinLock.RotateComp.OnMaxConstraintHit.AddUFunction(this, n"OnHitRightConstraint");
		LastRotationValue = 0;
		LastRotationVelocity = 0;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		SpinLock.RotateComp.OnMinConstraintHit.UnbindObject(this);
		SpinLock.RotateComp.OnMinConstraintHit.UnbindObject(this);
	}

	// UFUNCTION(BlueprintOverride)
	// bool ShouldActivate() const
	// {
	// 	if(!SpinLock.WhipResponseComp.IsGrabbed())
	// 		return false;

	// 	return true;
	// }

	// UFUNCTION(BlueprintOverride)
	// bool ShouldDeactivate() const
	// {
	// 	if(SpinLock.WhipResponseComp.IsGrabbed())
	// 		return false;

	// 	if(!SpinLock.RotateComp.bIsSleeping)
	// 		return false;

	// 	return true;
	// }

	float LastAlpha = 0;

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		auto NewPitch = DefaultEmitter.AudioComponent.WorldRotation.Roll;
		auto NewVelocity = (LastRotationValue - NewPitch) / DeltaSeconds;  

		LastRotationValue = NewPitch;
		LastRotationVelocity = Math::GetMappedRangeValueClamped(
			FVector2D(0, 300),
			FVector2D(0, 1),
			Math::Abs(NewVelocity)
		);
	}

	UFUNCTION(BlueprintPure, Meta = (CompactNodeTitle = "Player Rotation Input"))
	float GetPlayerRotationInput()
	{
		FVector2D RawInput = Player.CameraInput;
		FVector InputVector = Player.ViewRotation.RotateVector(FVector(0.0, RawInput.X, RawInput.Y));
		return InputVector.Size();
	}

	UFUNCTION(BlueprintPure, Meta = (CompactNodeTitle = "Rotation Alpha"))
	float GetRotationAlpha()
	{
		return SpinLock.Alpha;
	}

	UFUNCTION(BlueprintPure, Meta = (CompactNodeTitle = "Rotation Velocity"))
	float GetRotationVelocity()
	{
		return LastRotationVelocity;
	}

}