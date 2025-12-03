struct FMagnetDroneAttractionModesActivateParams
{
	TSubclassOf<UMagnetDroneAttractionMode> AttractionModeClass;
}

struct FMagnetDroneAttractionModesDeactivateParams
{
	bool bFinished = false;
}

class UMagnetDroneAttractionModesCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default DebugCategory = Drone::DebugCategory;

	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(PrisonTags::Prison);
	default CapabilityTags.Add(PrisonTags::Drones);
	default CapabilityTags.Add(MagnetDroneTags::MagnetDrone);
	default CapabilityTags.Add(MagnetDroneTags::MagnetDroneAttraction);

	default BlockExclusionTags.Add(MagnetDroneTags::AttachToBoatBlockExclusionTag);

	default TickGroup = MagnetDrone::AttractionTickGroup;
	default TickGroupOrder = MagnetDrone::AttractionTickGroupOrder;
	default TickGroupSubPlacement = 50;	// Way before the others (for testing)

	UMagnetDroneComponent DroneComp;
	UMagnetDroneAttractionComponent AttractionComp;
	UMagnetDroneAttachedComponent AttachedComp;

	UHazeMovementComponent MoveComp;
	UMagnetDroneAttractionMovementData MoveData;

	UMagnetDroneAttractionMode ActiveAttractionMode;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DroneComp = UMagnetDroneComponent::Get(Player);
		AttractionComp = UMagnetDroneAttractionComponent::Get(Player);
		AttachedComp = UMagnetDroneAttachedComponent::Get(Player);

		MoveComp = UHazeMovementComponent::Get(Player);
		MoveData = MoveComp.SetupMovementData(UMagnetDroneAttractionMovementData);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FMagnetDroneAttractionModesActivateParams& Params) const
	{
		if(MoveComp.HasMovedThisFrame())
			return false;

		if(!AttractionComp.HasSetStartAttractTargetThisFrame())
			return false;

		if(AttractionComp.IsAttracting())
			return false;

		if(AttachedComp.IsAttached())
			return false;

		if(!AttractionComp.HasAttractionTarget())
			return false;

		auto ShouldActivateParams = FMagnetDroneAttractionModeShouldActivateParams(
			Player.ActorLocation,
			Player.ActorVelocity,
			AttachedComp.IsAttached(),
			AttractionComp.GetAttractionTarget(),
			AttractionComp.GetAttractionTargetInstigator(),
			false,
		);

		TSubclassOf<UMagnetDroneAttractionMode> AttractionModeClass = nullptr;
		for(UMagnetDroneAttractionMode AttractionMode : AttractionComp.AttractionModes)
		{
			if(!AttractionMode.ShouldActivate(ShouldActivateParams))
				continue;

			AttractionModeClass = AttractionMode.Class;
			break;
		}

		if(!AttractionModeClass.IsValid())
			return false;

		Params.AttractionModeClass = AttractionModeClass;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FMagnetDroneAttractionModesDeactivateParams& Params) const
	{
		if(AttachedComp.IsAttached())
		{
			Params.bFinished = true;
			return true;
		}

		if(MoveComp.HasMovedThisFrame())
		{
			Params.bFinished = AttachedComp.AttachedThisFrame();
			return true;
		}

		if(!AttractionComp.HasAttractionTarget())
			return true;

		// While attracting, check if we have finished
		for(const FMovementHitResult& Impact : MoveComp.AllImpacts)
		{
			FMagnetDroneTargetData PendingTargetData = AttractionComp.GetAttractionTarget();
			EMagnetDroneIntendedTargetResult Result = MagnetDrone::WasImpactIntendedTarget(
				Impact.ConvertToHitResult(),
				Player.ActorLocation,
				Player.ActorVelocity,
				PendingTargetData
			);

			switch(Result)
			{
				case EMagnetDroneIntendedTargetResult::Finish:
				{
					Params.bFinished = true;
					return true;
				}

				case EMagnetDroneIntendedTargetResult::Continue:
					break;

				case EMagnetDroneIntendedTargetResult::Invalidate:
					return true;
			}
		}

		if(ActiveDuration > 1.0 && AttractionComp.GetAttractionMightBeStuckThisFrame())
		{
			Params.bFinished = AttachedComp.AttachedThisFrame();
			return true;
		}

		if(Player.ActorLocation.Equals(AttractionComp.GetAttractionTarget().GetTargetLocation(), 0.1))
		{
			Params.bFinished = true;
			return true;
		}

		if(AttractionComp.GetAttractionTarget().IsSocket())
		{
			// If we pass the plane the socket is on, immediately attach so we don't fly past it
			const FVector RelativeToSocket = AttractionComp.GetAttractionTarget().GetSocketComp().WorldTransform.InverseTransformPositionNoScale(Player.ActorLocation);
			if(RelativeToSocket.X < 1)
			{
				// We are behind the socket
				// Check if we are close enough horizontally, and attach if we are
				if(RelativeToSocket.Size2D(FVector::ForwardVector) < AttractionComp.GetAttractionTarget().GetSocketComp().AttachRadius)
				{
					Params.bFinished = true;
					return true;
				}
			}
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FMagnetDroneAttractionModesActivateParams Params)
	{
		AttractionComp.StartAttraction(this);

		ActiveAttractionMode = AttractionComp.GetAttractionMode(Params.AttractionModeClass);
		
		FMagnetDroneAttractionModePrepareAttractionParams SetupAttractionParams(
			Player,
			AttractionComp.GetAttractionTarget()
		);

		ActiveAttractionMode.RunPrepareAttraction(SetupAttractionParams, AttractionComp.AttractionStartedParams.TimeUntilArrival, this);

		// The attraction mode might have modified our initial state
		SetupAttractionParams.ApplyOnPlayer(Player);

		// broadcast event that we started attracting, trigger cameras, effects, etc. 
		UMagnetDroneEventHandler::Trigger_AttractionStarted(Player, AttractionComp.AttractionStartedParams);

		Player.ApplyCameraSettings(DroneComp.Settings.CamSettings_AttractionStarted, 1, this, SubPriority = 90);

		if(AttractionComp.ShouldApplyAttractionFOV())
			UCameraSettings::GetSettings(Player).FOV.Apply(DroneComp.Settings.AttractionFOV, this, 1);

		Player.BlockCapabilities(MagnetDroneTags::MagnetDroneAim, this);
	
		UMovementStandardSettings::SetWalkableSlopeAngle(Player, 90, this);
		UDroneMovementSettings::SetRollMaxSpeed(Player, 30, this);

		if(AttractionComp.GetAttractionTarget().ShouldAttractRelative())
		{
			MoveComp.FollowComponentMovement(AttractionComp.GetAttractionTarget().GetTargetComp(), this);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FMagnetDroneAttractionModesDeactivateParams Params)
	{
		ActiveAttractionMode.Reset();
		ActiveAttractionMode = nullptr;

		AttractionComp.FinishAttraction(Params.bFinished, this);

		if(Params.bFinished)
		{
			if(AttractionComp.AttractionTarget.IsSurface())
			{
				AttachedComp.AttachToSurface(
					AttractionComp.AttractionTarget,
					AttractionComp.GetAttractionStartedParams(),
					this
				);
			}
			else if(AttractionComp.AttractionTarget.IsSocket())
			{
				AttachedComp.AttachToSocket(
					AttractionComp.AttractionTarget,
					AttractionComp.GetAttractionStartedParams(),
					this
				);
			}
		}
		else
		{
			// broadcast that we canceled the attraction mid-Attraction
			UMagnetDroneEventHandler::Trigger_AttractionCanceled(Player);
			Player.SetActorVelocity(Player.ActorVelocity.GetClampedToMaxSize(AttractionComp.Settings.AttractionFailMaxSpeed));
		}

		Player.ClearCameraSettingsByInstigator(this, 1.0);
		Player.StopAllCameraShakes();
		Player.UnblockCapabilities(MagnetDroneTags::MagnetDroneAim, this);

		UMovementStandardSettings::ClearWalkableSlopeAngle(Player, this);
		UDroneMovementSettings::ClearRollMaxSpeed(Player, this);

		MoveComp.UnFollowComponentMovement(this, EMovementUnFollowComponentTransferVelocityType::KeepInheritedVelocity);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		if(!MoveComp.PrepareMove(MoveData))
			return;

		if(HasControl())
		{
			CalculateDeltaMove(DeltaTime);

			if(!MoveComp.HorizontalVelocity.IsNearlyZero(1.0))
				MoveData.SetRotation(FRotator::MakeFromXZ(MoveComp.Velocity, Player.MovementWorldUp));

			MoveData.IgnoreSplineLockConstraint();
		}
		else
		{
			MoveData.ApplyCrumbSyncedAirMovement();
		}

		MoveComp.ApplyMove(MoveData);

#if !RELEASE
		ActiveAttractionMode.GetTemporalLog(false).Status(f"Running {ActiveAttractionMode.Class.Name.PlainNameString}", ActiveAttractionMode.DebugColor);

		FTemporalLog TemporalLog = ActiveAttractionMode.GetTemporalLog();
		TemporalLog.Value("Attraction Alpha", AttractionComp.GetAttractionAlpha());
		ActiveAttractionMode.LogToTemporalLog(
			TemporalLog,
			FMagnetDroneAttractionModeLogParams(
				AttractionComp.GetAttractionAlpha(),
				ActiveDuration,
				Player.ActorLocation
			)
		);
#endif
	}

	void CalculateDeltaMove(float DeltaTime)
	{
		ActiveAttractionMode.RunApplyTargetDeltaTransform();

		auto TickAttractionParams = FMagnetDroneAttractionModeTickAttractionParams(
			Player.ActorLocation,
			Player.ActorVelocity,
			ActiveDuration,
			Time::GameTimeSeconds,
		);

		float AttractionAlpha = AttractionComp.GetAttractionAlpha();
		FVector DesiredLocation = ActiveAttractionMode.RunTickAttraction(TickAttractionParams, DeltaTime, AttractionAlpha);
		AttractionComp.SetAttractionAlpha(AttractionAlpha);

		if(AttractionComp.GetAttractionTarget().IsSocket())
		{
			// If we pass the plane the socket is on, immediately attach so we don't fly past it
			const FVector RelativeToSocket = AttractionComp.GetAttractionTarget().GetSocketComp().WorldTransform.InverseTransformPositionNoScale(DesiredLocation);
			if(RelativeToSocket.X < 0)
			{
				// We are behind the socket
				// Check if we are close enough horizontally, and put us in the socket if we are
				if(RelativeToSocket.Size2D(FVector::ForwardVector) < AttractionComp.GetAttractionTarget().GetSocketComp().AttachRadius)
					DesiredLocation = AttractionComp.GetAttractionTarget().GetTargetLocation();
			}
		}

		MoveData.AddDeltaFromMoveTo(DesiredLocation);
	}
}