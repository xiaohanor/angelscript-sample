class UGravityBladeGrappleTransitionCapability : UHazeChildCapability
{
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::LocalOrCrumbNetwork;

	default CapabilityTags.Add(GravityBladeTags::GravityBlade);

	default CapabilityTags.Add(GravityBladeGrappleTags::GravityBladeGrapple);
	default CapabilityTags.Add(GravityBladeGrappleTags::GravityBladeGrappleTransition);

	default DebugCategory = GravityBlade::DebugCategory;

	AHazePlayerCharacter Player;

	UGravityBladeUserComponent BladeComp;
	UGravityBladeGrappleUserComponent GrappleComp;

	UPlayerMovementComponent MoveComp;
	USteppingMovementData Movement;

	FVector StartVelocity;
	float TransitionDuration;

	UGravityBladeGrappleTransitionCapability(float InTransitionDuration)
	{
		TransitionDuration = InTransitionDuration;
	}

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
		if (ActiveDuration > TransitionDuration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		StartVelocity = MoveComp.Velocity;

		GrappleComp.AnimationData.LastGrappleTransitionFrame = Time::FrameNumber;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		const float Alpha = Math::Saturate(ActiveDuration / TransitionDuration);

		if (MoveComp.PrepareMove(Movement))
		{
			Movement.AddVelocity(Math::Lerp(StartVelocity, FVector::ZeroVector, Alpha));
			MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"GravityBladeGrapple");
		}

		GrappleComp.AnimationData.GrappleStateAlpha = Alpha;
	}
}