class AOilRigWallRunArm : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent ArmRoot;

	UPROPERTY(DefaultComponent, Attach = ArmRoot)
	USceneComponent ElbowRoot;

	UPROPERTY(DefaultComponent, Attach = ElbowRoot)
	USceneComponent ContainerRoot;

	UPROPERTY(DefaultComponent, Attach = ContainerRoot)
	UPlayerInheritMovementComponent InheritMovementComp;

	UPROPERTY(DefaultComponent, Attach = ContainerRoot)
	USceneComponent WallRunRoot;

	UPROPERTY(DefaultComponent, Attach = WallRunRoot)
	UGrappleWallrunPointComponent WallRunPointComp;

	UPROPERTY(DefaultComponent)
	UMovementImpactCallbackComponent MovementImpactCallbackComp;
	
	UPROPERTY(EditDefaultsOnly, Category = "Rotation")
	FRuntimeFloatCurve MoveCurve;
	UPROPERTY(EditDefaultsOnly, Category = "Rotation")
	float MoveDuration = 3.0;

	UPROPERTY(EditAnywhere, Category = "Rotation")
	float MaxOffset = -1600.0;

	UPROPERTY(EditInstanceOnly, Category = "Rotation", meta = (ClampMin = "0.0", ClampMax = "1.0", UIMin = "0.0", UIMax = "1.0"))
	float PreviewFraction = 0.0;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 15000;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike MoveTimeLike;

	UPROPERTY(EditAnywhere)
	bool bMoving = true;
	float StartMovingTime = 0.0;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		ArmRoot.SetRelativeLocation(FVector(0.0, Math::Lerp(0.0, MaxOffset, PreviewFraction), 0.0));
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (bMoving)
			StartMoving();

		MoveTimeLike.BindUpdate(this, n"UpdateMove");
		MoveTimeLike.BindFinished(this, n"FinishMove");
	}

	UFUNCTION(BlueprintPure)
	float GetAbsoluteArmPositionAlpha()
	{
		const float Pos =  MoveTimeLike.Position;
		return MoveTimeLike.IsReversed() ? 1 - Pos : Pos;
	}

	UFUNCTION()
	private void UpdateMove(float CurValue)
	{
		float Offset = Math::Lerp(0.0, MaxOffset, CurValue);
		ArmRoot.SetRelativeLocation(FVector(0.0, Offset, 0.0));
	}

	UFUNCTION()
	private void FinishMove()
	{

	}

	UFUNCTION()
	void RevealArm()
	{
		BP_RevealArm();
	}

	UFUNCTION(BlueprintEvent)
	void BP_RevealArm() {}

	UFUNCTION()
	void StartMoving()
	{
		bMoving = true;
		StartMovingTime = Time::PredictedGlobalCrumbTrailTime;
	}

	UFUNCTION()
	void MoveBackwards()
	{
		MoveTimeLike.ReverseFromEnd();
	}

	UFUNCTION()
	void MoveForwards()
	{
		MoveTimeLike.PlayFromStart();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (!bMoving)
			return;

		float CurTime = (Time::PredictedGlobalCrumbTrailTime - StartMovingTime) / MoveDuration;
		float WrappedTime = Math::Wrap(CurTime, 0.0, 2.0);
		if (WrappedTime > 1.0)
			WrappedTime = 2.0 - WrappedTime;

		float CurValue = MoveCurve.GetFloatValue(WrappedTime);

		float Offset = Math::Lerp(0.0, MaxOffset, CurValue);
		ArmRoot.SetRelativeLocation(FVector(0.0, Offset, 0.0));
	}

	UFUNCTION()
	void MoveBackwardsSyncedToPlayer(AHazePlayerCharacter Player)
	{
		if (Player.HasControl())
			CrumbMoveBackwards();
	}

	UFUNCTION()
	void MoveForwardsSyncedToPlayer(AHazePlayerCharacter Player)
	{
		if (Player.HasControl())
			CrumbMoveForwards();
	}

	UFUNCTION(CrumbFunction)
	private void CrumbMoveBackwards()
	{
		MoveBackwards();
	}

	UFUNCTION(CrumbFunction)
	private void CrumbMoveForwards()
	{
		MoveForwards();
	}
}