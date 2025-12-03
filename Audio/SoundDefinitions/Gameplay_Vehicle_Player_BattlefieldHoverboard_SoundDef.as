
UCLASS(Abstract)
class UGameplay_Vehicle_Player_BattlefieldHoverboard_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void OnNewTrick(FBattlefieldHoverboardTrickParams Params){}

	UFUNCTION(BlueprintEvent)
	void OnSuccessfulLand(){}

	UFUNCTION(BlueprintEvent)
	void OnTrickFailed(){}

	UFUNCTION(BlueprintEvent)
	void OnStartedGrinding(FBattlefieldHoverboardGrindEffectParams Params){}

	UFUNCTION(BlueprintEvent)
	void OnStoppedGrinding(){}

	UFUNCTION(BlueprintEvent)
	void OnTrickBoostStarted(){}

	UFUNCTION(BlueprintEvent)
	void OnTrickBoostEnded(){}

	UFUNCTION(BlueprintEvent)
	void OnTrickBoostStored(){}

	UFUNCTION(BlueprintEvent)
	void OnGrounded(FBattlefieldHoverboardOnGroundedParams Params){}

	UFUNCTION(BlueprintEvent)
	void OnGroundMaterialChanged(FBattlefieldHoverboardOnGroundMaterialChangedParams Params){}

	UFUNCTION(BlueprintEvent)
	void OnLeftGround(){}

	UFUNCTION(BlueprintEvent)
	void OnStartedWallRun(FBattlefieldHoverboardGrindEffectParams Params){}

	UFUNCTION(BlueprintEvent)
	void OnStoppedWallRun(){}

	/* END OF AUTO-GENERATED CODE */

	UPROPERTY(BlueprintReadOnly)
	ABattlefieldHoverboard Hoverboard;

	UHazeMovementComponent MoveComp;
	UBattlefieldHoverboardGrindingComponent GrindComp;

	UPROPERTY(BlueprintReadOnly)
	float RampTimePosition = 0.0;

	UPROPERTY(BlueprintReadOnly)
	const float MaxRampTimeSeconds = 30;

	private float PreviousStickInput = 0.0;

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(PlayerOwner.IsPlayerDead())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(PlayerOwner.IsPlayerDead())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		RampTimePosition = 0.0;
	}

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		Hoverboard = Cast<ABattlefieldHoverboard>(HazeOwner);
		SetPlayerOwner(Hoverboard.Player);
		MoveComp = UHazeMovementComponent::Get(Hoverboard.Player);
		GrindComp = UBattlefieldHoverboardGrindingComponent::Get(Hoverboard.Player);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		if(Hoverboard.HoverboardComp.bIsGrounded)
			RampTimePosition += DeltaSeconds;
		else
			RampTimePosition -= DeltaSeconds;

		RampTimePosition = Math::Clamp(RampTimePosition, 0.0, MaxRampTimeSeconds);
	}

	UFUNCTION(BlueprintPure)
	void GetHorizontalStickInput(float&out Current, float&out Delta)
	{	
		Current = MoveComp.GetSyncedMovementInputForAnimationOnly().Y;
		Delta = Math::Abs(Current - PreviousStickInput);
		PreviousStickInput = Current;	
	}

	UFUNCTION(BlueprintPure)
	float GetAlphaOnGrindSpline(UBattlefieldHoverboardGrindSplineComponent GrindSpline)
	{
		if(GrindSpline == nullptr)
			return 0.0;

		return GrindSpline.SplineComp.GetClosestSplineDistanceToWorldLocation(Hoverboard.ActorLocation) / GrindSpline.SplineComp.SplineLength;
	}

	UFUNCTION(BlueprintPure)
	bool IsOnSolidGround() 
	{
		if(GrindComp.IsGrinding())
			return false;

		return MoveComp.IsOnAnyGround();
	}
}