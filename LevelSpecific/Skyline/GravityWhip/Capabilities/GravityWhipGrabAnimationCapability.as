class UGravityWhipGrabAnimationCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(GravityWhipTags::GravityWhip);
	default CapabilityTags.Add(GravityWhipTags::GravityWhipGrabAnimation);

	default DebugCategory = GravityWhipTags::GravityWhip;

	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 110;

	UGravityWhipUserComponent UserComp;
	bool bHolstered = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		UserComp = UGravityWhipUserComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!UserComp.IsGrabbingAny())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!UserComp.IsGrabbingAny())
		{
			float TimeSinceRelease = Time::GetGameTimeSince(UserComp.ReleaseTimestamp);
			if (TimeSinceRelease > GravityWhip::Grab::ReleaseDuration)
				return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.Mesh.ResetSubAnimationInstance(EHazeAnimInstEvalType::Override);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		UserComp.AnimationData.bIsRequestingWhip = false;
		UGravityWhipEventHandler::Trigger_WhipFinishedRetracting(Player);
	}

	bool ShouldWhipBeHolstered() const
	{
		if (UserComp.bIsHolstered)
			return true;
		if (IsBlocked())
			return true;
		if (!Player.Mesh.CurrentOverrideFeatureMatchesRequest(n"GravityWhip"))
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (bHolstered)
		{
			if (!ShouldWhipBeHolstered())
			{
				UserComp.Whip.AttachToComponent(Player.Mesh, GravityWhip::Common::AttachSocket, EAttachmentRule::SnapToTarget);

				UGravityWhipEventHandler::Trigger_WhipUnholstered(Player);
				bHolstered = false;
			}
		}
		else
		{
			if (ShouldWhipBeHolstered())
			{
				UserComp.Whip.AttachToComponent(Player.Mesh, GravityWhip::Common::IdleAttachSocket, EAttachmentRule::SnapToTarget);
				UserComp.Whip.ActorRelativeTransform = GravityWhip::Common::IdleAttachTransform;

				UGravityWhipEventHandler::Trigger_WhipHolstered(Player);
				bHolstered = true;
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (UserComp.IsGrabbingAny())
		{
			UserComp.AnimationData.TargetComponents.Empty();
			UserComp.GetGrabbedComponents(UserComp.AnimationData.TargetComponents);
		}

		if (Player.Mesh.CanRequestOverrideFeature() && UserComp.IsGrabbingAny())
		{
			Player.Mesh.RequestOverrideFeature(n"GravityWhip", this);
			UserComp.AnimationData.bIsRequestingWhip = true;
		}
		else
		{
			UserComp.AnimationData.bIsRequestingWhip = false;
		}

		UpdateSpringValues(DeltaTime);
	}

	FHazeAcceleratedFloat AccTension;
	FHazeAcceleratedVector AccPullForce;

	void UpdateSpringValues(const float Dt)
	{
		// reset
		if(UserComp.TargetData.TargetComponents.Num() <= 0)
		{
			AccTension.SnapTo(0);
			AccPullForce.SnapTo(FVector::ZeroVector);
			UserComp.AnimationData.Tension = AccTension.Value;
			UserComp.AnimationData.TensionPullDirection = AccPullForce.Value;
			UserComp.AnimationData.TensionPullDirection2D = FVector2D::ZeroVector;
			return;
		}

		// the test map only has 1 component in the array no matter what I target atm.
		auto Target = UserComp.TargetData.TargetComponents[0];

		const FVector TargetForce = Target.PrevPendingForce;
		const FVector COM = UserComp.GrabCenterLocation; 

		const FVector ToTarget = (COM-Player.GetActorCenterLocation());
		float Tension = Math::Saturate(TargetForce.Size() / GravityWhip_VFX::MaxTensionForceSize); 

		// we want the tangent to become shorter as you get closer to the target,
		float DistToTargetScaler = ToTarget.Size() / GravityWhip_VFX::StartShrinkingTangentsDistanceThreshold;

		// we clamp it in order for our max lengths to stay true
		// and it will also give of tension in the string as you move backwards
		// because the tangents will have less bending impact on the string
		DistToTargetScaler = Math::Saturate(DistToTargetScaler);

		// Smooth out the tension
		const float TensionStiffness = Tension != 0 ? 400 : 50;
		const float TensionDamping = Tension != 0 ? 0.6 : 0;
		AccTension.SpringTo(Tension, TensionStiffness, TensionDamping, Dt);

		// We want a bouncy tension so we'll clamp it at the edges and make sure its always positive.
		const float FinalTension = Math::Min(Math::Abs(AccTension.Value), 1.0);
		UserComp.AnimationData.Tension = FinalTension;

		FVector PullForce = TargetForce * GravityWhip_VFX::ForceStrengthScaler * DistToTargetScaler;
		PullForce *= FinalTension;

		AccPullForce.SpringTo(
			PullForce,
			400.0,
			Tension == 0.0 ? 0 : 0.6,
			Dt
		);

		UserComp.AnimationData.TensionPullDirection = AccPullForce.Value;
		UserComp.AnimationData.TensionPullDirection2D.X = AccPullForce.Value.DotProduct(Player.GetActorRightVector());
		UserComp.AnimationData.TensionPullDirection2D.Y = AccPullForce.Value.DotProduct(Player.GetActorUpVector());
	}
}