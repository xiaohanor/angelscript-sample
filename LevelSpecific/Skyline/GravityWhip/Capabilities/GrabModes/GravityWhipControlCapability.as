class UGravityWhipControlCapability : UGravityWhipGrabCapability
{
	default CapabilityTags.Add(GravityWhipTags::GravityWhipControl);

	default GrabMode = EGravityWhipGrabMode::Control;

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

		POI.Clamps = FHazeCameraClampSettings(GravityWhip::Grab::CameraClampAngle);
		POI.FocusTarget.SetFocusToComponent(UserComp.GetPrimaryTarget());
		POI.Settings.InputTurnRateMultiplier = 1.0;
		POI.Settings.InputCounterForce = 4.0;
		POI.Settings.TurnTime = 0.75;
		POI.Apply(this, 1.5);

		Player.BlockCapabilities(CameraTags::CameraControl, this);
	}
	
	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		TriggerRemainingHits();
		Player.UnblockCapabilities(CameraTags::CameraControl, this);
		Player.ClearPointOfInterestByInstigator(this);

		for (auto& Grab : UserComp.Grabs)
		{
			for (auto Target : Grab.TargetComponents)
			{
				if (Grab.bHasTriggeredResponse)
					Grab.ResponseComponent.Release(UserComp, Target, FVector::ZeroVector);

				FGravityWhipReleaseData ReleaseData;
				ReleaseData.TargetComponent = Target;
				ReleaseData.Impulse = FVector::ZeroVector;
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
			FVector2D RawInput = GetAttributeVector2D(AttributeVectorNames::RightStickRaw);
			FVector InputVector = Player.ViewRotation.RotateVector(FVector(0.0, RawInput.X, RawInput.Y));
			
			for (int i = 0; i < UserComp.Grabs.Num(); ++i)
			{
				const auto& Grab = UserComp.Grabs[i];
				if (Grab.TargetComponents.Num() == 0 || !Grab.bHasTriggeredResponse)
					continue;

				float ForceMultiplier = Grab.ResponseComponent.ForceMultiplier;
				if (!Player.IsUsingGamepad())
					ForceMultiplier *= Grab.ResponseComponent.MouseCursorForceMultiplier;
				float DistributedForce = (GravityWhip::Grab::GrabForce * ForceMultiplier) / Grab.TargetComponents.Num();

				FVector AccumulatedLocation = FVector::ZeroVector;
				FVector AccumulatedForce = FVector::ZeroVector;
				for (int j = 0; j < Grab.TargetComponents.Num(); ++j)
				{
					auto TargetComponent = Grab.TargetComponents[j];

					FVector Force = InputVector * DistributedForce;
					
					TargetComponent.PendingForce += Force;
					AccumulatedLocation += TargetComponent.WorldLocation;
					AccumulatedForce += Force;
				}

				Grab.ResponseComponent.DesiredLocation = (AccumulatedLocation + (AccumulatedForce * DeltaTime)) / Grab.TargetComponents.Num();
				Grab.ResponseComponent.DesiredRotation = Grab.Actor.ActorRotation;
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
		{
			auto PrimaryTarget = UserComp.GetPrimaryTarget();
			if (PrimaryTarget != nullptr)
			{
				FVector AimPoint = AimingRay.Origin + AimingRay.Direction * (UserComp.GrabCenterLocation - AimingRay.Origin).Size();
				FVector ViewPoint = Player.ViewLocation + Player.ViewRotation.ForwardVector * (UserComp.GrabCenterLocation - Player.ViewLocation).Size();

				POI.FocusTarget.SetFocusToComponent(PrimaryTarget);
				POI.FocusTarget.WorldOffset = (UserComp.GrabCenterLocation - PrimaryTarget.WorldLocation) + (ViewPoint - AimPoint).ConstrainToPlane(Player.ViewRotation.ForwardVector);
			}
		}
	}
}