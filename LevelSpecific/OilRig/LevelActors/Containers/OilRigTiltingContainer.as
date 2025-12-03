event void FTiltingContainerEvent();

UCLASS(Abstract)
class AOilRigTiltingContainer : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UFauxPhysicsAxisRotateComponent RotateComp;

	UPROPERTY(DefaultComponent, Attach = RotateComp)
	UCameraShakeForceFeedbackComponent CamShakeFFComp;

	UPROPERTY(DefaultComponent)
	UFauxPhysicsPlayerWeightComponent WeightComp;

	UPROPERTY(DefaultComponent)
	UMovementImpactCallbackComponent MovementImpactCallbackComp;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 10000.0;

	UPROPERTY()
	FTiltingContainerEvent OnBothPlayersLanded;

	bool bMioOnContainer = false;
	bool bZoeOnContainer = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MovementImpactCallbackComp.OnGroundImpactedByPlayer.AddUFunction(this, n"PlayerLanded");
		MovementImpactCallbackComp.OnGroundImpactedByPlayerEnded.AddUFunction(this, n"PlayerLeft");

		RotateComp.OnMinConstraintHit.AddUFunction(this, n"MinConstraintHit");
		RotateComp.OnMaxConstraintHit.AddUFunction(this, n"MaxConstraintHit");
	}

	UFUNCTION()
	private void MinConstraintHit(float Strength)
	{
		CamShakeFFComp.ActivateCameraShakeAndForceFeedback();
	}

	UFUNCTION()
	private void MaxConstraintHit(float Strength)
	{
		CamShakeFFComp.ActivateCameraShakeAndForceFeedback();
	}

	UFUNCTION()
	private void PlayerLanded(AHazePlayerCharacter Player)
	{
		if (Player.IsMio())
			bMioOnContainer = true;
		if (Player.IsZoe())
			bZoeOnContainer = true;

		if (bMioOnContainer && bZoeOnContainer)
			OnBothPlayersLanded.Broadcast();
	}

	UFUNCTION()
	private void PlayerLeft(AHazePlayerCharacter Player)
	{
		if (Player.IsMio())
			bMioOnContainer = false;
		if (Player.IsZoe())
			bZoeOnContainer = false;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		float FFMultiplier = Math::GetMappedRangeValueClamped(FVector2D(0.05, 0.3), FVector2D(0.0, 0.1), Math::Abs(RotateComp.Velocity));
		FHazeFrameForceFeedback FF;
		FF.LeftMotor = Math::Sin(Time::GetGameTimeSeconds() * 30.0) * FFMultiplier;
		FF.RightMotor = Math::Sin(-Time::GetGameTimeSeconds() * 30.0) * FFMultiplier;
		ForceFeedback::PlayWorldForceFeedbackForFrame(FF, RotateComp.WorldLocation, 2500.0, 500.0);
	}
}