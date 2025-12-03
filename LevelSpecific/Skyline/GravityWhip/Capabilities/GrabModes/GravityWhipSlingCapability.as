class UGravityWhipSlingCapability : UGravityWhipGrabCapability
{
	default bForceFeedbackBasedOnGrabMovement = false;
	default CapabilityTags.Add(GravityWhipTags::GravityWhipSling);

	default GrabMode = EGravityWhipGrabMode::Sling;
	default DebugCategory = GravityWhipTags::GravityWhip;

	UPlayerAimingComponent AimComp;
	float ThrowStartTime = 0.0;

	FAimingResult AimResult;
	bool bTurnedIntoGloryKill = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		
		AimComp = UPlayerAimingComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		// If we release before we've attached to any grabs, cancel
		if (!HasAttachedToGrab() && !IsActioning(ActionNames::PrimaryLevelAbility))
		{
			// Don't deactivate when releasing the button until we've either grabbed or hit
			if (ActiveDuration >= GravityWhip::Hit::HitDuration || bHasActivatedGrab)
				return true;
		}

		if (ActiveDuration < GravityWhip::Grab::ForceSlingDuration)
			return false;

		if (UserComp.bIsSlingThrowing && Time::GetGameTimeSince(ThrowStartTime) > GravityWhip::Grab::SlingThrowDelay)
			return true;

		if (!UserComp.IsGrabbingAny())
			return true;

		if (UserComp.GetPrimaryGrabMode() != GrabMode)
			return true;
		
		if (Player.IsPlayerDead())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(const FGravityWhipGrabActivationParams& ActivationParams)
	{
		Super::OnActivated(ActivationParams);
		bTurnedIntoGloryKill = false;

		if (UserComp.SlingCameraSettings != nullptr)
			Player.ApplyCameraSettings(UserComp.SlingCameraSettings, 1.0, this, SubPriority = 62);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if (!bKeepGrabAfterDeactivate)
			TriggerRemainingHits();
		Player.ClearCameraSettingsByInstigator(this, 1.0);

		if (AimComp.IsAiming(UserComp))
			AimResult = AimComp.GetAimingTarget(UserComp);
		
		FVector AimLocation;
		FHitResult HitResult = UserComp.QueryWithRay(AimResult.AimOrigin, AimResult.AimDirection, GravityWhip::Grab::AimTraceRange, AimLocation);

		if (!bKeepGrabAfterDeactivate)
		{
			for (int GrabIndex = 0, GrabCount = UserComp.Grabs.Num(); GrabIndex < GrabCount; ++GrabIndex)
			{
				auto& Grab = UserComp.Grabs[GrabIndex];
				if (!IsValid(Grab.ResponseComponent))
					continue;

				if (Grab.bHasTriggeredResponse)
				{
					float ImpulseMultiplier = Grab.ResponseComponent.ImpulseMultiplier;
					float SpreadRadius = Math::RandRange(Grab.ResponseComponent.MinSpreadRadius, Grab.ResponseComponent.MaxSpreadRadius);

					for (int i = 0; i < Grab.TargetComponents.Num(); ++i)
					{
						auto TargetComponent = Grab.TargetComponents[i];

						FVector ThrowDirection = (AimLocation - TargetComponent.WorldLocation).GetSafeNormal();
						if (UserComp.Grabs.Num() > 1)
						{
							float OffsetAngle = Math::RadiansToDegrees((PI * 2.0) / UserComp.Grabs.Num()) * GrabIndex;
							FVector OffsetDirection = Player.ViewRotation.UpVector.RotateAngleAxis(OffsetAngle, Player.ViewRotation.ForwardVector);
							FVector OffsetLocation = AimLocation + (OffsetDirection * SpreadRadius);

							ThrowDirection = (OffsetLocation - TargetComponent.WorldLocation).GetSafeNormal();
						}

						FVector ThrowImpulse = (ThrowDirection * GravityWhip::Grab::ThrowImpulse * ImpulseMultiplier);

						if (Grab.bHasTriggeredResponse)
							Grab.ResponseComponent.Throw(UserComp, TargetComponent, HitResult, ThrowImpulse);

						FGravityWhipReleaseData ReleaseData;
						ReleaseData.TargetComponent = TargetComponent;
						ReleaseData.Impulse = ThrowImpulse;
						ReleaseData.AudioData = TargetComponent.AudioData;

						UGravityWhipEventHandler::Trigger_TargetThrown(Player, ReleaseData);

						Player.PlayForceFeedback(UserComp.SlingThrowForceFeedback, false, false, this);
					}
				}

				if (Grab.ResponseComponent != nullptr)
					Grab.ResponseComponent.OnEndGrabSequence.Broadcast();
			}

			UserComp.Grabs.Empty();
		}

		UserComp.bIsSlingThrowing = false;
		UserComp.AnimationData.bIsThrowing = false;

		Super::OnDeactivated();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Super::TickActive(DeltaTime);

		if (AimComp.IsAiming(UserComp))
			AimResult = AimComp.GetAimingTarget(UserComp);

		if (HasControl())
		{
			if (!IsActioning(ActionNames::PrimaryLevelAbility)
				&& ActiveDuration >= GravityWhip::Grab::ForceSlingDuration
				&& !UserComp.bIsSlingThrowing && !bTurnedIntoGloryKill)
			{
				bool bPerformedGloryKill = false;
				if (CanGloryKill(bForHit = false) && AimResult.AutoAimTarget == nullptr)
				{
					FHazeTraceSettings Trace;
					Trace.TraceWithChannel(ECollisionChannel::WorldGeometry);
					Trace.UseLine();

					FHitResult AimTrace = Trace.QueryTraceSingle(
						AimResult.AimOrigin, AimResult.AimOrigin + AimResult.AimDirection * 2000,
					);

					if (AimTrace.bBlockingHit)
					{
						// If we're targeting a floor, try a floor glory kill
						if (AimTrace.ImpactNormal.GetAngleDegreesTo(MoveComp.WorldUp) < 40.0)
						{
							ULocomotionFeatureGravityWhip Feature = Player.Mesh.GetFeatureByClass(ULocomotionFeatureGravityWhip);
							FGravityWhipActiveGloryKill GloryKill;
							int GloryKillIndex = Feature.AnimData.SelectRandomGloryKill(EGravityWhipGloryKillCondition::ThrowAtFloor, AimTrace.ImpactPoint.Distance(Player.ActorLocation));
							if (GloryKillIndex != -1 && GloryKillIndex == UserComp.LastGloryKillIndex)
								GloryKillIndex = Feature.AnimData.SelectRandomGloryKill(EGravityWhipGloryKillCondition::ThrowAtFloor, AimTrace.ImpactPoint.Distance(Player.ActorLocation), UserComp.LastGloryKillIndex, true);

							if (GloryKillIndex != -1)
							{
								GloryKill.Sequence = Feature.AnimData.GloryKills[GloryKillIndex];
								GloryKill.bMoveEnforcerToPoint = true;
								GloryKill.EnforcerTargetPoint = AimTrace.ImpactPoint;
								UserComp.LastGloryKillIndex = GloryKillIndex;

								CrumbTriggerThrowGloryKill(GloryKill);
								bPerformedGloryKill = true;
							}
						}
						// If we're targeting a wall, try a wall glory kill
						else if (AimTrace.ImpactNormal.DotProduct(MoveComp.WorldUp) < 0.1)
						{
							ULocomotionFeatureGravityWhip Feature = Player.Mesh.GetFeatureByClass(ULocomotionFeatureGravityWhip);
							FGravityWhipActiveGloryKill GloryKill;
							int GloryKillIndex = Feature.AnimData.SelectRandomGloryKill(EGravityWhipGloryKillCondition::ThrowAtWall, AimTrace.ImpactPoint.Distance(Player.ActorLocation));
							if (GloryKillIndex != -1 && GloryKillIndex == UserComp.LastGloryKillIndex)
								GloryKillIndex = Feature.AnimData.SelectRandomGloryKill(EGravityWhipGloryKillCondition::ThrowAtWall, AimTrace.ImpactPoint.Distance(Player.ActorLocation), UserComp.LastGloryKillIndex, true);

							if (GloryKillIndex != -1)
							{
								GloryKill.Sequence = Feature.AnimData.GloryKills[GloryKillIndex];
								GloryKill.bMoveEnforcerToPoint = true;
								GloryKill.EnforcerTargetPoint = AimTrace.ImpactPoint;
								UserComp.LastGloryKillIndex = GloryKillIndex;

								CrumbTriggerThrowGloryKill(GloryKill);
								bPerformedGloryKill = true;
							}
						}
					}
				}

				if (!bPerformedGloryKill)
					CrumbStartThrowing();
			}
		}
	}

	UFUNCTION(CrumbFunction)
	void CrumbTriggerThrowGloryKill(FGravityWhipActiveGloryKill GloryKill)
	{
		bKeepGrabAfterDeactivate = true;
		bTurnedIntoGloryKill = true;

		UserComp.TargetData.GrabMode = EGravityWhipGrabMode::GloryKill;
		UserComp.ActiveGloryKill = GloryKill;
	}

	UFUNCTION(CrumbFunction)
	void CrumbStartThrowing()
	{
		UserComp.bIsSlingThrowing = true;
		UserComp.AnimationData.bIsThrowing = true;
		ThrowStartTime = Time::GameTimeSeconds;
		TriggerReleaseAnimation();

		auto PrimaryTarget = UserComp.GetPrimaryTarget();
		
		if (PrimaryTarget != nullptr) // when we die our target is nullptr
		{
			FGravityWhipReleaseData ReleaseData;
			ReleaseData.TargetComponent = PrimaryTarget;	
			ReleaseData.AudioData = PrimaryTarget.AudioData;
			UGravityWhipEventHandler::Trigger_TargetPreThrown(Player, ReleaseData);
		}
	}
}