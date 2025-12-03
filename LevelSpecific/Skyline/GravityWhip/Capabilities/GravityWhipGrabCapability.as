struct FGravityWhipGrabActivationParams
{
	FGravityWhipTargetData TargetData;
}

UCLASS(Abstract)
class UGravityWhipGrabCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(GravityWhipTags::GravityWhip);
	default CapabilityTags.Add(GravityWhipTags::GravityWhipGrab);
	default CapabilityTags.Add(GravityWhipTags::GravityWhipGameplay);

	default CapabilityTags.Add(BlockedWhileIn::Crouch);
	default CapabilityTags.Add(BlockedWhileIn::Swimming);
	default CapabilityTags.Add(BlockedWhileIn::Grapple);
	default CapabilityTags.Add(BlockedWhileIn::GrappleEnter);
	default CapabilityTags.Add(BlockedWhileIn::Ladder);
	default CapabilityTags.Add(BlockedWhileIn::Swing);
	default CapabilityTags.Add(BlockedWhileIn::GravityWell);
	default CapabilityTags.Add(BlockedWhileIn::PoleClimb);
	default CapabilityTags.Add(BlockedWhileIn::Perch);
	default CapabilityTags.Add(BlockedWhileIn::PerchSpline);
	default CapabilityTags.Add(BlockedWhileIn::LedgeMantle);

	default DebugCategory = GravityWhipTags::GravityWhip;

	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 105;

	bool bAllowTurnIntoHit = true;

	EGravityWhipGrabMode GrabMode = EGravityWhipGrabMode::Drag;

	UGravityWhipUserComponent UserComp;
	UPlayerMovementComponent MoveComp;
	bool bPlayedReleaseAnimation = false;
	bool bPlayedAttachAnimation = false;
	bool bForceFeedbackBasedOnGrabMovement = true;

	bool bHasActivatedGrab = false;
	bool bHasTurnedIntoHit = false;
	bool bHasTriggeredHitEvent = false;

	bool bButtonMashStarted = false;
	bool bButtonMashCompleted = false;

	bool bKeepGrabAfterDeactivate = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		UserComp = UGravityWhipUserComponent::Get(Owner);
		MoveComp = UPlayerMovementComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FGravityWhipGrabActivationParams& ActivationParams) const
	{
		float TimeSinceRelease = Time::GetGameTimeSince(UserComp.ReleaseTimestamp);
		if (TimeSinceRelease < GravityWhip::Grab::ReleaseDuration)
			return false;

		if (!WasActionStartedDuringTime(ActionNames::PrimaryLevelAbility, GravityWhip::Grab::ReleaseDuration) && !UserComp.IsWhipPressBuffered())
			return false;

		if (!UserComp.IsTargetingAny())
			return false;

		if (UserComp.GetPrimaryGrabMode() != GrabMode)
			return false;

		ActivationParams.TargetData = UserComp.TargetData;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!IsActioning(ActionNames::PrimaryLevelAbility) || bHasTurnedIntoHit)
		{
			// Don't deactivate when releasing the button until we've either grabbed or hit
			if (ActiveDuration >= GravityWhip::Hit::HitDuration || bHasActivatedGrab)
				return true;
		}

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
		Player.Mesh.ResetSubAnimationInstance(EHazeAnimInstEvalType::Override);

		UserComp.Grab(ActivationParams.TargetData.TargetComponents);
		UserComp.bReleaseStrafeImmediately = false;
		UserComp.GrabTimestamp = Time::GameTimeSeconds;
		UserComp.AnimationData.LastGrabFrame = Time::FrameNumber;
		UserComp.AnimationData.LastGrabMode = GrabMode;
		UGravityWhipEventHandler::Trigger_WhipLaunched(Player);

		UserComp.AnimationData.bHasTurnedIntoWhipHit = false;
		UserComp.bWhipGrabHadTarget = true;
		UserComp.ConsumeBufferedWhipPress();

//		Player.BlockCapabilities(PlayerMovementTags::RollDash, this);
//		Player.BlockCapabilities(PlayerMovementTags::AirJump, this);

		bPlayedReleaseAnimation = false;
		bPlayedAttachAnimation = false;

		bButtonMashCompleted = false;
		bButtonMashStarted = false;
		bKeepGrabAfterDeactivate = false;

		bHasActivatedGrab = false;
		bHasTurnedIntoHit = false;
		bHasTriggeredHitEvent = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if (!bKeepGrabAfterDeactivate)
		{
			UserComp.ReleaseAll();
			UserComp.ReleaseTimestamp = Time::GameTimeSeconds;
			if (bPlayedAttachAnimation)
				TriggerReleaseAnimation();
			UGravityWhipEventHandler::Trigger_WhipStartRetracting(Player);
		}

//		Player.UnblockCapabilities(PlayerMovementTags::RollDash, this);
//		Player.UnblockCapabilities(PlayerMovementTags::AirJump, this);

		if (bButtonMashStarted)
			Player.StopButtonMash(this);
	}

	void TriggerReleaseAnimation()
	{
		if (bPlayedReleaseAnimation)
			return;
		bPlayedReleaseAnimation = true;

		UserComp.AnimationData.LastReleaseFrame = Time::FrameNumber;
	}

	void TriggerAttachAnimation()
	{
		if (bPlayedAttachAnimation)
			return;
		bPlayedAttachAnimation = true;

		UserComp.AnimationData.LastGrabAttachFrame = Time::FrameNumber;
	}

	bool HasAttachedToGrab() const
	{
		for (const auto& Grab : UserComp.Grabs)
		{
			if (Grab.bHasTriggeredResponse)
				return true;
			if (Grab.ResponseComponent.bGrabAttachImmediately)
				return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (HasControl())
		{
			if (!bHasActivatedGrab && !bHasTurnedIntoHit && bAllowTurnIntoHit)
			{
				if (!IsActioning(ActionNames::PrimaryLevelAbility))
				{
					if (CanGloryKill(bForHit = true))
					{
						auto Feature = Player.Mesh.GetFeatureByClass(ULocomotionFeatureGravityWhip);

						FGravityWhipActiveGloryKill GloryKill;
						int GloryKillIndex = Feature.AnimData.SelectRandomGloryKill(EGravityWhipGloryKillCondition::Hit, -1);
						if (GloryKillIndex != -1 && GloryKillIndex == UserComp.LastGloryKillIndex)
							GloryKillIndex = Feature.AnimData.SelectRandomGloryKill(EGravityWhipGloryKillCondition::Hit, -1, UserComp.LastGloryKillIndex, true);

						if (GloryKillIndex != -1)
						{
							GloryKill.Sequence = Feature.AnimData.GloryKills[GloryKillIndex];
							UserComp.LastGloryKillIndex = GloryKillIndex;

							CrumbTurnIntoHitGloryKill(GloryKill);
						}
						else
						{
							CrumbTurnIntoHit();
						}
					}
					else
					{
						CrumbTurnIntoHit();
					}
				}
			}
		}

		int NumComponents = 0;
		FVector AccumulatedLocation = FVector::ZeroVector;
		FVector TotalGrabVelocity;
		for (int i = UserComp.Grabs.Num() - 1; i >= 0; --i)
		{
			auto& Grab = UserComp.Grabs[i];

			if (Grab.TargetComponents.Num() == 1)
			{
				FVector GrabLocation = Grab.TargetComponents[0].WorldLocation;
				Grab.GrabVelocity = (GrabLocation - Grab.PrevGrabLocation) / Math::Max(DeltaTime, 0.001);
				TotalGrabVelocity += Grab.GrabVelocity;
				Grab.PrevGrabLocation = GrabLocation;
			}

			for (int j = Grab.TargetComponents.Num() - 1; j >= 0; --j)
			{
				auto TargetComponent = Grab.TargetComponents[j];

				if (TargetComponent == nullptr)
				{
					Grab.TargetComponents.RemoveAt(j);
					continue;
				}

				if (HasControl())
				{
					if (TargetComponent.IsDisabledForPlayer(Player) ||
						TargetComponent.IsBeingDestroyed() ||
						TargetComponent.Owner.IsActorBeingDestroyed())
					{
						UserComp.CrumbRelease(TargetComponent);
						continue;
					}
				}

				AccumulatedLocation += TargetComponent.WorldLocation;
				++NumComponents;
			}

			// Control side decides when to trigger grab response
			if (HasControl())
			{
				if (!Grab.bHasTriggeredResponse
					&& (Time::GetGameTimeSince(Grab.Timestamp) >= GravityWhip::Grab::GrabDelay || Grab.ResponseComponent.bGrabAttachImmediately)
					&& !bHasTurnedIntoHit)
				{
					if (!bHasActivatedGrab)
						CrumbActivateGrab();
					if (Grab.ResponseComponent.bGrabRequiresButtonMash)
					{
						if (!bButtonMashStarted)
						{
							FButtonMashSettings Settings = Grab.ResponseComponent.ButtonMashSettings;
							Settings.bBlockOtherGameplay = false;
							if (Grab.TargetComponents.Num() != 0)
								Settings.WidgetAttachComponent = Grab.TargetComponents[0];

							bButtonMashStarted = true;
							Player.StartButtonMash(Settings, this, FOnButtonMashCompleted(this, n"OnCompletedButtonMash"));
						}
						else if (bButtonMashCompleted)
						{
							CrumbTriggerGrabResponse(Grab.Actor);
						}
					}
					else
					{
						CrumbTriggerGrabResponse(Grab.Actor);
					}
				}
			}

			auto& SecondGrab = UserComp.Grabs[i];
			if (!bPlayedAttachAnimation && Time::GetGameTimeSince(SecondGrab.Timestamp) >= GravityWhip::Grab::GrabDelay && bHasActivatedGrab)
				TriggerAttachAnimation();

			// At this point, we should've gotten rid of any invalid targets
			//  so we should remove the entire grab itself if it hosts no targets
			if (SecondGrab.TargetComponents.Num() == 0)
				UserComp.Grabs.RemoveAt(i);
		}

		// Set force feedback
		if (bForceFeedbackBasedOnGrabMovement)
		{
			Player.SetFrameForceFeedback(ForceFeedback::ConvertWorldDirectionToForceFeedback(
				Player,
				TotalGrabVelocity.GetSafeNormal(),
				Math::GetMappedRangeValueClamped(
					FVector2D(300, 1000),
					FVector2D(0, 0.4),
					TotalGrabVelocity.Size())
			));
		}

		if (NumComponents != 0)
		{
			UserComp.GrabCenterLocation = (AccumulatedLocation / NumComponents);
		}


		if (!bHasTurnedIntoHit)
		{
			if (!HasAttachedToGrab())
			{
				Player.SetFrameForceFeedback(
					0, 0.5, 0, 0,
					ActiveDuration / GravityWhip::Grab::GrabDelay
				);
			}
			else
			{
				if (ActiveDuration - GravityWhip::Grab::GrabDelay < 0.25)
				{
					Player.SetFrameForceFeedback(
						0.8, 0.8, 0, 0,
					);
				}
			}
		}

		// If we're hitting something, deal the damage inside the hit window
		if (HasControl())
		{
			if (bHasTurnedIntoHit && UserComp.bInsideHitWindow && !bHasTriggeredHitEvent)
				TriggerRemainingHits();
		}

		if (WasActionStarted(ActionNames::PrimaryLevelAbility)
			&& ActiveDuration > GravityWhip::Grab::CanBufferHitsAfterDuration
			&& bHasTurnedIntoHit)
		{
			UserComp.BufferWhipPress();
		}
	}

	bool CanGloryKill(bool bForHit) const
	{
		for (int i = UserComp.Grabs.Num() - 1; i >= 0; --i)
		{
			auto& Grab = UserComp.Grabs[i];
			if (Grab.Actor == nullptr)
				continue;

			if (!Grab.ResponseComponent.bCanGloryKill)
				continue;

			auto HealthComp = UBasicAIHealthComponent::Get(Grab.Actor);
			if (HealthComp == nullptr)
				continue;

			if (bForHit)
			{
				if (HealthComp.GetCurrentHealth() > 0.5)
					continue;
			}

			return true;
		}

		return false;
	}

	void TriggerRemainingHits()
	{
		if (!HasControl())
			return;
		if (!bHasTurnedIntoHit && bHasActivatedGrab)
			return;
		if (bHasTriggeredHitEvent)
			return;
		bHasTriggeredHitEvent = true;

		for (int i = UserComp.Grabs.Num() - 1; i >= 0; --i)
		{
			auto& Grab = UserComp.Grabs[i];
			if (Grab.ResponseComponent != nullptr)
			{
				CrumbTriggerHit(Grab.ResponseComponent, UserComp.HitDirection, UserComp.HitPitch, UserComp.HitWindowExtraPushback, UserComp.HitWindowPushbackMultiplier);

				auto TargetComponents = Grab.TargetComponents;
				auto ResponseComponent = Grab.ResponseComponent;
				for (int j = TargetComponents.Num() - 1; j >= 0; --j)
				{
					auto TargetComponent = TargetComponents[j];
					
					FGravityWhipGrabData GrabData;
					GrabData.TargetComponent = TargetComponent;
					GrabData.HighlightPrimitive = UserComp.GetPrimitiveParent(TargetComponent);
					GrabData.GrabMode = Grab.ResponseComponent.GrabMode;
					GrabData.AudioData = TargetComponent.AudioData;
					
					UGravityWhipEventHandler::Trigger_WhipHitTarget(Player, GrabData);
				}
			}
		}
	}

	UFUNCTION(CrumbFunction)
	void CrumbTurnIntoHit()
	{
		bHasTurnedIntoHit = true;
		UserComp.AnimationData.bHasTurnedIntoWhipHit = true;

		for (int i = UserComp.Grabs.Num() - 1; i >= 0; --i)
		{
			auto& Grab = UserComp.Grabs[i];
			auto TargetComponents = Grab.TargetComponents;
			auto ResponseComponent = Grab.ResponseComponent;
			for (int j = TargetComponents.Num() - 1; j >= 0; --j)
			{
				auto TargetComponent = TargetComponents[j];
				
				FGravityWhipGrabData GrabData;
				GrabData.TargetComponent = TargetComponent;
				GrabData.HighlightPrimitive = UserComp.GetPrimitiveParent(TargetComponent);
				GrabData.GrabMode = Grab.ResponseComponent.GrabMode;
				GrabData.AudioData = TargetComponent.AudioData;
				
				UGravityWhipEventHandler::Trigger_WhipGrabTurnedIntoHit(Player, GrabData);
			}
		}
	}

	UFUNCTION(CrumbFunction)
	void CrumbTurnIntoHitGloryKill(FGravityWhipActiveGloryKill GloryKill)
	{
		bHasTurnedIntoHit = true;
		bKeepGrabAfterDeactivate = true;

		UserComp.TargetData.GrabMode = EGravityWhipGrabMode::GloryKill;
		UserComp.ActiveGloryKill = GloryKill;
	}

	UFUNCTION(CrumbFunction)
	private void CrumbTriggerHit(UGravityWhipResponseComponent ResponseComponent, EHazeCardinalDirection HitDirection, EAnimHitPitch HitPitch, float HitWindowExtraPushback, float HitWindowPushbackMultiplier)
	{
		if (!IsValid(ResponseComponent))
			return;

		ResponseComponent.OnHitByWhip.Broadcast(UserComp, HitDirection, HitPitch, HitWindowExtraPushback, HitWindowPushbackMultiplier);

		float HitStopDuration = 0.05;

		auto PlayerHitStopComp = UCombatHitStopComponent::GetOrCreate(Player);
		// if (PlayerHitStopComp != nullptr)
		// 	PlayerHitStopComp.ApplyHitStop(this, HitStopDuration);

		auto TargetHitStopComp = UCombatHitStopComponent::Get(ResponseComponent.Owner);
		if (TargetHitStopComp != nullptr)
			TargetHitStopComp.ApplyHitStop(this, HitStopDuration);

		if (UserComp.HitForceFeedback != nullptr)
			Player.PlayForceFeedback(UserComp.HitForceFeedback, false, true, this);
	}

	UFUNCTION(CrumbFunction)
	private void CrumbActivateGrab()
	{
		bHasActivatedGrab = true;
	}

	UFUNCTION()
	private void OnCompletedButtonMash()
	{
		bButtonMashCompleted = true;
	}

	UFUNCTION(CrumbFunction)
	private void CrumbTriggerGrabResponse(AActor GrabbedActor)
	{
		if (GrabbedActor == nullptr)
		{
			// devEnsure(false, f"Attempting to trigger whip grab response on an invalid actor.");
			return;
		}

		int GrabIndex = UserComp.GetActorGrabIndex(GrabbedActor);
		if (GrabIndex < 0)
		{
			if (GrabbedActor.IsObjectNetworked())
				devError(f"Couldn't find referenced actor \"{GrabbedActor.Name}\", the grabs are out of sync.");
			else
				devError(f"Couldn't find referenced actor \"{GrabbedActor.Name}\" which is not networked.");
			return;
		}

		TArray<UGravityWhipTargetComponent> GrabbedComponents;
		UserComp.GetGrabbedComponents(GrabbedComponents);

		auto& Grab = UserComp.Grabs[GrabIndex];
		Grab.bHasTriggeredResponse = true;

		auto TargetComponents = Grab.TargetComponents;
		auto ResponseComponent = Grab.ResponseComponent;
		for (int j = TargetComponents.Num() - 1; j >= 0; --j)
		{
			auto TargetComponent = TargetComponents[j];
			
			FGravityWhipGrabData GrabData;
			GrabData.TargetComponent = TargetComponent;
			GrabData.HighlightPrimitive = UserComp.GetPrimitiveParent(TargetComponent);
			GrabData.GrabMode = Grab.ResponseComponent.GrabMode;
			GrabData.AudioData = TargetComponent.AudioData;
			
			UGravityWhipEventHandler::Trigger_TargetGrabbed(Player, GrabData);

			ResponseComponent.Grab(UserComp, TargetComponent, GrabbedComponents);
		}
	}
}