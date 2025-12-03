class UGravityBikeSplineRedirectVelocityCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::Movement);

	default TickGroup = EHazeTickGroup::Movement;
	default TickGroupOrder = 50;

	AGravityBikeSpline GravityBike;
	UGravityBikeSplineMovementComponent MoveComp;
	UGravityBikeSplineMovementData MoveData;

	UGravityBikeSplineRedirectVelocityComponent RedirectVelocityComp;

	AGravityBikeSplineRedirectVelocityVolume CurrentRedirectVelocityVolume;

	FVector StartVelocity;
	FVector EndVelocity;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		GravityBike = Cast<AGravityBikeSpline>(Owner);
		MoveComp = GravityBike.MoveComp;
		MoveData = MoveComp.SetupMovementData(UGravityBikeSplineMovementData);

		RedirectVelocityComp = UGravityBikeSplineRedirectVelocityComponent::Get(GravityBike);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(MoveComp.HasMovedThisFrame())
			return false;

		if(!GravityBike.IsAirborne.Get())
			return false;

		if(RedirectVelocityComp.CurrentRedirectVelocityVolumes.IsEmpty())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(MoveComp.HasMovedThisFrame())
			return true;

		if(MoveComp.HasAnyValidBlockingContacts())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		CurrentRedirectVelocityVolume = RedirectVelocityComp.CurrentRedirectVelocityVolumes.Last();

		if(CurrentRedirectVelocityVolume.bUseDuration)
		{
			const FVector WorldUp = GravityBike.GetGlobalWorldUp();
			StartVelocity = MoveComp.Velocity.VectorPlaneProject(WorldUp);
			EndVelocity = CurrentRedirectVelocityVolume.RedirectVelocityDirectionComp.ForwardVector.VectorPlaneProject(WorldUp).GetSafeNormal() * StartVelocity.Size();
		}

		GravityBike.SteeringComp.SteeringMultiplier.Apply(GravityBike.Settings.AirSteerMultiplier, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		GravityBike.SteeringComp.SteeringMultiplier.Clear(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		const FVector WorldUp = GravityBike.GetGlobalWorldUp();

		if(!MoveComp.PrepareMove(MoveData, WorldUp))
			return;

		if(HasControl())
		{
			const FVector Velocity = MoveComp.Velocity;
			FVector HorizontalVelocity = MoveComp.Velocity.VectorPlaneProject(WorldUp);

			{
				FVector VerticalVelocity = Velocity - HorizontalVelocity;

				FVector VerticalDelta = FVector::ZeroVector;
				Acceleration::ApplyAccelerationToVelocity(VerticalVelocity, MoveComp.Gravity, DeltaTime, VerticalDelta);
				VerticalDelta += VerticalVelocity * DeltaTime;

				MoveData.AddDeltaWithCustomVelocity(VerticalDelta, VerticalVelocity);
			}

			if(CurrentRedirectVelocityVolume.bUseDuration)
			{
				TickDuration(HorizontalVelocity);
			}
			else
			{
				TickRotateSpeed(HorizontalVelocity, DeltaTime);
			}

			MoveData.AddVelocity(HorizontalVelocity);
			
			GravityBike.TurnBike(MoveData, DeltaTime);

			const FVector Forward = GravityBike.ActorForwardVector.VectorPlaneProject(WorldUp).GetSafeNormal();
			const FVector Right = GravityBike.ActorRightVector.VectorPlaneProject(WorldUp).GetSafeNormal();

			MoveData.AddDirectionalDrag(MoveComp.Velocity, 0.1, Forward);
			MoveData.AddDirectionalDrag(MoveComp.Velocity, 1, Right);

			MoveData.AddPendingImpulses();
		}
		else
		{
			MoveData.ApplyCrumbSyncedAirMovement();
		}

		MoveComp.ApplyMove(MoveData);
	}

	void TickRotateSpeed(FVector& HorizontalVelocity, float DeltaTime) const
	{
		const FVector WorldUp = GravityBike.GetGlobalWorldUp();
		const float Alpha = Math::Saturate(ActiveDuration / Math::Max(CurrentRedirectVelocityVolume.FadeInDuration, KINDA_SMALL_NUMBER));
		const float RotateAngleDelta = CurrentRedirectVelocityVolume.RotateSpeed * Alpha * DeltaTime;

		FVector TargetDirection = CurrentRedirectVelocityVolume.RedirectVelocityDirectionComp.ForwardVector;
		TargetDirection = TargetDirection.VectorPlaneProject(WorldUp).GetSafeNormal();

#if !RELEASE
		const FTemporalLog TemporalLog = TEMPORAL_LOG(RedirectVelocityComp);
		TemporalLog.DirectionalArrow("Horizontal Direction", GravityBike.ActorCenterLocation + FVector(0, 0, 100), HorizontalVelocity.GetSafeNormal() * 500, 10, 20, FLinearColor::Red);
		TemporalLog.DirectionalArrow("Target Direction", GravityBike.ActorCenterLocation + FVector(0, 0, 100), TargetDirection.GetSafeNormal() * 500, 10, 20, FLinearColor::Green);
#endif

		HorizontalVelocity = HorizontalVelocity.RotateTowards(TargetDirection, Math::RadiansToDegrees(RotateAngleDelta));
	}

	void TickDuration(FVector& HorizontalVelocity) const
	{
		const FVector WorldUp = GravityBike.GetGlobalWorldUp();

		float Alpha = Math::Saturate(ActiveDuration / CurrentRedirectVelocityVolume.RotateDuration);
		Alpha = CurrentRedirectVelocityVolume.RotateDurationAlphaCurve.GetFloatValue(Alpha);

		FVector TargetDirection = CurrentRedirectVelocityVolume.RedirectVelocityDirectionComp.ForwardVector;
		TargetDirection = TargetDirection.VectorPlaneProject(WorldUp).GetSafeNormal();

#if !RELEASE
		const FTemporalLog TemporalLog = TEMPORAL_LOG(RedirectVelocityComp);
		TemporalLog.DirectionalArrow("Horizontal Direction", GravityBike.ActorCenterLocation + FVector(0, 0, 100), HorizontalVelocity.GetSafeNormal() * 500, 10, 20, FLinearColor::Red);
		TemporalLog.DirectionalArrow("Target Direction", GravityBike.ActorCenterLocation + FVector(0, 0, 100), TargetDirection.GetSafeNormal() * 500, 10, 20, FLinearColor::Green);
#endif

		HorizontalVelocity = Math::Lerp(StartVelocity, EndVelocity, Alpha);
	}
};