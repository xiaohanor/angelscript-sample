struct FGravityBladeGrapplePullDeactivationParams
{
	FVector NewWorldUp;
};

class UGravityBladeGrapplePullCapability : UHazeChildCapability
{
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::LocalOrCrumbNetwork;

	default CapabilityTags.Add(GravityBladeTags::GravityBlade);

	default CapabilityTags.Add(GravityBladeGrappleTags::GravityBladeGrapple);
	default CapabilityTags.Add(GravityBladeGrappleTags::GravityBladeGrapplePull);

	default DebugCategory = GravityBlade::DebugCategory;

	AHazePlayerCharacter Player;

	UGravityBladeUserComponent BladeComp;
	UGravityBladeGrappleUserComponent GrappleComp;
	UPlayerMovementPerspectiveModeComponent PerspectiveModeComp;

	UPlayerMovementComponent MoveComp;
	UTeleportingMovementData Movement;

	float PullDuration;
	FVector RotationAxis;
	float RotationAngularDistance;
	FTransform StartTransform;
	FVector StartGravityDirection;
	FTransform TargetTransform;
	FVector TargetGravityDirection;
	FHazeRuntimeSpline MovementSpline;

	float TickDuration;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);

		BladeComp = UGravityBladeUserComponent::Get(Owner);
		GrappleComp = UGravityBladeGrappleUserComponent::Get(Owner);
		PerspectiveModeComp = UPlayerMovementPerspectiveModeComponent::Get(Player);

		MoveComp = UPlayerMovementComponent::Get(Owner);
		Movement = MoveComp.SetupTeleportingMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FGravityBladeGrapplePullDeactivationParams& DeactivationParams) const
	{
		if (TickDuration > PullDuration)
		{
			if (GrappleComp.ActiveGrappleData.CanShiftGravity())
				DeactivationParams.NewWorldUp = GrappleComp.ActiveGrappleData.WorldUp;
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		StartTransform = Player.ActorTransform;
		StartGravityDirection = Player.GetGravityDirection();
		TargetTransform = GrappleComp.ActiveGrappleData.WorldTransform;
		TargetGravityDirection = -GrappleComp.ActiveGrappleData.WorldUp;

		FVector CrossVector = StartGravityDirection;
		if (Math::Abs(TargetGravityDirection.DotProduct(CrossVector)) > 0.99)
		{
			const FVector TargetDirection = (TargetTransform.Location - StartTransform.Location).GetSafeNormal();
			CrossVector = StartGravityDirection.CrossProduct(TargetDirection);
		}
		RotationAxis = TargetGravityDirection.CrossProduct(CrossVector).GetSafeNormal();

		RotationAngularDistance = Math::RadiansToDegrees(StartGravityDirection.AngularDistanceForNormals(TargetGravityDirection));
		if (RotationAxis.DotProduct(StartGravityDirection.CrossProduct(TargetGravityDirection)) < 0.0)
			RotationAngularDistance *= -1.0;

		const float NewLength = RecalculateSpline();
		PullDuration = (NewLength / GravityBladeGrapple::PullSpeed);

		UGravityBladePlayerEventHandler::Trigger_StartPull(Player);

		if (GrappleComp.ActiveGrappleData.ResponseComponent != nullptr)
			GrappleComp.ActiveGrappleData.ResponseComponent.PullStart(GrappleComp);

		GrappleComp.GrapplePullDuration = PullDuration;
		GrappleComp.AnimationData.LastGrapplePullFrame = Time::FrameNumber;

		FGravityBladeGravityTransitionData Params;
		Params.bTransitionToOriginalGravity = (GrappleComp.ActiveAlignSurface.SurfaceNormal == FVector::UpVector);
		Params.PullDuration = PullDuration;
		Params.bWillAffectCamera = PerspectiveModeComp.IsCameraBehaviorEnabled();
		UGravityBladeGrappleEventHandler::Trigger_StartGravityShiftTransition(BladeComp.Blade, Params);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FGravityBladeGrapplePullDeactivationParams DeactivationParams)
	{
		if (!DeactivationParams.NewWorldUp.IsNearlyZero())
		{
			// GrappleComp.AlignComponent = GrappleComp.ActiveGrappleData.ShiftComponent;
			Player.OverrideGravityDirection(-DeactivationParams.NewWorldUp, Skyline::GravityProxy);
		}

		if (GrappleComp.ActiveGrappleData.ResponseComponent != nullptr)
			GrappleComp.ActiveGrappleData.ResponseComponent.PullEnd(GrappleComp);

		UGravityBladePlayerEventHandler::Trigger_EndPull(Player);
		if (IsValid(BladeComp.Blade))
			UGravityBladeGrappleEventHandler::Trigger_EndGravityShiftTransition(BladeComp.Blade);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float Alpha = Math::Saturate(ActiveDuration / PullDuration);
		Alpha = Math::EaseIn(0.0, 1.0, Alpha, 1.6);

		const FVector GravityDirection = StartGravityDirection.RotateAngleAxis(RotationAngularDistance * Alpha, RotationAxis).GetSafeNormal();

		if (MoveComp.PrepareMove(Movement))
		{
			const FVector TargetLocationDelta = (MovementSpline.Points.Last() - GrappleComp.ActiveGrappleData.WorldLocation);
			if (!TargetLocationDelta.IsNearlyZero(SMALL_NUMBER))
				RecalculateSpline();

			FVector UpVector = Player.MovementWorldUp;
			if (GrappleComp.ActiveGrappleData.CanShiftGravity())
				UpVector = GrappleComp.ActiveGrappleData.WorldUp;

			const FVector SplineLocation = MovementSpline.GetLocation(Alpha);
			const FVector SplineDirection = MovementSpline.GetDirection(Alpha);
			const FRotator TargetRotation = FRotator::MakeFromZX(-GravityDirection, SplineDirection);
			const FVector DeltaMovement = (SplineLocation - Player.ActorLocation);

			Movement.SetRotation(TargetRotation);
			Movement.AddDeltaWithCustomVelocity(DeltaMovement, FVector::ZeroVector);
			MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"GravityBladeGrapple");
		}

		if (GrappleComp.ActiveGrappleData.CanShiftGravity())
			Player.OverrideGravityDirection(GravityDirection, Skyline::GravityProxy);

		GrappleComp.AnimationData.GrappleStateAlpha = Alpha;
		TickDuration = ActiveDuration;

		float FFFrequency = 50.0;
		float FFIntensity = 0.3;
		FHazeFrameForceFeedback FF;
		FF.LeftMotor = Math::Sin(ActiveDuration * FFFrequency) * FFIntensity;
		FF.RightMotor = Math::Sin(-ActiveDuration * FFFrequency) * FFIntensity;
		Player.SetFrameForceFeedback(FF);
	}

	private float RecalculateSpline()
	{
		MovementSpline = FHazeRuntimeSpline();
		MovementSpline.AddPoint(StartTransform.Location);
		MovementSpline.AddPoint(GrappleComp.ActiveGrappleData.WorldLocation);

		return MovementSpline.Length;
	}
}