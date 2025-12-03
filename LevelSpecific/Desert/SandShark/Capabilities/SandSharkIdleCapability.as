struct FSandSharkIdleActivateParams
{
	float Time;
} struct FSandSharkIdleDeactivatedParams
{
	float Time;
}

class USandSharkIdleCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(SandSharkTags::SandShark);
	default CapabilityTags.Add(SandSharkTags::SandSharkIdle);
	default CapabilityTags.Add(SandSharkBlockedWhileIn::Chase);
	default CapabilityTags.Add(SandSharkBlockedWhileIn::Attack);
	default CapabilityTags.Add(SandSharkBlockedWhileIn::Distract);

	default TickGroup = EHazeTickGroup::Movement;
	default TickGroupOrder = SandShark::TickGroupOrder::Idle;

	ASandShark SandShark;
	USandSharkMovementComponent MoveComp;
	USandSharkAnimationComponent AnimationComp;
	USandSharkSettings SharkSettings;

	FVector Velocity;

	float CurrentDistance = 0;
	FHazeRuntimeSpline RuntimeSpline;

	FNavigationPath PrevPath;

	bool bUseRockAvoidanceSettings = false;

	FHazeAcceleratedRotator AccRotation;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SandShark = Cast<ASandShark>(Owner);
		MoveComp = USandSharkMovementComponent::Get(Owner);
		AnimationComp = USandSharkAnimationComponent::Get(Owner);

		SharkSettings = USandSharkSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FSandSharkIdleActivateParams& Params) const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;

		if (!Desert::HasLandscapeForLevel(SandShark.LandscapeLevel))
			return false;

		if (Desert::GetRelevantLandscapeLevel() != SandShark.LandscapeLevel)
			return false;

		Params.Time = Time::GameTimeSeconds;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FSandSharkIdleDeactivatedParams& Params) const
	{
		if (!Desert::HasLandscapeForLevel(SandShark.LandscapeLevel))
			return true;

		if (MoveComp.HasMovedThisFrame())
		{
			Params.Time = Time::GameTimeSeconds;
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FSandSharkIdleActivateParams Params)
	{
		Velocity = FVector::ZeroVector;
		CurrentDistance = 0;
		if (SandShark.MoveToComp.Path.IsValid())
		{
			auto Points = SandShark.MoveToComp.Path.Points;
			if (Points.Num() >= 2)
			{
				RuntimeSpline.SetPoints(Points);
			}
		}

		PrevPath = SandShark.MoveToComp.Path;
		AccRotation.SnapTo(SandShark.ActorRotation);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FSandSharkIdleDeactivatedParams Params)
	{
		RuntimeSpline = FHazeRuntimeSpline();
		AnimationComp.Data.BoneRelaxSpeedScale = 0.0;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (HasControl())
		{
			SandShark.AccMeshForwardOffset.AccelerateTo(-530, 0.5, DeltaTime);
			auto TraceSettings = SandShark.GetTraceSettings(100);
			const auto Overlaps = TraceSettings.QueryOverlaps(
				Desert::GetLandscapeLocationByLevel(SandShark.ActorLocation, SandShark.LandscapeLevel));

			if (SandShark.DestinationComp.FollowSpline != nullptr)
			{
				if (!Overlaps.HasBlockHit())
				{
					MoveComp.AccDive.AccelerateTo(SandShark::Idle::Height, SandShark::Idle::HeightDuration, DeltaTime);
					// SandShark.bIsAvoidingObstacles = false;
				}
				else
				{
					float Duration = 0.25;
					if (ActiveDuration < 1.0)
						Duration = 1.0;
					MoveComp.AccDive.AccelerateTo(SandShark::Idle::Height - 250, Duration, DeltaTime);
					// SandShark.bIsAvoidingObstacles = true;
				}

				MoveComp.AccMovementSpeed.AccelerateTo(SharkSettings.IdleMovement.MovementSpeed, SharkSettings.IdleMovement.AccelerationDuration, DeltaTime);
				auto SplinePos = SandShark.DestinationComp.FollowSplinePosition;
				FVector PrevLocation = SandShark.ActorLocation;

				SplinePos.Move(SandShark.DestinationComp.Speed * DeltaTime);

				FVector ToSharkFromSpline = (SandShark.ActorLocation - SandShark.DestinationComp.FollowSplinePosition.WorldLocation);
				float Offset = SandShark.DestinationComp.FollowSplinePosition.WorldRightVector.DotProduct(ToSharkFromSpline);
				float NewOffset = Math::FInterpTo(Offset, 0, DeltaTime, 1);
				float OffsetDelta = NewOffset - Offset;
				if (Math::IsNearlyZero(OffsetDelta, KINDA_SMALL_NUMBER))
					OffsetDelta = 0;
				FVector SplineDelta = SplinePos.WorldRightVector * OffsetDelta;
				FVector NewLocation = Desert::GetLandscapeLocationByLevel(SplinePos.WorldLocation + SplineDelta, SandShark.LandscapeLevel);
				FVector MoveDelta = NewLocation - PrevLocation;

				AccRotation.AccelerateTo(MoveDelta.ToOrientationRotator(), 0.75, DeltaTime);
				MoveComp.ApplyMove(NewLocation, AccRotation.Value.Quaternion(), this);
			}
			else
			{
				if (SandShark.MoveToComp.Path.IsValid())
				{
					if (SandShark.MoveToComp.Path.Points != PrevPath.Points)
					{
						auto Points = SandShark.MoveToComp.Path.Points;
						if (Points.Num() >= 2)
						{
							RuntimeSpline.SetPoints(Points);
							CurrentDistance = 0;
						}
					}
					AccRotation.SnapTo(SandShark.ActorRotation);
					// RuntimeSpline.DrawDebugSpline();
					FVector Location = RuntimeSpline.GetLocationAtDistance(CurrentDistance + 100);
					// Debug::DrawDebugSphere(Location, 25, 12);
					FSandSharkMovementData MoveData = SharkSettings.IdleMovement;
					float Dot = (Location - SandShark.ActorLocation).GetSafeNormal().DotProduct(SandShark.ActorForwardVector);
					if (Dot < 0.2 || Overlaps.HasBlockHit())
					{
						SandShark.bIsAvoidingObstacles = true;
						MoveData.MaxTurnAngle = 180;
						MoveData.TurnSpeed = 720;
						MoveData.MovementSpeedTurning = 400;
						if (Overlaps.HasBlockHit())
							MoveComp.AccDive.AccelerateTo(SandShark::Idle::Height - 350, 0.5, DeltaTime);
						else
							MoveComp.AccDive.AccelerateTo(SandShark::Idle::Height - 140, 0.5, DeltaTime);
					}
					else
						MoveComp.AccDive.AccelerateTo(SandShark::Idle::Height, SandShark::Idle::HeightDuration + 0.5, DeltaTime);

					float Speed = MoveComp.AccMovementSpeed.Value;
					CurrentDistance += Speed * DeltaTime;
					CurrentDistance = Math::Clamp(CurrentDistance, 0, RuntimeSpline.Length);
					if (MoveComp.AccDive.Value < -340)
					{
						MoveComp.AccMovementSpeed.AccelerateTo(MoveData.MovementSpeed, 0.5, DeltaTime);
						FVector OutLocation;
						FRotator OutRotation;
						RuntimeSpline.GetLocationAndRotationAtDistance(CurrentDistance, OutLocation, OutRotation);
						MoveComp.ApplyMove(OutLocation, OutRotation.Quaternion(), this);
					}
					else
					{
						MoveData.MaxTurnAngle = 120;
						MoveData.TurnSpeed = 60;
						MoveComp.MoveNavigateToLocationNoOvershoot(MoveData, Location, DeltaTime, MoveData.MovementSpeed, this);
					}

					PrevPath = SandShark.MoveToComp.Path;
				}
			}
		}
		else
		{
			// Remote movement
			MoveComp.ApplyCrumbSyncedLocationAndRotation(this);
		}
		
		if (SandShark.SyncedMeshLocationComp.Value.Z < -250)
		{
			AnimationComp.Data.BoneRelaxSpeedScale = 4.0;
		}
		else
		{
			AnimationComp.Data.BoneRelaxSpeedScale = 0.0;
		}
	}
};