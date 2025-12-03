namespace DevTogglesGolfClub
{
	const FHazeDevToggleBool DebugDraw;
}

class ASanctuaryGolfClub : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent YawRotateComp;

	UPROPERTY(DefaultComponent, Attach = YawRotateComp)
	UFauxPhysicsAxisRotateComponent SwingRotateComp;

	UPROPERTY(DefaultComponent, Attach = SwingRotateComp)
	UDarkPortalTargetComponent DarkPortalTargetComponent;

	UPROPERTY(DefaultComponent, Attach = SwingRotateComp)
	UArrowComponent ForceArrowComp;

	UPROPERTY(DefaultComponent)
	UDarkPortalResponseComponent DarkPortalResponseComponent;

	UPROPERTY(DefaultComponent)
	UCameraShakeForceFeedbackComponent CameraShakeForceFeedbackComponent;

	UPROPERTY(DefaultComponent)
	UDarkPortalFauxPhysicsReactionComponent DarkPortalFauxPhysicsReactionComponent;

	UPROPERTY(EditInstanceOnly)
	ASanctuaryLightBirdSocket Socket;

	FHazeTimeLike LerpYawTimeLike;
	default LerpYawTimeLike.UseSmoothCurveZeroToOne();
	default LerpYawTimeLike.Duration = 0.5;

	float CurrentYaw;
	float TargetYaw;

	FVector SocketStartLocation;

	bool bSwingPositiveVelocity;

	float SocketDistance = 0.0;

	UFUNCTION(BlueprintEvent)
	void BP_OnHitConstraintMax(float Strength) {};

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		DarkPortalResponseComponent.OnGrabbed.AddUFunction(this, n"HandleGrabbed");
		DarkPortalResponseComponent.OnReleased.AddUFunction(this, n"HandleReleased");
		LerpYawTimeLike.BindUpdate(this, n"LerpYawTimeLikeUpdate");
		SwingRotateComp.OnMaxConstraintHit.AddUFunction(this, n"HandleMaxConstraintHit");

		SocketStartLocation = Socket.TranslateComp.WorldLocation;
		DevTogglesGolfClub::DebugDraw.MakeVisible();
	}

	UFUNCTION()
	private void HandleMaxConstraintHit(float Strength)
	{
		FVector ImpulseForce = ForceArrowComp.ForwardVector * Strength * 3500.0;

		Socket.TranslateComp.ApplyImpulse(DarkPortalTargetComponent.WorldLocation, ImpulseForce);
		CameraShakeForceFeedbackComponent.ActivateCameraShakeAndForceFeedback();
		if (DevTogglesGolfClub::DebugDraw.IsEnabled())
			PrintToScreen("Force = " + ImpulseForce, 3.0);

		BP_OnHitConstraintMax(Strength);
	}

	UFUNCTION()
	private void HandleGrabbed(ADarkPortalActor Portal, UDarkPortalTargetComponent TargetComponent)
	{
		CurrentYaw = YawRotateComp.WorldRotation.Yaw;
		FVector Direction = ((Portal.ActorLocation - ActorLocation) * FVector(1.0, 1.0, 0.0)).GetSafeNormal();
		TargetYaw = Direction.Rotation().Yaw;
		LerpYawTimeLike.PlayRate = 1.0;
		SwingRotateComp.Friction = 5.0;

		LerpYawTimeLike.PlayFromStart();
	}

	UFUNCTION()
	private void HandleReleased(ADarkPortalActor Portal, UDarkPortalTargetComponent TargetComponent)
	{
		SwingRotateComp.Friction = 0.8;

		UpdateSwingConstraintMax();
	}

	UFUNCTION()
	private void LerpYawTimeLikeUpdate(float CurrentValue)
	{
		YawRotateComp.SetWorldRotation(FRotator(0.0, Math::Lerp(CurrentYaw, TargetYaw, CurrentValue), 0.0));
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (SwingRotateComp.Velocity < 0.0 && bSwingPositiveVelocity)
		{
			bSwingPositiveVelocity = false;

			if (DevTogglesGolfClub::DebugDraw.IsEnabled())
				PrintToScreen("Positive velocity = " + bSwingPositiveVelocity, 2.0);

			if (TargetYaw != 0.0 && !DarkPortalResponseComponent.IsGrabbed())
			{
				CurrentYaw = YawRotateComp.WorldRotation.Yaw;
				TargetYaw = ActorRotation.Yaw;
				LerpYawTimeLike.PlayRate = 0.5;

				LerpYawTimeLike.PlayFromStart();
			}
		}

		if (SwingRotateComp.Velocity > 0.0 && !bSwingPositiveVelocity)
		{
			bSwingPositiveVelocity = true;

			UpdateSwingConstraintMax();

			if (DevTogglesGolfClub::DebugDraw.IsEnabled())
				PrintToScreen("Positive velocity = " + bSwingPositiveVelocity, 2.0);
		}
	}

	UFUNCTION()
	private void UpdateSwingConstraintMax()
	{
		SocketDistance = (SocketStartLocation - Socket.TranslateComp.WorldLocation).Size();
		if (DevTogglesGolfClub::DebugDraw.IsEnabled())
			PrintToScreen("Distance = " + SocketDistance, 3.0);

		if (SocketDistance < 500.0)
			SwingRotateComp.ConstrainAngleMax = 0.0;
		else
			SwingRotateComp.ConstrainAngleMax = 90.0;
	}
};