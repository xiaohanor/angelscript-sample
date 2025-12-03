class UGravityWhipControlledDragCapability : UGravityWhipGrabCapability
{
	default CapabilityTags.Add(GravityWhipTags::GravityWhipControlledDrag);

	default GrabMode = EGravityWhipGrabMode::ControlledDrag;

	UPlayerAimingComponent AimComp;
	UCameraPointOfInterestClamped POI;
	UHazeCrumbSyncedVectorComponent SyncedControlInput;
	FVector2D AimValues;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();

		AimComp = UPlayerAimingComponent::Get(Owner);
		POI = Player.CreatePointOfInterestClamped();
		SyncedControlInput = UHazeCrumbSyncedVectorComponent::GetOrCreate(Owner, n"GravityWhipControlInput");
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(const FGravityWhipGrabActivationParams& ActivationParams)
	{
		Super::OnActivated(ActivationParams);

		if (Player.IsUsingGamepad())
		{
			POI.Clamps = FHazeCameraClampSettings(GravityWhip::Grab::CameraClampAngle);
			POI.FocusTarget.SetFocusToComponent(UserComp.GetPrimaryTarget());
			POI.Settings.InputTurnRateMultiplier = 1.0;
			POI.Settings.InputCounterForce = 8.0;
			POI.Settings.TurnTime = 0.75;
			POI.Apply(this, 1.5);
		}
		else
		{
			for (const auto& Grab : UserComp.Grabs)
			{
				if (Grab.ResponseComponent != nullptr && Grab.ResponseComponent.bMouseCursorTreatDragAsControl)
				{
					POI.Clamps = FHazeCameraClampSettings(GravityWhip::Grab::CameraClampAngle);
					POI.FocusTarget.SetFocusToComponent(UserComp.GetPrimaryTarget());
					POI.Settings.InputTurnRateMultiplier = 1.0;
					POI.Settings.InputCounterForce = 4.0;
					POI.Settings.TurnTime = 0.75;
					POI.Apply(this, 1.5);
					break;
				}
			}
		}

		if (UserComp.DragCameraSettings != nullptr)
			Player.ApplyCameraSettings(UserComp.DragCameraSettings, 1.0, this, SubPriority = 60);
	}
	
	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		TriggerRemainingHits();
		Player.ClearCameraSettingsByInstigator(this, 1.0);
		Player.ClearPointOfInterestByInstigator(this);

		for (auto& Grab : UserComp.Grabs)
		{
			for (auto Target : Grab.TargetComponents)
			{
				const FVector Impulse = UserComp.CalculateThrowImpulse(Target,
					Grab.ResponseComponent.OffsetDistance,
					Grab.ResponseComponent.ImpulseMultiplier);

				if (Grab.bHasTriggeredResponse)
					Grab.ResponseComponent.Release(UserComp, Target, Impulse);

				FGravityWhipReleaseData ReleaseData;
				ReleaseData.TargetComponent = Target;
				ReleaseData.Impulse = Impulse;
				ReleaseData.AudioData = Target.AudioData;

				UGravityWhipEventHandler::Trigger_TargetReleased(Player, ReleaseData);
			}

			if (Grab.ResponseComponent != nullptr)
				Grab.ResponseComponent.OnEndGrabSequence.Broadcast();
		}
		UserComp.Grabs.Empty();

		Super::OnDeactivated();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Super::TickActive(DeltaTime);

		auto AimingRay = UserComp.GetAimingRay();
		
		FVector AimLocation;
		UserComp.QueryWithRay(AimingRay.Origin, AimingRay.Direction, GravityWhip::Grab::AimTraceRange, AimLocation);
			
		if (HasControl())
		{
			FVector2D RawInput = Player.CameraInput;
			FVector InputVector = Player.ViewRotation.RotateVector(FVector(0.0, RawInput.X, RawInput.Y));
			
			for (const auto& Grab : UserComp.Grabs)
			{
				if (Grab.TargetComponents.Num() == 0 || !Grab.bHasTriggeredResponse)
					continue;

				float OffsetDistance = Grab.ResponseComponent.OffsetDistance;
				if (AimComp.HasAiming2DConstraint())
					OffsetDistance = Grab.ResponseComponent.OffsetDistance2D;
				float ForceMultiplier = Grab.ResponseComponent.ForceMultiplier;
				if (!Player.IsUsingGamepad())
					ForceMultiplier *= Grab.ResponseComponent.MouseCursorForceMultiplier;
				float DistributedForce = (GravityWhip::Grab::GrabForce * ForceMultiplier) / Grab.TargetComponents.Num();

				// NOTE: Bit of habsching to blend between control and drag; experimental stuff
				//  while we try to find a good way to whip constrained objects
				float ControlDragBlend = Grab.ResponseComponent.ControlDragBlend;
				if (Grab.ResponseComponent.bMouseCursorTreatDragAsControl && !Player.IsUsingGamepad())
					ControlDragBlend = 0.0;

				FVector DragAccumulatedLocation;
				FVector ControlAccumulatedLocation;
				FVector ControlAccumulatedForce;
				for (int i = 0; i < Grab.TargetComponents.Num(); ++i)
				{
					auto TargetComponent = Grab.TargetComponents[i];

					if (Grab.ResponseComponent.bUseDynamicOffsetDistance)
						OffsetDistance = (TargetComponent.WorldLocation - AimingRay.Origin).Size();

					FVector DesiredLocation = UserComp.GetDragOrigin(OffsetDistance);
					FVector ToDesiredLocation = (DesiredLocation - TargetComponent.WorldLocation);
					float Alpha = Math::Saturate(ToDesiredLocation.Size() / OffsetDistance);

					FVector DragForce = (ToDesiredLocation.GetSafeNormal() * DistributedForce * Alpha) * ControlDragBlend;
					FVector ControlForce = (InputVector * DistributedForce) * (1.0 - ControlDragBlend);

					TargetComponent.PendingForce += DragForce + ControlForce;
					
					DragAccumulatedLocation += DesiredLocation;
					ControlAccumulatedLocation += TargetComponent.WorldLocation;
					ControlAccumulatedForce += ControlForce;
				}

				Grab.ResponseComponent.DesiredLocation = (DragAccumulatedLocation / Grab.TargetComponents.Num()) + (ControlAccumulatedForce * DeltaTime);
				Grab.ResponseComponent.DesiredRotation = FRotator::MakeFromXZ(AimingRay.Direction, Player.MovementWorldUp);
				Grab.ResponseComponent.AimLocation = AimLocation;
			}

			SyncedControlInput.Value = InputVector;
		}
	
		// Animation data
		{
			FVector CenterPointDirection = (UserComp.GrabCenterLocation - AimingRay.Origin).GetSafeNormal();
			float X = UserComp.GetConstrainedAngle(AimingRay.Direction, CenterPointDirection, Player.ActorUpVector);
			float Y = UserComp.GetConstrainedAngle(AimingRay.Direction, CenterPointDirection, Player.ActorRightVector);
			UserComp.AnimationData.PullDirection.X = Math::Clamp(X / GravityWhip::Grab::MaxThrowAngle, -1.0, 1.0);
			UserComp.AnimationData.PullDirection.Y = -Math::Clamp(Y / GravityWhip::Grab::MaxThrowAngle, -1.0, 1.0);

			AimValues = Player.CalculatePlayerAimAnglesBuffered(AimValues);
			UserComp.AnimationData.VerticalAimSpace = (AimValues.Y / 90.0);
			UserComp.AnimationData.NumGrabs = UserComp.Grabs.Num();
			UserComp.WantedDragDirection = SyncedControlInput.Value;
		}

		// Update point of interest
		UGravityWhipTargetComponent PrimaryTarget = UserComp.GetPrimaryTarget();
		if (PrimaryTarget != nullptr)
		{
			FVector AimPoint = AimingRay.Origin + AimingRay.Direction * (UserComp.GrabCenterLocation - AimingRay.Origin).Size();
			FVector ViewPoint = Player.ViewLocation + Player.ViewRotation.ForwardVector * (UserComp.GrabCenterLocation - Player.ViewLocation).Size();

			POI.FocusTarget.SetFocusToComponent(PrimaryTarget);
			POI.FocusTarget.WorldOffset = (UserComp.GrabCenterLocation - PrimaryTarget.WorldLocation) + (ViewPoint - AimPoint).ConstrainToPlane(Player.ViewRotation.ForwardVector);
		}
	}
}