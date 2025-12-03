class UGravityBladeGrappleThrowCapability : UHazeChildCapability
{
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::LocalOrCrumbNetwork;

	default CapabilityTags.Add(GravityBladeTags::GravityBlade);

	default CapabilityTags.Add(GravityBladeGrappleTags::GravityBladeGrapple);
	default CapabilityTags.Add(GravityBladeGrappleTags::GravityBladeGrappleThrow);

	default DebugCategory = GravityBlade::DebugCategory;
	
	AHazePlayerCharacter Player;

	UGravityBladeUserComponent BladeComp;
	UGravityBladeGrappleUserComponent GrappleComp;

	UPlayerMovementComponent MoveComp;
	USteppingMovementData Movement;

	float ThrowDuration;
	FVector StartLocation;
	FHazeRuntimeSpline BladeSpline;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);

		BladeComp = UGravityBladeUserComponent::Get(Owner);
		GrappleComp = UGravityBladeGrappleUserComponent::Get(Owner);
		
		MoveComp = UPlayerMovementComponent::Get(Owner);
		Movement = MoveComp.SetupSteppingMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (GrappleComp.AnimationData.GrappleStateAlpha >= 1.0) // if (ActiveDuration > ThrowDuration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		StartLocation = BladeComp.Blade.ActorLocation;

		const float NewLength = RecalculateSpline();
		ThrowDuration = (NewLength / GravityBladeGrapple::ThrowSpeed);

		const FRotator TargetRotation = FRotator::MakeFromZX(Player.MovementWorldUp, BladeSpline.GetDirection(0.0));
		Player.ActorRotation = TargetRotation;

		FGravityBladeThrowData ThrowData;
		ThrowData.Location = Player.Mesh.GetSocketLocation(n"RightAttach");
		ThrowData.Normal = BladeComp.Blade.ActorUpVector;
		ThrowData.ThrowDuration = ThrowDuration;
		
		UGravityBladeGrappleEventHandler::Trigger_StartThrow(BladeComp.Blade, ThrowData);

		if (GrappleComp.ActiveGrappleData.ResponseComponent != nullptr)
			GrappleComp.ActiveGrappleData.ResponseComponent.ThrowStart(GrappleComp, ThrowData);

		GrappleComp.AnimationData.LastGrappleThrowFrame = Time::FrameNumber;
		GrappleComp.AnimationData.bGrappleGrounded = MoveComp.IsOnAnyGround();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if (GrappleComp.ActiveGrappleData.IsValid())
		{
			BladeComp.Blade.ActorLocation = GrappleComp.ActiveGrappleData.WorldLocation;
			BladeComp.Blade.AttachToActor(GrappleComp.ActiveGrappleData.Actor, NAME_None, EAttachmentRule::KeepWorld);
		}

		FGravityBladeThrowData ThrowData;
		ThrowData.Location = BladeComp.Blade.ActorLocation;
		ThrowData.Normal = BladeComp.Blade.ActorUpVector;
		UGravityBladeGrappleEventHandler::Trigger_EndThrow(BladeComp.Blade, ThrowData);

		if (GrappleComp.ActiveGrappleData.ResponseComponent != nullptr)
			GrappleComp.ActiveGrappleData.ResponseComponent.ThrowEnd(GrappleComp, ThrowData);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Recalculate the spline if the target has moved away
		const FVector TargetLocationDelta = (BladeSpline.Points.Last() - GrappleComp.ActiveGrappleData.WorldLocation);
		if (!TargetLocationDelta.IsNearlyZero(SMALL_NUMBER))
			RecalculateSpline();

		float Alpha = Math::Saturate(ActiveDuration / ThrowDuration);
		Alpha = Math::EaseIn(0.0, 1.0, Alpha, 4.0);

		if (MoveComp.PrepareMove(Movement))
		{
			const FVector PlayerDirection = (GrappleComp.ActiveGrappleData.WorldLocation - Player.ActorLocation).GetSafeNormal();

			Movement.AddOwnerVelocity();
			Movement.SetRotation(PlayerDirection.Rotation());
			Movement.RequestFallingForThisFrame();
			MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"GravityBladeGrapple");
		}

		const FVector BladeLocation = BladeSpline.GetLocation(Alpha);
		const FVector BladeDirection = BladeSpline.GetDirection(Alpha);
		const FRotator BladeRotation = FRotator::MakeFromZX(BladeDirection, -Player.MovementWorldUp);

		BladeComp.Blade.SetActorLocationAndRotation(
			BladeLocation,
			BladeRotation
		);

		GrappleComp.AnimationData.GrappleStateAlpha = Alpha;
	}

	private float RecalculateSpline()
	{
		BladeSpline = FHazeRuntimeSpline();
		BladeSpline.AddPoint(StartLocation);
		BladeSpline.AddPoint(GrappleComp.ActiveGrappleData.WorldLocation);
		BladeSpline.SetCustomExitTangentPoint(GrappleComp.ActiveGrappleData.WorldLocation - GrappleComp.ActiveGrappleData.WorldUp);
		BladeSpline.SetCustomCurvature(0.9);

		return BladeSpline.Length;
	}
}