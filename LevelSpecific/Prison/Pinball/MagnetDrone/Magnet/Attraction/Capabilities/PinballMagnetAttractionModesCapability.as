struct FPinballMagnetAttractionModesActivateParams
{
	TSubclassOf<UMagnetDroneAttractionMode> AttractionModeClass;
}

struct FPinballMagnetAttractionModesDeactivateParams
{
	bool bFinished = false;
}

class UPinballMagnetAttractionModesCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Local;
	default DebugCategory = Drone::DebugCategory;

	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(PrisonTags::Prison);
	default CapabilityTags.Add(PrisonTags::Drones);
	default CapabilityTags.Add(MagnetDroneTags::MagnetDrone);
	default CapabilityTags.Add(MagnetDroneTags::MagnetDroneAttraction);
	default CapabilityTags.Add(MagnetDroneTags::BlockedWhileAttached);	// Need to be blocked during attachment, since on remote we want to be quiet when waiting for deactivation from the control side

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
	bool ShouldActivate(FPinballMagnetAttractionModesActivateParams& Params) const
	{
		if(!HasControl())
			return false;

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
			false
		);

		for(UMagnetDroneAttractionMode AttractionMode : AttractionComp.AttractionModes)
		{
			if(!AttractionMode.ShouldActivate(ShouldActivateParams))
				continue;

			Params.AttractionModeClass = AttractionMode.Class;
			return true;;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FPinballMagnetAttractionModesDeactivateParams& Params) const
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

		if(AttractionComp.GetAttractionMightBeStuckThisFrame())
		{
			Params.bFinished = AttachedComp.AttachedThisFrame();
			return true;
		}

		if(!AttractionComp.HasAttractionTarget())
		{
			Params.bFinished = false;
			return true;
		}

		if(AttractionComp.AttractionTarget.GetActor().IsA(APinballBoss))
		{
			if(AttractionComp.HasFinishedAttracting())
			{
				Params.bFinished = true;
				return true;
			}
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FPinballMagnetAttractionModesActivateParams Params)
	{
		AttractionComp.StartAttraction(this);

		ActiveAttractionMode = AttractionComp.GetAttractionMode(Params.AttractionModeClass);
		
		FMagnetDroneAttractionModePrepareAttractionParams SetupAttractionParams(
			Player,
			AttractionComp.GetAttractionTarget(),
		);

		ActiveAttractionMode.RunPrepareAttraction(SetupAttractionParams, AttractionComp.AttractionStartedParams.TimeUntilArrival, this);

		// The attraction mode might have modified our initial state
		SetupAttractionParams.ApplyOnPlayer(Player);

		// broadcast event that we started attracting, trigger cameras, effects, etc. 
		UMagnetDroneEventHandler::Trigger_AttractionStarted(Player, AttractionComp.AttractionStartedParams);

		Player.BlockCapabilities(MagnetDroneTags::MagnetDroneAim, this);
	
		UMovementStandardSettings::SetWalkableSlopeAngle(Player, 90, this);
		UDroneMovementSettings::SetRollMaxSpeed(Player, 15, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FPinballMagnetAttractionModesDeactivateParams Params)
	{
		ActiveAttractionMode.Reset();
		ActiveAttractionMode = nullptr;

		AttractionComp.FinishAttraction(Params.bFinished, this);

		if(Params.bFinished)
		{
        	AttachedComp.AttachToSurface(
				AttractionComp.AttractionTarget,
					AttractionComp.GetAttractionStartedParams(),
				this
			);
		}
		else
		{
			// broadcast that we canceled the attraction mid-Attraction
			UMagnetDroneEventHandler::Trigger_AttractionCanceled(Player);
		}

		Player.StopAllCameraShakes();
		Player.UnblockCapabilities(MagnetDroneTags::MagnetDroneAim, this);

		UMovementStandardSettings::ClearWalkableSlopeAngle(Player, this);
		UDroneMovementSettings::ClearRollMaxSpeed(Player, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		if(!MoveComp.PrepareMove(MoveData))
			return;

		if(HasControl())
		{
			CalculateDeltaMove(DeltaTime);
			MoveData.IgnoreSplineLockConstraint();
		}
		else
		{
			MoveData.ApplyCrumbSyncedAirMovement();
		}

		MoveComp.ApplyMove(MoveData);

#if !RELEASE
		ActiveAttractionMode.GetTemporalLog(false).Status(f"Running {Class.Name.PlainNameString}", ActiveAttractionMode.DebugColor);
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
		auto TickAttractionParams = FMagnetDroneAttractionModeTickAttractionParams(
			Player.ActorLocation,
			Player.ActorVelocity,
			Math::Max(ActiveDuration, KINDA_SMALL_NUMBER),
			Time::GameTimeSeconds,
		);

		float AttractionAlpha = AttractionComp.GetAttractionAlpha();
		FVector DesiredLocation = ActiveAttractionMode.RunTickAttraction(TickAttractionParams, DeltaTime, AttractionAlpha);
		AttractionComp.SetAttractionAlpha(AttractionAlpha);

		MoveData.AddDeltaFromMoveTo(DesiredLocation);
	}
}