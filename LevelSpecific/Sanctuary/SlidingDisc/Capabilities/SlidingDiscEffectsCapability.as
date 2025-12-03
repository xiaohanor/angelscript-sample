struct FSlidingDiscImpactData
{
	float ImpactStrength;
	UPhysicalMaterial AudioPhysMaterial;
}

class USlidingDiscEffectsCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Local;
	default TickGroup = EHazeTickGroup::Gameplay;

	ASlidingDisc SlidingDisc;
	UHazeMovementComponent MovementComponent;

	float AirborneDuration = 0.0;
	float GroundDuration = 0.0;
	float TimeSinceImpact = 0.0;

	bool bHasFakeGroundContact = false;
	bool bHadFakeGroundContact = false;

	FSlidingDiscImpactData StrongestGroundImpactData;
	FSlidingDiscImpactData StrongestSideImpactData;
	FRotator LeanRotation;
	FRotator OGDiscRot;

	bool bFirst = true;

	// acc on effect roll

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SlidingDisc = Cast<ASlidingDisc>(Owner);
		MovementComponent = UHazeMovementComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (SlidingDisc.GrindingOnHydra != nullptr)
			return false;
		if (!SlidingDisc.bIsSliding)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (SlidingDisc.GrindingOnHydra != nullptr)
			return true;
		if (!SlidingDisc.bIsSliding)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		bHasFakeGroundContact = MovementComponent.HasGroundContact();
		UpdateDiscLeaningRotation(DeltaTime);
		UpdateEffects(DeltaTime);
		bHadFakeGroundContact = bHasFakeGroundContact;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		if (bFirst)
		{
			bFirst = false;
			// SlidingDisc.AccPivotRot.SnapTo(SlidingDisc.BasePivot.ComponentQuat);
			OGDiscRot = SlidingDisc.ActorRotation;
			SlidingDisc.AccPivotRot.SnapTo(OGDiscRot.Quaternion());
		}
	}

	void UpdateDiscLeaningRotation(float DeltaTime)
	{
		FVector TurnForce;
		FQuat TargetRotation;
		FVector Forwards = MovementComponent.HorizontalVelocity.Size() >= KINDA_SMALL_NUMBER ? MovementComponent.Velocity : SlidingDisc.BasePivot.ForwardVector;

		if (bHasFakeGroundContact)
		{
			TurnForce = MovementComponent.WorldUp.CrossProduct(Forwards).GetSafeNormal() * Forwards.Size() * 0.5 * SlidingDisc.Lean;
			TargetRotation = FQuat::MakeFromZX(MovementComponent.GroundContact.Normal, Forwards);
		}
		else
		{
			FVector HorizontalVelocity = Forwards.VectorPlaneProject(MovementComponent.WorldUp);
			if(!HorizontalVelocity.IsNearlyZero())
				TargetRotation = FQuat::MakeFromXZ(Forwards, SlidingDisc.ActorUpVector);//SlidingDisc.AccPivotRot.Value.UpVector);
		}

		float Angle = 15.0;
		float TargetLean = Math::GetMappedRangeValueClamped(FVector2D(-1.0, 1.0), FVector2D(-Angle, Angle), SlidingDisc.Lean);
		float AccelerateDuration = 5.0;
		if (Math::Abs(TargetLean) > Math::Abs(SlidingDisc.AccRollRot.Value))
			AccelerateDuration = 1.0;
		SlidingDisc.AccRollRot.AccelerateTo(TargetLean, AccelerateDuration, DeltaTime);
		FRotator RollRot;
		RollRot.Roll = SlidingDisc.AccRollRot.Value;
		SlidingDisc.Pivot.SetRelativeRotation(RollRot);

		//Debug::DrawDebugLine(Game::Mio.ActorLocation, SlidingDisc.ActorLocation, FLinearColor::White, 3.0, 0.0, true);
		// Debug::DrawDebugCoordinateSystem(SlidingDisc.ActorLocation, SlidingDisc.ActorRotation, 500.0, 10.0, 0.0, true);

		SlidingDisc.AccPivotRot.AccelerateTo(TargetRotation, 1.0, DeltaTime);
		FQuat TotalWorldRot =  SlidingDisc.AccPivotRot.Value * LeanRotation.Quaternion();
		//Debug::DrawDebugCoordinateSystem(SlidingDisc.ActorLocation, TotalWorldRot.Rotator(), 500.0, 10.0, 0.0, true);
		SlidingDisc.BasePivot.SetWorldRotation(TotalWorldRot);

#if EDITOR
		TEMPORAL_LOG(SlidingDisc, "Sliding").Value("Speed", MovementComponent.Velocity.Size());
		TEMPORAL_LOG(SlidingDisc, "Sliding").Value("Fake HasGroundContact", bHasFakeGroundContact);
		TEMPORAL_LOG(SlidingDisc).Arrow("Turn Force", Owner.ActorLocation, Owner.ActorLocation + TurnForce, 3.0, 20.0, ColorDebug::Magenta);
		TEMPORAL_LOG(SlidingDisc).Arrow("Velocity", Owner.ActorLocation, Owner.ActorLocation + MovementComponent.Velocity, 3.0, 20.0, ColorDebug::Magenta);
		TEMPORAL_LOG(SlidingDisc).Arrow("TargetRotation Z", Owner.ActorLocation, Owner.ActorLocation + TargetRotation.UpVector * 300.0, 3.0, 20.0, ColorDebug::Blue);
		TEMPORAL_LOG(SlidingDisc).Arrow("TargetRotation X", Owner.ActorLocation, Owner.ActorLocation + TargetRotation.ForwardVector * 300.0, 3.0, 20.0, ColorDebug::Red);
		TEMPORAL_LOG(SlidingDisc).Arrow("TargetRotation Y", Owner.ActorLocation, Owner.ActorLocation + TargetRotation.RightVector * 300.0, 3.0, 20.0, ColorDebug::Green);
#endif
	}

	void UpdateEffects(float DeltaTime)
	{
		const float ActivateAudioTreshold = 0.1;

		float NewAirborneDuration = AirborneDuration + DeltaTime;
		if (AirborneDuration < ActivateAudioTreshold && NewAirborneDuration > ActivateAudioTreshold)
		{
			DevPrintStringCategory(n"SlidingDisc", "Disc", "Airborne", 3.0, ColorDebug::Eggblue);
			USlidingDiscEventHandler::Trigger_OnAirborne(SlidingDisc);
		}

		float NewGroundedDuration = GroundDuration + DeltaTime;
		if (GroundDuration < ActivateAudioTreshold && NewGroundedDuration > ActivateAudioTreshold)
		{
			FLinearColor LandColor = ColorDebug::Yellow;
			if (StrongestGroundImpactData.ImpactStrength > 100.0)
				LandColor = ColorDebug::Marigold;
			if (StrongestGroundImpactData.ImpactStrength > 500.0)
				LandColor = ColorDebug::Saffron;
			if (StrongestGroundImpactData.ImpactStrength > 1000.0)
				LandColor = ColorDebug::Vermillion;
			if (StrongestGroundImpactData.ImpactStrength > 1300.0)
				LandColor = ColorDebug::Carmine;
			DevPrintStringCategory(n"SlidingDisc", "Disc", "Landed " + StrongestGroundImpactData.ImpactStrength, 3.0, LandColor);

			USlidingDiscEventHandler::Trigger_OnLanded(SlidingDisc, FOnSlidingDiscLandedParams(StrongestGroundImpactData.ImpactStrength, StrongestGroundImpactData.AudioPhysMaterial));

			if(StrongestGroundImpactData.ImpactStrength > 1300)
				SlidingDisc.HandleCameraShakeAndForceFeedback();

			StrongestGroundImpactData.ImpactStrength = 0.0;


			
		}

		AirborneDuration += DeltaTime;
		GroundDuration += DeltaTime;

		if (bHadFakeGroundContact != bHasFakeGroundContact)
		{
			if (bHasFakeGroundContact)
			{ 
				float DotProduct = (-MovementComponent.GroundContact.Normal).DotProduct(MovementComponent.PreviousVelocity.GetSafeNormal());
				float ClampedDotProduct = Math::Clamp(DotProduct, 0.0, Math::Abs(DotProduct));
				float ImpactStrength = MovementComponent.PreviousVelocity.Size() * ClampedDotProduct;

				if (ImpactStrength > StrongestGroundImpactData.ImpactStrength)
				{
					StrongestGroundImpactData.ImpactStrength = ImpactStrength;
					StrongestGroundImpactData.AudioPhysMaterial = MovementComponent.GroundContact.GetAudioPhysMaterial();
					GroundDuration = 0.0;
				}
			}
			else
			{
				AirborneDuration = 0.0;
			}
		}

		if (bHasFakeGroundContact && !SlidingDisc.TrailVFX.IsActive())
			SlidingDisc.TrailVFX.Activate();
		else if (!bHasFakeGroundContact && SlidingDisc.TrailVFX.IsActive())
			SlidingDisc.TrailVFX.Deactivate();

		const float MagicRimDistance = 220.0;
		if (SlidingDiscDevToggles::DrawDisc.IsEnabled())
			Debug::DrawDebugSphere(SlidingDisc.ActorCenterLocation, MagicRimDistance, 12, ColorDebug::White, 1.0);
		for (auto Impact : MovementComponent.AllImpacts)
		{
			float ImpactDistance = Impact.ImpactPoint.Distance(SlidingDisc.ActorCenterLocation);
			bool bTooClose = ImpactDistance < MagicRimDistance;

			if (bTooClose)
				continue;

			float DotProduct = (-Impact.Normal).DotProduct(MovementComponent.PreviousVelocity.GetSafeNormal());
			float ClampedDotProduct = Math::Clamp(DotProduct, 0.0, Math::Abs(DotProduct));
			float ImpactStrength = MovementComponent.PreviousVelocity.Size() * ClampedDotProduct;

			if (StrongestSideImpactData.ImpactStrength < ImpactStrength)
			{
				TimeSinceImpact = 0.0;
				StrongestSideImpactData.ImpactStrength = ImpactStrength;
				StrongestSideImpactData.AudioPhysMaterial = Impact.GetAudioPhysMaterial();

				if (SlidingDiscDevToggles::DrawDisc.IsEnabled())
				{
					Debug::DrawDebugSphere(Impact.Location, 10.0, 12, ColorDebug::Ruby, 10.0, 2.0, true);
					Debug::DrawDebugArrow(Impact.Location, Impact.Location + Impact.Normal * ImpactStrength, 10.0, ColorDebug::Ruby, 5.0, 3.0);
				}
			}
		}

		float NewImpactDuration = TimeSinceImpact + DeltaTime;
		if (TimeSinceImpact < ActivateAudioTreshold && NewImpactDuration > ActivateAudioTreshold && StrongestSideImpactData.ImpactStrength > KINDA_SMALL_NUMBER)
		{
			DevPrintStringCategory(n"SlidingDisc", "Disc", "Side Collision " + StrongestGroundImpactData.ImpactStrength, 3.0, ColorDebug::Ruby);
			USlidingDiscEventHandler::Trigger_OnCollisionImpact(SlidingDisc, FOnSlidingDiscCollidedParams(StrongestSideImpactData.ImpactStrength, StrongestSideImpactData.AudioPhysMaterial));
			StrongestSideImpactData.ImpactStrength = 0.0;
			SlidingDisc.CameraShakeForceFeedbackComponent.ActivateCameraShakeAndForceFeedback();
		}
		TimeSinceImpact += DeltaTime;

		if (bHasFakeGroundContact)
		{
			FHazeFrameForceFeedback FrameForceFeedback;
			FrameForceFeedback.LeftMotor = 0.05;
			FrameForceFeedback.RightMotor = 0.05;
			ForceFeedback::PlayWorldForceFeedbackForFrame(FrameForceFeedback, SlidingDisc.ActorLocation);
			//Game::Mio.PlayCameraShake(SlidingDisc.LightCollisionCameraShake, this);
		}
	}
}

