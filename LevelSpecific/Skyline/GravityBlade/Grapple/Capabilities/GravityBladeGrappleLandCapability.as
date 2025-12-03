class UGravityBladeGrappleLandCapability : UHazeChildCapability
{
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::LocalOrCrumbNetwork;

	default CapabilityTags.Add(GravityBladeTags::GravityBlade);

	default CapabilityTags.Add(GravityBladeGrappleTags::GravityBladeGrapple);
	default CapabilityTags.Add(GravityBladeGrappleTags::GravityBladeGrappleLand);

	default DebugCategory = GravityBlade::DebugCategory;

	AHazePlayerCharacter Player;

	UGravityBladeUserComponent BladeComp;
	UGravityBladeGrappleUserComponent GrappleComp;

	UPlayerMovementComponent MoveComp;
	USteppingMovementData Movement;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);

		BladeComp = UGravityBladeUserComponent::Get(Owner);
		GrappleComp = UGravityBladeGrappleUserComponent::Get(Owner);

		MoveComp = UPlayerMovementComponent::Get(Owner);
		Movement = MoveComp.SetupSteppingMovementData();
	}

	private bool ShouldShake()
	{
		if(Player.GetCurrentGameplayPerspectiveMode() == EPlayerMovementPerspectiveMode::SideScroller)
			return false;
		if(GrappleComp.GrappleLandingCameraShake == nullptr)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (GrappleComp.AnimationData.GrappleStateAlpha >= 1.0) // if (ActiveDuration > GravityBladeGrapple::LandDuration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		if (!BladeComp.IsBladeEquipped())
			BladeComp.EquipBlade();

		GrappleComp.AnimationData.LastGrappleLandFrame = Time::FrameNumber;

		if(GrappleComp.GrappleLandingForceFeedback != nullptr)
			Player.PlayForceFeedback(GrappleComp.GrappleLandingForceFeedback, false, true, this);

		if(ShouldShake())
		{
			Player.PlayWorldCameraShake(GrappleComp.GrappleLandingCameraShake, this, Player.ActorLocation, 50, 300);
			Player.OtherPlayer.PlayWorldCameraShake(GrappleComp.GrappleLandingCameraShake, this, Player.ActorLocation, 100, 500, Scale = 0.4);
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		const float Alpha = Math::Saturate(ActiveDuration / GravityBladeGrapple::LandDuration);

		if (MoveComp.PrepareMove(Movement))
		{
			// TODO: Pops into falling for a frame or so if we don't ground ourselves
			auto GroundTrace = Trace::InitFromMovementComponent(MoveComp);
			auto HitResult = GroundTrace.QueryTraceSingle(Player.ActorLocation, Player.ActorLocation - MoveComp.WorldUp * GravityBladeGrapple::StepDownHeight);

			if (HitResult.bBlockingHit && !HitResult.bStartPenetrating)
				Movement.AddDeltaFromMoveToPositionWithCustomHorizontalAndVerticalVelocity(HitResult.Location, FVector::ZeroVector, FVector::ZeroVector);
			
			Movement.OverrideFinalGroundResult(HitResult, true);
			MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"GravityBladeGrapple");
		}

		GrappleComp.AnimationData.GrappleStateAlpha = Alpha;
	}
}