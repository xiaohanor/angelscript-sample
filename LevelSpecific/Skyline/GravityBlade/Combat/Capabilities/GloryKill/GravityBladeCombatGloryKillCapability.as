class UGravityBladeCombatGloryKillCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default CapabilityTags.Add(GravityBladeTags::GravityBlade);
	
	default CapabilityTags.Add(GravityBladeCombatTags::GravityBladeCombat);
	default CapabilityTags.Add(GravityBladeCombatTags::GravityBladeGloryKill);

	default CapabilityTags.Add(BlockedWhileIn::Dash);
	default CapabilityTags.Add(BlockedWhileIn::Jump);

	default DebugCategory = GravityBlade::DebugCategory;

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 80;
	default SeparateInactiveTick(EHazeTickGroup::ActionMovement, 25);

	UGravityBladeUserComponent BladeComp;
	UGravityBladeCombatUserComponent CombatComp;

	UPlayerTargetablesComponent TargetablesComp;
	UPlayerMovementComponent MoveComp;
	UCombatHitStopComponent HitStopComp;
	UPlayerHealthComponent PlayerHealthComp;
	USteppingMovementData Movement;
	UGentlemanComponent MioGentlemanComp;
	UGentlemanComponent ZoeGentlemanComp;
	UGravityBladeCombatResponseComponent EnforcerResponseComp;
	UPlayerStepDashComponent StepDashComp;

	AAISkylineEnforcerBase TargetEnforcer;
	UBasicAIHealthComponent EnforcerHealthComp;

	FVector StartLocation;
	float TargetHeight;
	FVector ForwardVector;
	FVector AccumulatedTranslation;
	float TotalMovementLength;
	float MinimumSuctionDistance;

	bool bPreviousInsideHitWindow;

	bool bShouldUseGloryKillCamera = false;
	bool bHasBlockedJumpAndDash = false;

	float LastGloryKillTime;

	FQuat StartRot;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		BladeComp = UGravityBladeUserComponent::Get(Owner);
		CombatComp = UGravityBladeCombatUserComponent::Get(Owner);
		
		TargetablesComp = UPlayerTargetablesComponent::Get(Owner);
		MoveComp = UPlayerMovementComponent::Get(Owner);
		HitStopComp = UCombatHitStopComponent::Get(Owner);
		PlayerHealthComp = UPlayerHealthComponent::Get(Owner);
		StepDashComp = UPlayerStepDashComponent::Get(Owner);
		Movement = MoveComp.SetupSteppingMovementData();

		MioGentlemanComp = UGentlemanComponent::GetOrCreate(Game::Mio);
		ZoeGentlemanComp = UGentlemanComponent::GetOrCreate(Game::Zoe);
	}

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if(GravityBladeCombat::DEBUG_DrawEnforcerDangerMaxRange)
		{
			Debug::DrawDebugSphere(Player.ActorLocation, GravityBladeCombat::GloryKillEnforcerDangerMaxRange, 12, FLinearColor::Red);
			Debug::DrawDebugString(Player.ActorCenterLocation + FVector::ForwardVector * GravityBladeCombat::GloryKillEnforcerDangerMaxRange, "Enforcer danger max range", FLinearColor::Red);
			Debug::DrawDebugString(Player.ActorCenterLocation - FVector::ForwardVector * GravityBladeCombat::GloryKillEnforcerDangerMaxRange, "Enforcer danger max range", FLinearColor::Red);
			Debug::DrawDebugString(Player.ActorCenterLocation + FVector::RightVector * GravityBladeCombat::GloryKillEnforcerDangerMaxRange, "Enforcer danger max range", FLinearColor::Red);
			Debug::DrawDebugString(Player.ActorCenterLocation - FVector::RightVector * GravityBladeCombat::GloryKillEnforcerDangerMaxRange, "Enforcer danger max range", FLinearColor::Red);
		}
	}
#endif

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FGravityBladeCombatGloryKillActivatedParams& Params) const
	{
		if(MoveComp.HasMovedThisFrame())
			return false;

		if(!BladeComp.IsBladeEquipped())
			return false;

		if(!CombatComp.HasPendingAttack())
			return false;

		if(CombatComp.PendingAttackData.Target == nullptr)
			return false;

		if (!HasPendingGloryKillAttack())
			return false;
		
		if(!ShouldDoGloryKill())
			return false;

		bool bAirborne = ((CombatComp.PendingAttackData.MovementType == EGravityBladeAttackMovementType::Air) ||
							(CombatComp.PendingAttackData.MovementType == EGravityBladeAttackMovementType::AirHover) || 
							(CombatComp.PendingAttackData.MovementType == EGravityBladeAttackMovementType::AirSlam) ||
							(CombatComp.PendingAttackData.MovementType == EGravityBladeAttackMovementType::AirRush));
		
		// Not enough airborne glory kill anims, don't use them (remove if this changes)
		if (bAirborne)
			return false;							

		bool bUseRightFoot = Player.IsRightFootForward();
#if TEST
		bUseRightFoot = GravityBladeGloryKillDevToggles::GetOverrideSideRight(bUseRightFoot);
#endif		

		int GloryKillIndex = CombatComp.GetGloryKillIndex(bAirborne);
		if (GloryKillIndex == -1)
			return false;

		// Glory kills aren't always possible to perform depending on the world geometry around it
		if (!CombatComp.IsGloryKillValidToPerform(CombatComp.PendingAttackData.Target, GloryKillIndex, bAirborne, bUseRightFoot))
		{
			// Retry to find another glory kill that might validate
			int TryIndex = CombatComp.GetGloryKillIndex(bAirborne, IgnoreGloryKillIndex = GloryKillIndex);
			if (TryIndex == -1 || TryIndex == GloryKillIndex)
				return false;

			if (CombatComp.IsGloryKillValidToPerform(CombatComp.PendingAttackData.Target, TryIndex, bAirborne, bUseRightFoot))
				GloryKillIndex = TryIndex;
			else
				return false;
		}

		Params.bAirborne = bAirborne;
		Params.GloryKillIndex = GloryKillIndex;
		Params.bUseRightFoot = bUseRightFoot;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!CombatComp.HasActiveAttack())
			return true;

		if (!HasPendingGloryKillAttack())	
			return true;

		if (ActiveDuration > CombatComp.ActiveGloryKillAnimation.MetaData.Duration)
			return true;

		if (CombatComp.HasPendingAttack())
		{
			if (CombatComp.bInsideComboWindow)
				return true;
		}

		if(CombatComp.bInsideSettleWindow && CombatComp.ShouldExitSettle())
			return true;

		return false;
	}

	bool HasPendingGloryKillAttack() const
	{
		if (GravityBladeCombat::bAllowOnlyGroundedGloryKills)
		{
			if(CombatComp.PendingAttackData.MovementType != EGravityBladeAttackMovementType::Ground)
				return false;
			if(CombatComp.PendingAttackData.AnimationType != EGravityBladeAttackAnimationType::GroundAttack)
				return false;
		}
		else
		{
			if ((CombatComp.PendingAttackData.AnimationType != EGravityBladeAttackAnimationType::GroundAttack) &&
				(CombatComp.PendingAttackData.AnimationType != EGravityBladeAttackAnimationType::SprintAttack) &&
				(CombatComp.PendingAttackData.AnimationType != EGravityBladeAttackAnimationType::AirAttack) &&
				(CombatComp.PendingAttackData.AnimationType != EGravityBladeAttackAnimationType::AirSlamAttack) &&
				(CombatComp.PendingAttackData.AnimationType != EGravityBladeAttackAnimationType::DashAttack) &&
				(CombatComp.PendingAttackData.AnimationType != EGravityBladeAttackAnimationType::RollDashAttack) &&
				(CombatComp.PendingAttackData.AnimationType != EGravityBladeAttackAnimationType::RollDashJumpAttack) &&
				(CombatComp.PendingAttackData.AnimationType != EGravityBladeAttackAnimationType::AirDashAttack) &&
				(CombatComp.PendingAttackData.AnimationType != EGravityBladeAttackAnimationType::GroundAttack))
				return false;
		}
		return true;
	}

	bool bCameraActive = false;

	UFUNCTION(BlueprintOverride)
	void OnActivated(FGravityBladeCombatGloryKillActivatedParams Params)
	{
		bPreviousInsideHitWindow = CombatComp.bInsideHitWindow;
		BladeComp.UnsheatheBlade();

		MioGentlemanComp.SetInvalidTarget(this);
		if(!GravityBladeCombat::bAllowCancellingGloryKills)
		{
			PlayerHealthComp.AddDamageInvulnerability(this, 10);
		}
		CombatComp.SetActiveAttackData(CombatComp.PendingAttackData, this);
		CombatComp.StartAttackAnimation();
		CombatComp.bGloryKillInterrupted = false;
		CombatComp.StartGloryKill(Params.GloryKillIndex, Params.bAirborne, Params.bUseRightFoot);
		CombatComp.bGloryKillActive = true;
		Player.BlockCapabilities(GravityBladeCombatTags::GravityBladeAttack, this);
		TargetEnforcer = Cast<AAISkylineEnforcerBase>(CombatComp.ActiveAttackData.Target.Owner);
		EnforcerHealthComp = UBasicAIHealthComponent::Get(TargetEnforcer);
		EnforcerResponseComp = UGravityBladeCombatResponseComponent::Get(TargetEnforcer);

		if(!GravityBladeCombat::bAllowCancellingGloryKills)
		{
			Player.BlockCapabilities(PlayerMovementTags::Dash, this);
			Player.BlockCapabilities(PlayerMovementTags::Jump, this);
			Player.BlockCapabilities(n"Knockdown", this);
		}
		bHasBlockedJumpAndDash = true;

		// ApplyCameraSettings();

		StartRot = Player.ActorQuat;
		FVector ToTargetHorizontal = (TargetEnforcer.ActorLocation - Player.ActorLocation).ConstrainToPlane(MoveComp.WorldUp);
		if (ToTargetHorizontal.SizeSquared() < Math::Square(40.0))
		{
			// When close to target we shouldn't rotate
			CombatComp.GloryKillWantedPlayerRotation = StartRot;		
		}
		else
		{
			// When some ways away, we rotate to face target so it won't have to slide in front of us
			CombatComp.GloryKillWantedPlayerRotation = ToTargetHorizontal.ToOrientationQuat();
		}

		if(HasControl())
		{
			AccumulatedTranslation = FVector::ZeroVector;

			// Get forward vector after turning towards movement direction
			//  then use our new forward to find suction target
			ForwardVector = CombatComp.GetMovementDirection(Player.ViewRotation.ForwardVector);

			TotalMovementLength = CombatComp.ActiveGloryKillAnimation.MetaData.MovementLength;
			if (CombatComp.ActiveAttackData.Target != nullptr)
			{
				// Calculate minimum distance we want to reach and extend
				//  our total root motion movement length to accommodate
				MinimumSuctionDistance = CombatComp.GetSuctionReachDistance(CombatComp.ActiveAttackData.Target);
				TotalMovementLength = Math::Max(TotalMovementLength, ToTargetHorizontal.Size() - MinimumSuctionDistance);
			}
		}

		// Target responsecomponent will react to direct OnHit calls from this capability but ignore tracing for hits while doing glory kill
		EnforcerResponseComp.AddResponseComponentDisable(this);

		StartLocation = Owner.ActorLocation;
		TargetHeight = 0.0;
		if (CombatComp.ActiveAttackData.Target != nullptr)
			TargetHeight = CombatComp.ActiveAttackData.Target.Owner.ActorUpVector.DotProduct(CombatComp.ActiveAttackData.Target.Owner.ActorLocation - StartLocation);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		// Interrupted
		if(GravityBladeCombat::bAllowCancellingGloryKills)
		{
			if(Player.IsCapabilityTagBlocked(BlockedWhileIn::Dash) || Player.IsCapabilityTagBlocked(BlockedWhileIn::Jump))
				CombatComp.bGloryKillInterrupted = true;
		}

		if(!CombatComp.bGloryKillInterrupted)
			LastGloryKillTime = Time::GameTimeSeconds;

		MioGentlemanComp.ClearInvalidTarget(this);
		if(!GravityBladeCombat::bAllowCancellingGloryKills)
		{
			PlayerHealthComp.RemoveDamageInvulnerability(this);
			PlayerHealthComp.AddDamageInvulnerability(this, 1);
		}
		// Reset current combo when attack finishes
		CombatComp.StopActiveAttackData(this, bBlockInterruptByMovement = false);

		if (bHasBlockedJumpAndDash && !GravityBladeCombat::bAllowCancellingGloryKills)
		{
			Player.UnblockCapabilities(PlayerMovementTags::Dash, this);
			Player.UnblockCapabilities(PlayerMovementTags::Jump, this);
			bHasBlockedJumpAndDash = false;
		}

		Player.UnblockCapabilities(GravityBladeCombatTags::GravityBladeAttack, this);
		if(!GravityBladeCombat::bAllowCancellingGloryKills)
			Player.UnblockCapabilities(n"Knockdown", this);
		CombatComp.bGloryKillActive = false;

		// if(bCameraActive)
		// {
		// 	ClearCameraSettings();
		// }

		// Allow target response component to be hit by traces again
		EnforcerResponseComp.RemoveResponseComponentDisable(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// if(ActiveDuration > 0.0 && bCameraActive && CombatComp.bInsideSettleWindow)
		// {
		// 	ClearCameraSettings();
		// }

		TArray<FHazeAnimNotifyStateGatherInfo> TriggerTimes;
		CombatComp.ActiveGloryKillAnimation.Animation.Sequence.GetAnimNotifyStateTriggerTimes(UAnimNotifyGravityBladeHitWindow, TriggerTimes);

		if(ActiveDuration > 0.0 && !EnforcerHealthComp.IsDead() && CombatComp.bInsideHitWindow && !bPreviousInsideHitWindow)
		{
			bool bIsDead = ActiveDuration >= TriggerTimes[TriggerTimes.Num() - 1].TriggerTime;

			FVector ClosestPoint;
			TargetEnforcer.CapsuleComponent.GetClosestPointOnCollision(Player.ActorCenterLocation, ClosestPoint);

			FVector ToClosestPoint = (ClosestPoint - Player.ActorCenterLocation);

			FGravityBladeHitData HitData;
			HitData.Damage = bIsDead ? EnforcerHealthComp.CurrentHealth : 0.0;
			HitData.DamageType = EDamageType::MeleeSharp;
			HitData.AttackMovementLength = CombatComp.ActiveGloryKillAnimation.MetaData.MovementLength;
			HitData.Actor = TargetEnforcer;
			HitData.Component = TargetEnforcer.CapsuleComponent;
			HitData.ImpactPoint = ClosestPoint;
			HitData.ImpactNormal = -ToClosestPoint.GetSafeNormal();
			HitData.MovementType = EGravityBladeAttackMovementType::Ground;

			// Trigger a hit here, damage is handled by the enforcer glory death capability
			EnforcerResponseComp.Hit(CombatComp, HitData);
			UGravityBladeCombatEventHandler::Trigger_OnHitEnemy(BladeComp.Blade, HitData);
		}

		bPreviousInsideHitWindow = CombatComp.bInsideHitWindow;

		if (MoveComp.PrepareMove(Movement))
		{
			if(HasControl())
			{
				Movement.StopMovementWhenLeavingEdgeThisFrame();

				FVector RootMovement = BladeComp.GetRootMotionForFullAnimation(
					ActiveDuration, DeltaTime, TotalMovementLength,
					CombatComp.ActiveGloryKillAnimation.MetaData.Duration);

				// Move as if we're already turned in target direction
				FVector DeltaMovement = CombatComp.GloryKillWantedPlayerRotation.RotateVector(RootMovement);

				// Turn toward target direction quickly
				Movement.SetRotation(FQuat::Slerp(StartRot, CombatComp.GloryKillWantedPlayerRotation, Math::Min(ActiveDuration / 0.2, 1.0)));

				DeltaMovement = DeltaMovement.VectorPlaneProject(MoveComp.WorldUp);

				Movement.AddDelta(DeltaMovement);
				Movement.AddGravityAcceleration();

				float HeightAdjustDuration = Math::Min(0.5, CombatComp.ActiveGloryKillAnimation.MetaData.Duration * 0.25);
				if (ActiveDuration < HeightAdjustDuration)
				{
					// Adjust so we end up at target height
					float WantedHeight = Math::EaseIn(0.0, TargetHeight, ActiveDuration / HeightAdjustDuration, 2.0);
					float CurHeight = CombatComp.ActiveAttackData.Target.UpVector.DotProduct(Player.ActorLocation - StartLocation);
					Movement.AddDelta(CombatComp.ActiveAttackData.Target.UpVector * (WantedHeight - CurHeight));
				}
			}
			else
			{
				Movement.ApplyCrumbSyncedGroundMovement();
			}

			MoveComp.ApplyMoveAndRequestLocomotion(Movement, GravityBladeCombat::GloryKillFeature);
		}

		// Once we're in the settle window, unblock dash and jump so we can cancel it
		if (bHasBlockedJumpAndDash && CombatComp.bInsideSettleWindow && !GravityBladeCombat::bAllowCancellingGloryKills)
		{
			Player.UnblockCapabilities(PlayerMovementTags::Dash, this);
			Player.UnblockCapabilities(PlayerMovementTags::Jump, this);
			bHasBlockedJumpAndDash = false;
		}
	}

	void ApplyCameraSettings()
	{
		if(!bShouldUseGloryKillCamera)
			return;
		
		FVector2D ViewPointRelativeLocation;
		SceneView::ProjectWorldToViewpointRelativePosition(Player, TargetEnforcer.ActorLocation, ViewPointRelativeLocation);

		// Camera settings
		{
			const float BlendInTime = CameraSettings.BlendInTime < 0.0 ? CombatComp.GloryKillCameraSettingBlendInTime : CameraSettings.BlendInTime;
			Player.ApplyCameraSettings(CombatComp.GloryKillCameraSettings, BlendInTime, this, EHazeCameraPriority::High, SubPriority = 61);

			auto Settings = UCameraSettings::GetSettings(Player);

			if(CameraSettings.bUsePivotOffset)
			{
				FVector RelevantPivotOffset = CameraSettings.PivotOffset;
				if(POISettings.bUseSeparateLocalOffsetIfEnforcerLeftOnScreen && ViewPointRelativeLocation.X < 0.5)
					RelevantPivotOffset = CameraSettings.SeparatePivotOffset;

				Settings.PivotOffset.Apply(RelevantPivotOffset, this, BlendInTime, EHazeCameraPriority::High, SubPriority = 62);
			}

			if(CameraSettings.bUseFOV)
				Settings.FOV.Apply(CameraSettings.FOV, this, BlendInTime, EHazeCameraPriority::High, SubPriority = 62);

			if(CameraSettings.bUseCameraOffset)
				Settings.CameraOffset.Apply(CameraSettings.CameraOffset, this, BlendInTime, EHazeCameraPriority::High, SubPriority = 62);
		}

		// Point of interest
		if(bShouldUseGloryKillCamera)
		{
			FHazePointOfInterestFocusTargetInfo Poi;

			if(POISettings.TargetType == EGravityBladeGloryKillPOITargetType::Player)
				Poi.SetFocusToActor(Player);
			else if(POISettings.TargetType == EGravityBladeGloryKillPOITargetType::Enforcer)
				Poi.SetFocusToActor(TargetEnforcer);
			else if(POISettings.TargetType == EGravityBladeGloryKillPOITargetType::InBetweenEnforcerPlayer ||
				POISettings.TargetType == EGravityBladeGloryKillPOITargetType::EnforcerAlignBone ||
				POISettings.TargetType == EGravityBladeGloryKillPOITargetType::InBetweenEnforcerAlignBonePlayer ||
				POISettings.TargetType == EGravityBladeGloryKillPOITargetType::PlayerAlignBone ||
				POISettings.TargetType == EGravityBladeGloryKillPOITargetType::InBetweenPlayerAlignBonePlayer ||
				POISettings.TargetType == EGravityBladeGloryKillPOITargetType::PlayerHandBaseIK)
			{
				SetupCustomTargetOnPoi(Poi);
			}
			else
				devError("Forgot to add case to handle poi target type!");
			
			FVector LocalOffset = POISettings.LocalOffset;
			if(POISettings.bUseSeparateLocalOffsetIfEnforcerLeftOnScreen && ViewPointRelativeLocation.X < 0.5)
				LocalOffset = POISettings.SeparateLocalOffset;

			Poi.LocalOffset = LocalOffset;

			FApplyPointOfInterestSettings Settings;
			Settings.ClearOnInput = CombatComp.GloryKillPOIClearOnInputSettings;
			Player.ApplyPointOfInterest(this, Poi, Settings, POISettings.BlendInTime);
		}

		bCameraActive = true;
	}

	void SetupCustomTargetOnPoi(FHazePointOfInterestFocusTargetInfo& Poi)
	{
		if(CombatComp.GloryKillCameraData.CustomTargetSceneComponent == nullptr)
			CombatComp.GloryKillCameraData.CustomTargetSceneComponent = USceneComponent::Create(Player);

		Poi.SetFocusToComponent(CombatComp.GloryKillCameraData.CustomTargetSceneComponent);
		CombatComp.GloryKillCameraData.bMoveCustomPoint = true;
		CombatComp.GloryKillCameraData.TargetEnforcer = TargetEnforcer;
		CombatComp.GloryKillCameraData.TargetType = POISettings.TargetType;
	}

	void ClearCameraSettings()
	{
		const float BlendOutTime = CameraSettings.BlendOutTime < 0.0 ? CombatComp.GloryKillCameraSettingBlendOutTime : CameraSettings.BlendOutTime;

		Player.ClearCameraSettingsByInstigator(this, BlendOutTime);
		
		if(bShouldUseGloryKillCamera)
			Player.ClearPointOfInterestByInstigator(this);

		bCameraActive = false;
		CombatComp.GloryKillCameraData.bMoveCustomPoint = false;
	}

	// Checks if there is only one opponent close-by which is the opponent that is targeted now. If so, do glory kill
	bool ShouldDoGloryKill() const
	{
#if EDITOR
		if(GravityBladeGloryKillDevToggles::Disable.IsEnabled())
			return false;
#endif

		auto Enforcer = Cast<AAISkylineEnforcerBase>(CombatComp.PendingAttackData.Target.Owner);
		if(Enforcer == nullptr)
			return false;

		// Only allow glory kills against targets in our front(ish) hemisphere
		FVector Origin = Owner.ActorCenterLocation - Owner.ActorForwardVector * 20.0;
		if (Owner.ActorForwardVector.DotProduct(Enforcer.ActorCenterLocation - Origin) < 0.0)
			return false; // We will trigger a normal attack instead which will turn us toward target so we can glory kill with next attack

		if(Time::GetGameTimeSince(LastGloryKillTime) < GravityBladeCombat::GloryKillChainedDuration)
			return true;

		UBasicAIHealthComponent HealthComp = Enforcer.HealthComp;

		// Trigger glory kill only if target is below set health fraction (ignore damage of attack that will be triggered if there is no glory kill)
		if(HealthComp.CurrentHealth > GravityBladeCombat::GloryKillDamage)
		 	return false;

		TArray<AHazeActor> Opponents = MioGentlemanComp.GetOpponents();

		// Add opponents that are targeting Zoe, but ignore duplicates
		for(AHazeActor Opponent : ZoeGentlemanComp.GetOpponents())
		{
			if(Opponents.Contains(Opponent))
				continue;

			Opponents.Add(Opponent);
		}

		for(int i = Opponents.Num() - 1; i >= 0; i--)
		{
			auto CurrentHealthComp = UBasicAIHealthComponent::Get(Opponents[i]);
			if(CurrentHealthComp.IsDead())
				Opponents.RemoveAt(i);
		}

		// Get amount of enforcers that's currently targeting Mio (excluding the gravity blade's current target)
		int AmountOfOtherEnforcers = 0;
		for(auto Opponent : Opponents)
		{
			auto Current = Cast<AAISkylineEnforcerBase>(Opponent);

			// Only count enforcers and not all AI's
			if(Current == nullptr)
				continue;

			// Ignore the glory kill target
			if(CombatComp.PendingAttackData.Target.Owner == Opponent)
				continue;

			// If the enforcer is far away, don't count it as a threat
			if(Current.ActorLocation.DistSquared(Player.ActorLocation) > Math::Square(GravityBladeCombat::GloryKillEnforcerDangerMaxRange))
				continue;

			++AmountOfOtherEnforcers;
		}

		// If there are other dangerous enforcers around, we only randomly trigger glory kills
		if(AmountOfOtherEnforcers > 0)
		{
			if(Math::RandRange(0.0, 1.0) > GravityBladeCombat::GloryKillWhileInDangerChance)
				return false;
		}

		return true;
	}

	const FGravityBladeGloryKillAnimFeatureCameraSettings& GetCameraSettings() const property
	{
		return CombatComp.ActiveGloryKillAnimation.MetaData.CameraSettings;
	}

	const FGravityBladeGloryKillAnimFeaturePOISettings& GetPOISettings() const property
	{
		return CombatComp.ActiveGloryKillAnimation.MetaData.POISettings;
	}
}

struct FGravityBladeCombatGloryKillActivatedParams
{
	int GloryKillIndex;
	bool bAirborne = false;
	bool bUseRightFoot = false;
}

