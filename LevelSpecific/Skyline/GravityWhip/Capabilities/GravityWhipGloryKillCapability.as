class UGravityWhipGloryKillCapability : UHazePlayerCapability
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

	default DebugCategory = GravityWhipTags::GravityWhip;

	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 106;

	UGravityWhipUserComponent UserComp;
	UPlayerMovementComponent MoveComp;

	TArray<float32> HitTimes;
	float DamagePerHit = 0.0;
	float ComboWindowStartTime = 0.0;
	bool bRelease = false;
	bool bIsStrafing = false;
	bool bIsMovementLocked = false;

	TArray<UGravityWhipResponseComponent> GrabbedComponents;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		UserComp = UGravityWhipUserComponent::Get(Owner);
		MoveComp = UPlayerMovementComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!UserComp.IsGrabbingAny())
			return false;

		if (UserComp.GetPrimaryGrabMode() != EGravityWhipGrabMode::GloryKill)
			return false;
		
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!UserComp.IsGrabbingAny())
			return true;

		if (UserComp.GetPrimaryGrabMode() != EGravityWhipGrabMode::GloryKill)
			return true;
		
		if (Player.IsPlayerDead())
			return true;

		if (!UserComp.ActiveGloryKill.IsSet())
			return true;

		if (ActiveDuration > UserComp.ActiveGloryKill.Value.Sequence.PlayerAnimation.Sequence.PlayLength)
			return true;

		if (bRelease)
			return true;

		if (ActiveDuration > ComboWindowStartTime && ComboWindowStartTime > 0.0)
		{
			if (MoveComp.IsInAir())
				return true;
			if (Player.IsAnyCapabilityActive(PlayerMovementTags::Dash))
				return true;
		}

		return false;
	}
	
	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		auto Feature = Player.Mesh.GetFeatureByClass(ULocomotionFeatureGravityWhip);
		auto Anim = UserComp.ActiveGloryKill.GetValue();

		HitTimes.Reset();
		UserComp.bGloryKillMovementLocked = false;
		GrabbedComponents.Reset();

		Anim.Sequence.WhipAnimation.Sequence.GetAnimNotifyTriggerTimes(UGravityWhipGloryKillDamageNotify, HitTimes);
		DamagePerHit = 1.0 / Math::Max(HitTimes.Num(), 1);
		bRelease = false;

		if (Anim.Sequence.StrafeDuration > 0.0)
		{
			Player.EnableStrafe(this);
			bIsStrafing = true;
		}
		else
		{
			bIsStrafing = false;
		}

		Player.ApplyCameraSettings(Anim.Sequence.CameraSettings, 0.5, this);

		ComboWindowStartTime = Anim.Sequence.PlayerAnimation.Sequence.GetAnimNotifyTime(UGravityWhipGloryKillComboWindowNotify);

		for (FGravityWhipUserGrab& Grab : UserComp.Grabs)
		{
			Grab.bForcedGrab = true;
			
			if (IsValid(Grab.ResponseComponent))
			{
				Grab.ResponseComponent.OnGloryKill.Broadcast(UserComp, Anim);
				GrabbedComponents.Add(Grab.ResponseComponent);
			}

			if (IsValid(Grab.Actor))
			{
				auto HealthComp = UBasicAIHealthComponent::Get(Grab.Actor);
				if (HealthComp != nullptr)
					DamagePerHit *= HealthComp.CurrentHealth;
			}
		}

		Player.BlockCapabilities(GravityWhipTags::GravityWhipTarget, this);
		UGravityWhipEventHandler::Trigger_WhipGloryKillStart(Owner);
	}
	
	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if (HitTimes.Num() != 0)
		{
			for (FGravityWhipUserGrab& Grab : UserComp.Grabs)
			{
				if (IsValid(Grab.Actor))
				{
					auto HealthComp = UBasicAIHealthComponent::Get(Grab.Actor);
					if (HealthComp != nullptr)
						HealthComp.TakeDamage(DamagePerHit * HitTimes.Num(), EDamageType::Default, Player);

					FGravityWhipEventHandlerWhipGloryKillHitData Data;
					Data.TargetComponent = UGravityWhipTargetComponent::Get(Grab.Actor);
					UGravityWhipEventHandler::Trigger_WhipGloryKillHit(Owner, Data);
				}
			}
		}

		UserComp.ActiveGloryKill.Reset();

		if (bIsStrafing)
		{
			Player.DisableStrafe(this);
			bIsStrafing = false;
		}
		
		for (UGravityWhipResponseComponent GrabbedComp : GrabbedComponents)
		{
			if (IsValid(GrabbedComp))
				GrabbedComp.OnGloryKillEnded.Broadcast();
		}

		GrabbedComponents.Reset();
		UserComp.ReleaseAll();
		UserComp.ReleaseTimestamp = Time::GameTimeSeconds;
		UserComp.bReleaseStrafeImmediately = true;
		UserComp.ConsumeBufferedWhipPress();
		UGravityWhipEventHandler::Trigger_WhipStartRetracting(Player);

		Player.ClearCameraSettingsByInstigator(this, 1);

		if (bIsMovementLocked)
		{
			bIsMovementLocked = false;
			Player.UnblockCapabilities(CapabilityTags::GameplayAction, this);
			Player.UnblockCapabilities(CapabilityTags::MovementInput, this);
		}

		Player.UnblockCapabilities(GravityWhipTags::GravityWhipTarget, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		AActor TargetActor;

		int NumComponents = 0;
		FVector AccumulatedLocation = FVector::ZeroVector;
		for (int i = UserComp.Grabs.Num() - 1; i >= 0; --i)
		{
			auto& Grab = UserComp.Grabs[i];
			TargetActor = Grab.Actor;

			for (int j = Grab.TargetComponents.Num() - 1; j >= 0; --j)
			{
				auto TargetComponent = Grab.TargetComponents[j];
				if (TargetComponent == nullptr)
					continue;
				
				auto TargetMesh = USkeletalMeshComponent::Get(Grab.Actor);
				if (TargetMesh != nullptr && !UserComp.ActiveGloryKill.Value.Sequence.WhipAttachSocket.IsNone())
					AccumulatedLocation += TargetMesh.GetSocketLocation(UserComp.ActiveGloryKill.Value.Sequence.WhipAttachSocket);
				else
					AccumulatedLocation += TargetComponent.WorldLocation;

				++NumComponents;
			}
		}

		if (NumComponents != 0)
		{
			UserComp.GrabCenterLocation = (AccumulatedLocation / NumComponents);
		}

		// Debug::DrawDebugSphere(UserComp.GrabCenterLocation);

		for (int i = 0; i < HitTimes.Num(); ++i)
		{
			HitTimes[i] -= float32(DeltaTime);
			if (HitTimes[i] <= 0)
			{
				if (TargetActor != nullptr)
				{
					auto HealthComp = UBasicAIHealthComponent::Get(TargetActor);
					if (HealthComp != nullptr)
						HealthComp.TakeDamage(DamagePerHit, EDamageType::Default, Player);

					FGravityWhipEventHandlerWhipGloryKillHitData Data;
					Data.TargetComponent = UGravityWhipTargetComponent::Get(TargetActor);
					UGravityWhipEventHandler::Trigger_WhipGloryKillHit(Owner, Data);
				}

				HitTimes.RemoveAt(i);
				--i;
			}
		}

		const bool bInComboWindow = (ActiveDuration > ComboWindowStartTime && ComboWindowStartTime > 0.0);
		if (WasActionStarted(ActionNames::PrimaryLevelAbility) && bInComboWindow)
		{
			UserComp.BufferWhipPress();
			bRelease = true;
		}

		// Allow releasing from the glory kill early if we're holding input
		if (bInComboWindow && !bIsMovementLocked)
		{
			if (MoveComp.MovementInput.Size() > 0.1)
			{
				bRelease = true;
			}
		}

		if (ActiveDuration > UserComp.ActiveGloryKill.Value.Sequence.StrafeDuration
			&& bIsStrafing)
		{
			Player.DisableStrafe(this);
			bIsStrafing = false;
		}

		if (bIsMovementLocked)
		{
			if (!UserComp.bGloryKillMovementLocked)
			{
				bIsMovementLocked = false;
				Player.UnblockCapabilities(CapabilityTags::GameplayAction, this);
				Player.UnblockCapabilities(CapabilityTags::MovementInput, this);
			}
		}
		else
		{
			if (UserComp.bGloryKillMovementLocked)
			{
				bIsMovementLocked = true;
				Player.BlockCapabilities(CapabilityTags::GameplayAction, this);
				Player.BlockCapabilities(CapabilityTags::MovementInput, this);
			}
		}

		float FFFrequency = 10.0;
		float FFIntensity = 0.1;
		FHazeFrameForceFeedback FF;
		FF.LeftMotor = Math::Sin(ActiveDuration * FFFrequency) * FFIntensity;
		FF.RightMotor = Math::Sin(-ActiveDuration * FFFrequency) * FFIntensity;
		Player.SetFrameForceFeedback(FF);
	}
}

class UGravityWhipGloryKillDamageNotify : UAnimNotify
{
}

class UGravityWhipGloryKillComboWindowNotify : UAnimNotify
{
}

class UGravityWhipGloryKillLockedMovement : UAnimNotifyState
{
	UFUNCTION(BlueprintOverride)
	bool NotifyBegin(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation, float TotalDuration,
	                 FAnimNotifyEventReference EventReference) const
	{
		auto UserComp = UGravityWhipUserComponent::Get(MeshComp.Owner);
		if (UserComp != nullptr)
			UserComp.bGloryKillMovementLocked = true;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool NotifyEnd(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation,
				   FAnimNotifyEventReference EventReference) const
	{
		auto UserComp = UGravityWhipUserComponent::Get(MeshComp.Owner);
		if (UserComp != nullptr)
			UserComp.bGloryKillMovementLocked = false;
		return true;
	}
}