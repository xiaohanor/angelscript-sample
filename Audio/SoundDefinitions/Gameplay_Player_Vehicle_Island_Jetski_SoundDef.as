
UCLASS(Abstract)
class UGameplay_Player_Vehicle_Island_Jetski_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void OnExplode(){}

	UFUNCTION(BlueprintEvent)
	void OnStopAirMovement(){}

	UFUNCTION(BlueprintEvent)
	void OnStartAirMovement(){}

	UFUNCTION(BlueprintEvent)
	void OnStartAirDive(){}

	UFUNCTION(BlueprintEvent)
	void OnStopDiving(){}

	UFUNCTION(BlueprintEvent)
	void OnStartGroundMovement(){}

	UFUNCTION(BlueprintEvent)
	void OnStopGroundMovement(){}

	UFUNCTION(BlueprintEvent)
	void OnStopUnderwaterMovement(FJetskiOnExitUnderwaterEventData EventData){}

	UFUNCTION(BlueprintEvent)
	void OnStartUnderwaterMovement(FJetskiOnEnterUnderwaterEventData EventData){}

	/* END OF AUTO-GENERATED CODE */

	UPROPERTY(BlueprintReadOnly, NotVisible)
	AJetski Jetski;

	const float MAX_WATER_FORWARD_SPEED = 2800;
	const float MAX_WATER_THROTTLE_DELTA = 30;
	const float MAX_WATER_ANGULAR_SPEED = 100;
	const float MAX_WATER_VERTICAL_SPEED = 1500;
	const float MAX_GROUNDED_PREVIOUS_VERTICAL_SPEED = 2500;

	private float ThrottleDelta = 0.0;
	private float PreviousThrottle = 0.0;

	UPROPERTY(BlueprintReadOnly, NotVisible)
	bool bWasOnWaterSurface = false;

	UFUNCTION(BlueprintPure, Meta = (CompactNodeTitle = "Is On Water Surface"))
	bool IsOnWaterSurface()
	{
		return Jetski.IsOnWaterSurface();
	}

	UFUNCTION(BlueprintPure, Meta = (CompactNodeTitle = "Jetski Is Grounded"))
	bool IsJetskiGrounded()
	{
		return Jetski.GetMovementState() == EJetskiMovementState::Ground;
	}

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		Jetski = Cast<AJetski>(HazeOwner);	
	}

	UFUNCTION(BlueprintOverride)
	bool OverrideEmitterSceneAttachment(FName EmitterName, FName& ComponentName, AHazeActor& TargetActor,
										FName& BoneName, bool& bUseAttach)
	{
		ComponentName = n"MeshComp";
		TargetActor = HazeOwner;
		bUseAttach = true;
		return true;
	}

	UFUNCTION(BlueprintPure, Meta = (CompactNodeTitle = "Throttle"))
	float GetThrottle()
	{
		return Jetski.GetThrottleInput();	
	}

	UFUNCTION(BlueprintPure, Meta = (CompactNodeTitle = "Throttle Speed"))
	float GetThrottleSpeed()
	{
		return Math::Saturate(Jetski.GetForwardSpeed(EJetskiUp::Global) / MAX_WATER_FORWARD_SPEED);
	}

	UFUNCTION(BlueprintPure, Meta = (CompactNodeTitle = "Throttle Delta"))
	float GetThrottleDelta()
	{
		return Math::GetMappedRangeValueClamped(FVector2D(-MAX_WATER_THROTTLE_DELTA, MAX_WATER_THROTTLE_DELTA), FVector2D(-1.0, 1.0), ThrottleDelta);
	}
	
	UFUNCTION(BlueprintPure, Meta = (CompactNodeTitle = "Angular Speed"))
	float GetAngularSpeed()
	{
		return Math::Saturate(Math::Abs(Jetski.AngularSpeed) / MAX_WATER_ANGULAR_SPEED);
	}

	UFUNCTION(BlueprintPure,  Meta = (CompactNodeTitle = "Vertical Speed"))
	float GetVerticalSpeed()
	{
		return Math::Saturate(Math::Abs(Jetski.GetVerticalSpeed(EJetskiUp::Global)) / MAX_WATER_VERTICAL_SPEED);
	}

	UFUNCTION(BlueprintPure,  Meta = (CompactNodeTitle = "Previous Vertical Speed"))
	float GetPreviousVerticalSpeed()
	{
		return Math::Saturate(Math::Abs(Jetski.MoveComp.PreviousVerticalVelocity.Size()) / MAX_GROUNDED_PREVIOUS_VERTICAL_SPEED);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		bWasOnWaterSurface = Jetski.IsOnWaterSurface();

		auto Throttle = GetThrottle();
		ThrottleDelta = Throttle - PreviousThrottle;
		PreviousThrottle = Throttle;
	}
}