class UGravityWhipDragCapability : UGravityWhipGrabCapability
{
	default CapabilityTags.Add(GravityWhipTags::GravityWhipDrag);
	
	default GrabMode = EGravityWhipGrabMode::Drag;

	UPlayerAimingComponent AimComp;
	UCameraPointOfInterestClamped POI;
	FVector2D AimValues;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();

		AimComp = UPlayerAimingComponent::Get(Owner);
		POI = Player.CreatePointOfInterestClamped();
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(const FGravityWhipGrabActivationParams& ActivationParams)
	{
		Super::OnActivated(ActivationParams);

		POI.Clamps = FHazeCameraClampSettings(GravityWhip::Grab::CameraClampAngle);
		POI.FocusTarget.SetFocusToComponent(UserComp.GetPrimaryTarget());
		POI.Settings.TurnTime = 0.75;
		POI.Apply(this, 1.5);

		if (UserComp.DragCameraSettings != nullptr)
			Player.ApplyCameraSettings(UserComp.DragCameraSettings, 1.0, this, SubPriority = 61);
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
				FVector Impulse = FVector::ZeroVector;

				if (Grab.bHasTriggeredResponse)
				{
					Impulse = UserComp.CalculateThrowImpulse(Target,
						Grab.ResponseComponent.OffsetDistance,
						Grab.ResponseComponent.ImpulseMultiplier);

					Grab.ResponseComponent.Release(UserComp, Target, Impulse);
				}

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

		FVector WantedMoveDirection;
		int WantedMoveCount = 0;
		
		if (HasControl())
		{
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

				FVector AccumulatedLocation;
				for (int i = 0; i < Grab.TargetComponents.Num(); ++i)
				{
					auto TargetComponent = Grab.TargetComponents[i];

					if (Grab.ResponseComponent.bUseDynamicOffsetDistance)
						OffsetDistance = (TargetComponent.WorldLocation - AimingRay.Origin).Size();

					FVector DesiredLocation = UserComp.GetDragOrigin(OffsetDistance);
					FVector ToDesiredLocation = (DesiredLocation - TargetComponent.WorldLocation);
					float Alpha = Math::Saturate(ToDesiredLocation.Size() / OffsetDistance);

					if (ToDesiredLocation.Size() > 10.0)
					{
						WantedMoveDirection += ToDesiredLocation.GetSafeNormal();
						WantedMoveCount += 1;
					}

					TargetComponent.PendingForce += (ToDesiredLocation.GetSafeNormal() * DistributedForce * Alpha);
					AccumulatedLocation += DesiredLocation;
				}
				
				Grab.ResponseComponent.DesiredLocation = (AccumulatedLocation / Grab.TargetComponents.Num());
				Grab.ResponseComponent.DesiredRotation = FRotator::MakeFromXZ(AimingRay.Direction, Player.MovementWorldUp);
				Grab.ResponseComponent.AimLocation = AimLocation;
			}
		}
		else
		{
			WantedMoveCount = UserComp.Grabs.Num();
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

			if (WantedMoveCount != 0)
			{
				UserComp.WantedDragDirection = WantedMoveDirection / float(WantedMoveCount);
			}
			else
			{
				UserComp.WantedDragDirection = FVector::ZeroVector;
			}
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