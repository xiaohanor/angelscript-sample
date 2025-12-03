class UDentistToothDoubleCannonLaunchedDetachedCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::Movement);
	default BlockExclusionTags.Add(Dentist::DoubleCannon::DentistDoubleCannonBlockExclusionTag);

	default DebugCategory = n"Movement";

	default TickGroup = EHazeTickGroup::Movement;
	default TickGroupOrder = 52;

	UDentistToothPlayerComponent PlayerComp;
	UDentistToothDoubleCannonComponent CannonComp;

	UPlayerMovementComponent MoveComp;
	USimpleMovementData MoveData;

	float StartTimeSinceLaunch;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PlayerComp = UDentistToothPlayerComponent::Get(Player);
		CannonComp = UDentistToothDoubleCannonComponent::Get(Player);

		MoveComp = UPlayerMovementComponent::Get(Player);
		MoveData = MoveComp.SetupSimpleMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;

		if(!CannonComp.IsLaunched())
			return false;

		if(!CannonComp.ShouldBeDetached())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;

		if(!CannonComp.IsLaunched())
			return true;

		if(MoveComp.HasAnyValidBlockingImpacts())
			return true;

		if(!CannonComp.ShouldBeDetached())
			return true;

		// Time out
		if(CannonComp.GetCannon().GetPredictedTimeSinceLaunchStart() > CannonComp.GetLaunchTrajectory().GetTotalTime())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		CannonComp.GetCannon().OnPlayersDetached.Broadcast();
		UDentistToothDoubleCannonEventHandler::Trigger_OnDetached(Player);

		StartTimeSinceLaunch = CannonComp.GetCannon().GetPredictedTimeSinceLaunchStart();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		CannonComp.Reset();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (MoveComp.PrepareMove(MoveData))
		{
			FTransform LaunchTransform = CannonComp.GetCurrentLaunchTransform();
			FQuat Rotation = FQuat::MakeFromZX(FVector::UpVector, MoveComp.Velocity);
			FVector Location = LaunchTransform.Location;

			if (HasControl())
			{
				MoveData.AddDeltaFromMoveTo(Location);
				MoveData.SetRotation(Rotation);
			}
			else
			{
				// Since the crumb trail will be further behind than the launch root, we need to transition from the launch root to the crumb transform
				auto CrumbSyncedPosition = MoveComp.GetCrumbSyncedPosition();

				const float CurrentTime = CannonComp.GetCannon().GetPredictedTimeSinceLaunchStart();
				const float DetachTime = StartTimeSinceLaunch;
				const float TotalTime = CannonComp.GetLaunchTrajectory().GetTotalTime();

				const float Alpha = Math::GetPercentageBetweenClamped(DetachTime, TotalTime, CurrentTime);

				FTransform LerpTransform(
					Math::LerpShortestPath(Rotation.Rotator(), CrumbSyncedPosition.WorldRotation, Alpha),
					Math::Lerp(Location, CrumbSyncedPosition.WorldLocation, Alpha)
				);

				MoveData.ApplyManualSyncedLocationAndRotation(LerpTransform.Location, CrumbSyncedPosition.WorldVelocity, LerpTransform.Rotator());
			}

			MoveComp.ApplyMoveAndRequestLocomotion(MoveData, Dentist::Feature);
		}

		TickMeshRotation(DeltaTime);
	}

	void TickMeshRotation(float DeltaTime)
	{
		if(PlayerComp.HasSetMeshRotationThisFrame())
			return;

		FTransform LaunchTransform = CannonComp.GetCurrentLaunchTransform();

		if(Player.IsZoe())
		{
			// Zoe is rotated the wrong way, so we must flip her
			// Do so smoothly before landing
			const float TimeLeft = CannonComp.GetLaunchTrajectory().GetTotalTime() - CannonComp.GetCannon().GetPredictedTimeSinceLaunchStart();
			const float DetachedDuration = CannonComp.GetLaunchTrajectory().GetTotalTime() - CannonComp.GetCannon().GetDetachTime();
			float TimeLeftAlpha = Math::Saturate(TimeLeft / DetachedDuration);
			TimeLeftAlpha = Math::GetMappedRangeValueClamped(FVector2D(0, 0.8), FVector2D(0, 1), TimeLeftAlpha);
			TimeLeftAlpha = Math::EaseInOut(0, 1, TimeLeftAlpha, 2);
			LaunchTransform.SetRotation(LaunchTransform.TransformRotation(FQuat(FVector::DownVector, PI * (1.0 - TimeLeftAlpha))));
		}

		if(Dentist::DoubleCannon::bApplyRotation)
			PlayerComp.SetMeshWorldRotation(LaunchTransform.Rotation, this, -1, DeltaTime);
	}

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnLogActive(FTemporalLog TemporalLog)
	{
		TemporalLog.Transform("Player Transform", Player.ActorTransform);
		TemporalLog.Transform("Mesh Transform", PlayerComp.GetToothActor().ActorTransform);
		TemporalLog.Transform("Launch Transform", CannonComp.GetCurrentLaunchTransform());
	}
#endif
};