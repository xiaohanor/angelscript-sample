class AOilRigPerchPiston : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent PistonRoot;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent LeftArmRoot;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent RightArmRoot;

	UPROPERTY(DefaultComponent, Attach = LeftArmRoot)
	USceneComponent LeftSideHinge;

	UPROPERTY(DefaultComponent, Attach = RightArmRoot)
	USceneComponent RightSideHinge;

	UPROPERTY(DefaultComponent, Attach = PistonRoot)
	USceneComponent LeftMidHinge;

	UPROPERTY(DefaultComponent, Attach = PistonRoot)
	USceneComponent RightMidHinge;

	UPROPERTY(DefaultComponent, Attach = PistonRoot)
	UPerchPointComponent PerchPointComp;

	UPROPERTY(DefaultComponent, Attach = PerchPointComp)
	UPerchEnterByZoneComponent PerchLandingComp;

	UPROPERTY(DefaultComponent)
	UHazeActionQueueComponent ActionQueue;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 5000.0;

	UPROPERTY(EditAnywhere)
	float StartDelay = 0.0;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		FVector DirRightMidToRightSide = (RightSideHinge.WorldLocation - RightMidHinge.WorldLocation).GetSafeNormal();
		RightMidHinge.SetWorldRotation(DirRightMidToRightSide.Rotation());
		FVector DirRightSideToMid = -DirRightMidToRightSide;
		RightSideHinge.SetWorldRotation(DirRightSideToMid.Rotation());

		FVector DirLeftMidToLeftSide = (LeftSideHinge.WorldLocation - LeftMidHinge.WorldLocation).GetSafeNormal();
		LeftMidHinge.SetWorldRotation(DirLeftMidToLeftSide.Rotation());
		FVector DirLeftSideToMid = -DirLeftMidToLeftSide;
		LeftSideHinge.SetWorldRotation(DirLeftSideToMid.Rotation());
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ActionQueue.SetLooping(true);
		ActionQueue.Duration(1.0, this, n"UpdateMove");
		ActionQueue.Event(this, n"HitTop");
		ActionQueue.ReverseDuration(1.0, this, n"UpdateMove");
		ActionQueue.Event(this, n"HitBottom");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		ActionQueue.ScrubTo(Time::PredictedGlobalCrumbTrailTime - StartDelay);
	}

	UFUNCTION()
	private void HitTop()
	{
		UOilRigPerchPistonEventHandler::Trigger_HitTop(this);
		UOilRigPerchPistonEventHandler::Trigger_StartMovingDown(this);
	}

	UFUNCTION()
	private void HitBottom()
	{
		UOilRigPerchPistonEventHandler::Trigger_HitBottom(this);
		UOilRigPerchPistonEventHandler::Trigger_StartMovingUp(this);
	}

	UFUNCTION()
	private void UpdateMove(float CurValue)
	{
		float Offset = Math::Lerp(-212.0, 212.5, Curve::SmoothCurveZeroToOne.GetFloatValue(CurValue));
		PistonRoot.SetRelativeLocation(FVector(0.0, 0.0, Offset));

		FVector DirRightMidToRightSide = (RightSideHinge.WorldLocation - RightMidHinge.WorldLocation).GetSafeNormal();
		RightMidHinge.SetWorldRotation(DirRightMidToRightSide.Rotation());
		FVector DirRightSideToMid = -DirRightMidToRightSide;
		RightSideHinge.SetWorldRotation(DirRightSideToMid.Rotation());

		FVector DirLeftMidToLeftSide = (LeftSideHinge.WorldLocation - LeftMidHinge.WorldLocation).GetSafeNormal();
		LeftMidHinge.SetWorldRotation(DirLeftMidToLeftSide.Rotation());
		FVector DirLeftSideToMid = -DirLeftMidToLeftSide;
		LeftSideHinge.SetWorldRotation(DirLeftSideToMid.Rotation());
	}
}

class UOilRigPerchPistonEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent)
	void StartMovingUp() {}
	UFUNCTION(BlueprintEvent)
	void StartMovingDown() {}
	UFUNCTION(BlueprintEvent)
	void HitTop() {}
	UFUNCTION(BlueprintEvent)
	void HitBottom() {}
}