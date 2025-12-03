struct FMagnetDroneAttractionPreviewActivateParams
{
	FMagnetDroneTargetData AimData;
	TSubclassOf<UMagnetDroneAttractionMode> AttractionModeClass;
};

class UMagnetDroneAttractionPreviewCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Local;

	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(PrisonTags::Prison);
	default CapabilityTags.Add(PrisonTags::Drones);
	default CapabilityTags.Add(MagnetDroneTags::MagnetDrone);
	default CapabilityTags.Add(MagnetDroneTags::MagnetDroneAttraction);
	default CapabilityTags.Add(MagnetDroneTags::BlockedWhileAttraction);

	default BlockExclusionTags.Add(MagnetDroneTags::AttachToBoatBlockExclusionTag);

	default TickGroup = MagnetDrone::StartAttractTickGroup;
	default TickGroupOrder = MagnetDrone::StartAttractTickGroupOrder - 1;

	UMagnetDroneAttractAimComponent AttractAimComp;
	UMagnetDroneAttractionComponent AttractionComp;
	UMagnetDroneAttachedComponent AttachedComp;

	FHazeAcceleratedVector AccStartVelocity;
	FHazeAcceleratedVector AccEndVelocity;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		AttractAimComp = UMagnetDroneAttractAimComponent::Get(Player);
		AttractionComp = UMagnetDroneAttractionComponent::Get(Player);
		AttachedComp = UMagnetDroneAttachedComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FMagnetDroneAttractionPreviewActivateParams& Params) const
	{
		FMagnetDroneTargetData AimData;
		EMagnetDroneStartAttractionInstigator Instigator;
		if(!TryGetAimData(AimData, Instigator))
			return false;

		UMagnetDroneAttractionMode AttractionMode = SelectAttractionMode(AimData, Instigator);
		if(AttractionMode == nullptr)
			return false;

		Params.AimData = AimData;
		Params.AttractionModeClass = AttractionMode.Class;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		FMagnetDroneTargetData AimData;
		EMagnetDroneStartAttractionInstigator Instigator;
		if(!TryGetAimData(AimData, Instigator))
			return true;

		UMagnetDroneAttractionMode AttractionMode = SelectAttractionMode(AimData, Instigator);
		if(AttractionMode == nullptr)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FMagnetDroneAttractionPreviewActivateParams Params)
	{
		UMagnetDroneAttractionMode AttractionMode = AttractionComp.GetAttractionMode(Params.AttractionModeClass);
		if(AttractionMode == nullptr)
			return;

		AccStartVelocity.SnapTo(Player.ActorVelocity);
		const FVector StartVelocity = AccStartVelocity.Value * AttractionComp.Settings.PreviewStartVelocityMultiplier;

		FVector EndLocation;
		FVector EndVelocity;
		const FHazeRuntimeSpline PreviewSpline = SimulateAttraction(Params.AimData, AttractionMode, StartVelocity, EndLocation, EndVelocity);

		AccEndVelocity.SnapTo(EndVelocity);

		FMagnetDronePreviewAttractionPathEventData EventData = CreateAttractionPathEventData(PreviewSpline, Player.ActorLocation, AccStartVelocity.Value, EndLocation, AccEndVelocity.Value);

		UMagnetDroneEventHandler::Trigger_StartPreviewAttractionPath(Player, EventData);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		UMagnetDroneEventHandler::Trigger_StopPreviewAttractionPath(Player);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FMagnetDroneTargetData AimData;
		EMagnetDroneStartAttractionInstigator Instigator;
		if(!TryGetAimData(AimData, Instigator))
			return;

		UMagnetDroneAttractionMode AttractionMode = SelectAttractionMode(AimData, Instigator);
		if(AttractionMode == nullptr)
			return;

		AccStartVelocity.AccelerateTo(Player.ActorVelocity, AttractionComp.Settings.PreviewStartVelocityAccelerateDuration, DeltaTime);
		const FVector StartVelocity = AccStartVelocity.Value * AttractionComp.Settings.PreviewStartVelocityMultiplier;

		FVector EndLocation;
		FVector EndVelocity;
		const FHazeRuntimeSpline PreviewSpline = SimulateAttraction(AimData, AttractionMode, StartVelocity, EndLocation, EndVelocity);

		// Smooth out the start and end tangents
		AccEndVelocity.AccelerateTo(EndVelocity, 1, DeltaTime);

		FMagnetDronePreviewAttractionPathEventData EventData = CreateAttractionPathEventData(PreviewSpline, Player.ActorLocation, FVector::ZeroVector, EndLocation, AccStartVelocity.Value);

		UMagnetDroneEventHandler::Trigger_TickPreviewAttractionPath(Player, EventData);

#if !RELEASE
		FDebugDrawRuntimeSplineParams DrawParams;
		DrawParams.Width = 5;
		DrawParams.LineType = EDebugDrawRuntimeSplineLineType::Lines;
		DrawParams.bDrawStartPoint = false;
		DrawParams.bDrawSplinePoints = false;
		DrawParams.LineColor = AttractionMode.DebugColor;
		DrawParams.bDrawMovingPoint = true;

		// if(MagnetDrone::AttractionModes::bDebugDrawPreviewSpline)
		// 	CurrentPreviewSpline.DrawDebugSpline(DrawParams);

		// if(MagnetDrone::AttractionModes::bDebugDrawInterpolatedSpline)
		// 	InterpolatedPreviewSpline.DrawDebugSpline(DrawParams);

		AttractionComp.GetTemporalLog().Page("Preview")
			.Section("Final", -888)
			.RuntimeSpline("CurrentPreviewSpline", PreviewSpline)
		;
#endif
	}

	UMagnetDroneAttractionMode SelectAttractionMode(FMagnetDroneTargetData AimData, EMagnetDroneStartAttractionInstigator Instigator) const
	{
		bool bIsAttached = AttachedComp.IsAttached();

		if(!HasControl())
		{
			auto PinballPredictionComp = UPinballMagnetDronePredictionComponent::Get(Player);
			if(PinballPredictionComp != nullptr)
			{
				// We are predicting in pinball!
				FPinballPredictionSyncedData SyncedData = PinballPredictionComp.GetLatestSyncedData();
				bIsAttached = SyncedData.AttachedData.AttachedData.CanAttach();
			}
		}

		auto ShouldActivateParams = FMagnetDroneAttractionModeShouldActivateParams(
			Player.ActorLocation,
			Player.ActorVelocity,
			bIsAttached,
			AimData,
			Instigator,
			true
		);

		for(UMagnetDroneAttractionMode AttractionMode : AttractionComp.AttractionModes)
		{
			if(!AttractionMode.ShouldActivate(ShouldActivateParams))
				continue;

			return AttractionMode;
		}

		return nullptr;
	}

	bool TryGetAimData(FMagnetDroneTargetData&out OutAimData, EMagnetDroneStartAttractionInstigator&out OutInstigator) const
	{
		auto AttractJumpComp = UMagnetDroneAttractJumpComponent::Get(Player);
		if(AttractJumpComp != nullptr && AttractJumpComp.JumpAimData.IsValidTarget())
		{
			OutAimData = AttractJumpComp.JumpAimData;
			OutInstigator = EMagnetDroneStartAttractionInstigator::Jump;
			return true;
		}

		if(AttractAimComp.AimData.IsValidTarget())
		{
			OutAimData = AttractAimComp.AimData;
			OutInstigator = EMagnetDroneStartAttractionInstigator::Aim;
			return true;
		}

		return false;
	}
	
	FHazeRuntimeSpline SimulateAttraction(FMagnetDroneTargetData AimData, UMagnetDroneAttractionMode AttractionMode, FVector StartVelocity, FVector&out OutEndLocation, FVector&out OutEndVelocity) const
	{
#if !RELEASE
		FTemporalLog AttractionModePageLog = AttractionComp.GetTemporalLog().Page("Attraction Mode");
		AttractionModePageLog.Status(f"Previewing {AttractionMode.Class.Name.PlainNameString}", AttractionMode.DebugColor);
		FTemporalLog PreviewPageLog = AttractionComp.GetTemporalLog().Page("Preview");
		AttractionMode.DebugPreviewIteration = 0;
#endif

		FVector InitialLocation = Player.ActorLocation;
		FVector InitialVelocity = StartVelocity;

		FMagnetDroneAttractionModePrepareAttractionParams SetupAttractionParams(
			AttractionComp.Settings,
			AimData,
			InitialLocation,
			StartVelocity,
			Player.MovementWorldUp,
			Player.ViewRotation,
			Time::GameTimeSeconds,
		);

		float TimeUntilArrival;
		AttractionMode.RunPrepareAttraction(SetupAttractionParams, TimeUntilArrival, this);

		// The attraction mode might have modified our initial state
		SetupAttractionParams.ApplyOnPreview(
			InitialLocation,
			InitialVelocity,
		);

		const float MAX_DURATION = 10;
		const float TIME_STEP = 0.033;
		float Time = 0;

		FHazeRuntimeSpline PreviewSpline;
		PreviewSpline.AddPoint(InitialLocation);
		PreviewSpline.CustomEnterTangentPoint = AttractionMode.GetStartLocation() + AttractionMode.GetStartTangent();
		PreviewSpline.CustomExitTangentPoint = AttractionMode.GetEndLocation() + AttractionMode.GetEndTangent();

#if !RELEASE
		PreviewPageLog
			.Section("Prepare", -999)
			.Sphere("Start Location", AttractionMode.GetStartLocation(), MagnetDrone::Radius)
			.DirectionalArrow("Start Tangent", AttractionMode.GetStartLocation(), AttractionMode.GetStartTangent())
			.Sphere("End Location", AttractionMode.GetEndLocation(), MagnetDrone::Radius)
			.Plane("End Tangent", AttractionMode.GetEndLocation(), AttractionMode.GetEndTangent())
		;
#endif

		FVector CurrentLocation = InitialLocation;
		FVector CurrentVelocity = InitialVelocity;
		float AttractionAlpha = 0;

		while(Time < MAX_DURATION)
		{
#if !RELEASE
			AttractionMode.DebugPreviewIteration = PreviewSpline.Points.Num();
#endif

			float TimeStep = Math::Min(TIME_STEP, MAX_DURATION - Time);
			Time += TimeStep;
			
			auto TickAttractionParams = FMagnetDroneAttractionModeTickAttractionParams(
				CurrentLocation,
				CurrentVelocity,
				Time,
				SetupAttractionParams.InitialGameTime + Time,
			);

			FVector PreviousLocation = CurrentLocation;
			CurrentLocation = AttractionMode.RunTickAttraction(TickAttractionParams, TimeStep, AttractionAlpha);
			CurrentVelocity = (CurrentLocation - PreviousLocation) / TimeStep;

			PreviewSpline.AddPoint(CurrentLocation);

#if !RELEASE
			FTemporalLog TemporalLog = AttractionMode.GetTemporalLog();
			AttractionMode.LogToTemporalLog(
				TemporalLog,
				FMagnetDroneAttractionModeLogParams(
					AttractionAlpha,
					Time,
					CurrentLocation
				)
			);
#endif

			if(AttractionAlpha >= 1.0)
				break;

			Time += TIME_STEP;
		}

		AttractionMode.Reset();

		OutEndLocation = CurrentLocation;
		OutEndVelocity = CurrentVelocity;

		return PreviewSpline;
	}

	private FMagnetDronePreviewAttractionPathEventData CreateAttractionPathEventData(FHazeRuntimeSpline PreviewSpline, FVector StartLocation, FVector StartVelocity, FVector EndLocation, FVector EndVelocity) const
	{
		FMagnetDronePreviewAttractionPathEventData EventData;
		EventData.StartLocation = StartLocation;
		EventData.StartTangent = StartVelocity * 0.3;

		EventData.EndLocation = EndLocation;

		if(StartVelocity.IsNearlyZero())
		{
			EventData.EndTangent = EndVelocity.GetClampedToMaxSize(600);
		}
		else
		{
			EventData.EndTangent = StartVelocity * 0.2;
			EventData.EndTangent -= EndVelocity.GetClampedToMaxSize(600);
			EventData.EndTangent *= -1.0;
		}

		EventData.ImmediateSpline = PreviewSpline;

		check(!EventData.StartLocation.IsZero());
		check(!EventData.EndLocation.IsZero());
		check(!EventData.ImmediateSpline.Points.IsEmpty());

		return EventData;
	}
};