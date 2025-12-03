struct FWalkerHeadFloodedEscapeDeactivateParams
{
	bool bSuccess = false;
}

class UIslandWalkerHeadFloodedEscapeBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Movement);
	default Requirements.Add(EBasicBehaviourRequirement::Animation);

	UIslandWalkerHeadComponent HeadComp;
	AIslandWalkerArenaLimits Arena;
	AIslandWalkerHeadStumpTarget Stump;
	UIslandWalkerAnimationComponent WalkerAnimComp;
	UIslandRedBlueReflectComponent BulletReflectComp;
	UIslandWalkerPhaseComponent WalkerPhaseComp;
	TArray<UPerchPointComponent> PerchPoints;
	TArray<UIslandWalkerHeadHatchInteractionComponent> HatchInteracts;
	UIslandWalkerSettings Settings;
	int iEscapeSpline = 0;
	UHazeSplineComponent Spline;
	bool bHasDetachedPlayers = false;
	bool bRecovering;
	float RecoverDistanceAlongSpline;
	float RecoverCompleteTime;
	float RecoverAllowMovementTime;
	float ShakeOffPlayersTime;
	bool bIsMovingAlongSpline;
	float StartMovingTime;
	bool bPlayersAreInvulnerable = false;
	bool bHasActivatedCamera;

	FHazePlayRndSequenceData HurtReactions;
	float HurtAnimCooldown;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		
		HeadComp = UIslandWalkerHeadComponent::Get(Owner);
		WalkerAnimComp = UIslandWalkerAnimationComponent::Get(Owner);
		Owner.GetComponentsByClass(PerchPoints);
		Owner.GetComponentsByClass(HatchInteracts);
		Settings = UIslandWalkerSettings::GetSettings(Owner);
		BulletReflectComp = UIslandRedBlueReflectComponent::Get(Owner);
		UIslandWalkerHeadStumpRoot::Get(Owner).OnStumpTargetSetup.AddUFunction(this, n"OnStumpSetup");
		WalkerPhaseComp = UIslandWalkerPhaseComponent::Get(HeadComp.NeckCableOrigin.Owner);
		WalkerPhaseComp.OnSkipIntro.AddUFunction(this, n"OnSkipIntro");
		SetupHurtAnims(20);	
	}

	UFUNCTION()
	private void OnStumpSetup(AIslandWalkerHeadStumpTarget Target)
	{
		Stump = Target;
		Stump.OnTakeDamage.AddUFunction(this, n"OnTakeDamage");
		Arena = TListedActors<AIslandWalkerArenaLimits>().GetSingle();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if (Stump == nullptr)
			return false;
		if (HeadComp.State != EIslandWalkerHeadState::Escape)
			return false;
		if (HeadComp.bAtEndOfEscape)
			return false;
		if (Arena == nullptr)
			return false;
		if (!Arena.bIsFlooded)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FWalkerHeadFloodedEscapeDeactivateParams& OutParams) const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (!bRecovering && DestinationComp.IsAtSplineEnd(Spline, 10.0))
		{
			OutParams.bSuccess = true;
			return true;
		}
		if (bRecovering && (ActiveDuration > RecoverCompleteTime))
		{
			OutParams.bSuccess = false;
			return true;
		}
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();

		// We can take damage, but should show as ignoring since you only shoot into hatch
		// We do not need to ShowAllowDamage since subsequent beahviours will handlle that.
		Stump.ShowIgnoreDamage(); 

		if (!Arena.EscapeOrder.IsValidIndex(iEscapeSpline))
		{
			Cooldown.Set(10.0);
			return;
		}
		Spline = Arena.EscapeOrder[iEscapeSpline].Spline;
		bHasDetachedPlayers = false;
		HeadComp.bAtEndOfEscape = false;
		HeadComp.bHeadEscapeSuccess = false;
		HeadComp.HeadEscapeStartDistanceAlongSpline = 0.0;
		Stump.ForceFieldComp.PowerDown();
		BulletReflectComp.AddReflectBlockerForBothPlayers(this);
		
		bRecovering = false;
		RecoverDistanceAlongSpline = Spline.SplineLength * 0.25;
		RecoverCompleteTime = 60.0; // Will be reduced to throw off anim play length after time when starting to recover		
		RecoverAllowMovementTime = BIG_NUMBER;
		ShakeOffPlayersTime = BIG_NUMBER;

		// Start with a hurt animation before taking off
		bIsMovingAlongSpline = false;
		StartMovingTime = WalkerAnimComp.GetRequestedAnimation(FeatureTagWalker::HatchFlight, SubTagWalkerHatchFlight::StartLiftOff).ScaledPlayLength;
		AnimComp.RequestFeature(FeatureTagWalker::HatchFlight, SubTagWalkerHatchFlight::StartLiftOff, EBasicBehaviourPriority::Medium, this);
		HurtAnimCooldown = StartMovingTime + 0.7; 

		// Set interact state for player anims
		for (UIslandWalkerHeadHatchInteractionComponent Interact : HatchInteracts)
		{
			Interact.State = EWalkerHeadHatchInteractionState::LiftOff;
		}

		// Players are invulnerable until shaken off, we don't want them to die from e.g. a slight dip into the acid. 
		Game::Mio.BlockCapabilities(n"Death", this);
		Game::Zoe.BlockCapabilities(n"Death", this);
		bPlayersAreInvulnerable = true;

		// Low wobble and friction for when not following spline
		UIslandWalkerSettings::SetHeadWobbleAmplitude(Owner, FVector(0.0, 0.0, 0.0), this, EHazeSettingsPriority::Gameplay);
		UIslandWalkerSettings::SetHeadFriction(Owner, 0.25, this, EHazeSettingsPriority::Gameplay);
		UIslandWalkerHeadEffectHandler::Trigger_OnStartFinalSplineRunToDestruction(Cast<AHazeActor>(Owner));
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FWalkerHeadFloodedEscapeDeactivateParams Params)
	{
		Super::OnDeactivated();

		if (Params.bSuccess)
		{
			// We've reached the end of escape spline
			HeadComp.bAtEndOfEscape = true;
			HeadComp.bHeadEscapeSuccess = true;
			iEscapeSpline++;
			Stump.Destroy(); // Destroy walker head, triggering end of boss fight
			UIslandWalkerHeadEffectHandler::Trigger_OnEndFinalSplineRunToDestruction(Cast<AHazeActor>(Owner));

			if (HeadComp.NeckCableOrigin != nullptr)
			{
				// Walker respawn points capability does not run ShouldDeactivate so needs to be blocked to deactivate
				// This never need to unblock!
				AHazeActor Walker = Cast<AHazeActor>(HeadComp.NeckCableOrigin.Owner);
				if (Walker != nullptr)
					Walker.BlockCapabilities(n"PlayerRespawning", this);
			}
		}
		else
		{
			// We've failed to damage head enough, throw off players
			HeadComp.bHeadShakeOffPlayers = true;
			HeadComp.bHeadEscapeSuccess = false;
			HeadComp.bAtEndOfEscape = false;
			Stump.ForceFieldComp.PowerUp();

			UIslandWalkerHeadEffectHandler::Trigger_OnCancelFinalSplineRunToDestruction(Cast<AHazeActor>(Owner));

			// Recover quite a lot of health in post swimming escape (should be uncommon that we fail to kill walker head here)
			Stump.Health = Settings.HeadSwimmingCrashHealthThreshold + Settings.HeadCrashRecoverHealth;
			Stump.HealthBarComp.ModifyHealth(Stump.Health);

			// Back to shark time!
			HeadComp.State = EIslandWalkerHeadState::Swimming;
			WalkerPhaseComp.Phase = EIslandWalkerPhase::Swimming; 	
		}
		for (UPerchPointComponent Perch : PerchPoints)
		{
			Perch.Enable(this);
		}
		BulletReflectComp.RemoveReflectBlockerForBothPlayers(this);

		if (bPlayersAreInvulnerable)
		{
			Game::Mio.UnblockCapabilities(n"Death", this);
			Game::Zoe.UnblockCapabilities(n"Death", this);
			bPlayersAreInvulnerable = false;
		}

		ClearCamera();
		Owner.ClearSettingsByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (ShouldRecover(Settings.HeadEscapeFloodedSpeed * DeltaTime))
			StartRecovering();

		TweakDamage();	

		if (!bIsMovingAlongSpline)
		{
			// Writhe in pain a short while, using root motion only for movement. Then take off towards spline.
			if (ActiveDuration > StartMovingTime)
				bIsMovingAlongSpline = true;
			UpdateCamera();
		}	
		else if (!bRecovering)
		{
			// Follow escape spline
			DestinationComp.MoveAlongSpline(Spline, Settings.HeadEscapeFloodedSpeed);
			if (!bHasDetachedPlayers && DestinationComp.IsAtSplineEnd(Spline, 400.0))
			{
				// Detach players before end of spline
				bHasDetachedPlayers = true;
				for (UPerchPointComponent Perch : PerchPoints)
				{
					Perch.Disable(this);
				}

				HeadComp.bAtEndOfEscape = true;
				HeadComp.bHeadEscapeSuccess = true;
			}
			UpdateCamera();
		}
		else
		{
			// Recovering and throwing off players, using root motion movement of throw off animation
			if ((ActiveDuration > ShakeOffPlayersTime) && HasControl())
				CrumbThrowOffPlayers();

			if (ActiveDuration > RecoverAllowMovementTime)
			{
				// Move towards arena center
				FVector Dest = Arena.ActorLocation;
				FVector DiveOffset = FVector(0.0, 0.0, -500.0);
				if (Arena.GetFloodedSubmergedDepth(Owner) > 400.0)
					DiveOffset = FVector::ZeroVector;
				DestinationComp.MoveTowardsIgnorePathfinding(Owner.ActorLocation + Owner.ActorForwardVector * 1000.0 + DiveOffset, Settings.HeadEscapeFloodedSpeed * 0.5);
				DestinationComp.RotateTowards(Dest);	
			}
		}

#if EDITOR
		if (Owner.bHazeEditorOnlyDebugBool)
		{
			Spline.DrawDebug(400.0, FLinearColor::Yellow, 5.0);
			Debug::DrawDebugSphere(Spline.GetWorldLocationAtSplineDistance(RecoverDistanceAlongSpline), 20.0, 4, FLinearColor::Red, 5.0);	
			if (bRecovering)
			{
				Debug::DrawDebugSphere(Game::Mio.FocusLocation, 50.0, 4, FLinearColor::Red );
				Debug::DrawDebugSphere(Game::Zoe.FocusLocation, 50.0, 4, FLinearColor::Red );
			}
		}
#endif		
	}

	UFUNCTION(CrumbFunction)
	void CrumbThrowOffPlayers()
	{
		ShakeOffPlayersTime = BIG_NUMBER;

		Game::Mio.UnblockCapabilities(n"Death", this);
		Game::Zoe.UnblockCapabilities(n"Death", this);
		bPlayersAreInvulnerable = false;
		HeadComp.bHeadEscapeSuccess = false;
		HeadComp.bHeadShakeOffPlayers = true;
		Arena.OnPhaseChange.Broadcast(EIslandWalkerPhase::ThrowOffPlayers);		
	}

	bool ShouldRecover(float NextMoveDistance)
	{
		if (bRecovering)
			return false;
		if (Stump.Health < 0.01)
			return false; // Damaged beyond repair
		if (DestinationComp.FollowSplinePosition.CurrentSpline != Spline)
			return false; // Don't recover unless we're following escape spline
		if (DestinationComp.FollowSplinePosition.CurrentSplineDistance + NextMoveDistance < RecoverDistanceAlongSpline)
			return false; // At this distance we check for recovery
		return true; 
	}

	void StartRecovering()
	{
		bRecovering = true;	

		for (UIslandWalkerHeadHatchInteractionComponent Interact : HatchInteracts)
		{
			Interact.State = EWalkerHeadHatchInteractionState::ThrownOff;
		}

		Owner.StopSlotAnimation(EHazeSlotAnimType::SlotAnimType_Default, 0.05);
		AnimComp.RequestFeature(FeatureTagWalker::HatchFlight,SubTagWalkerHatchFlight::ThrowOff, EBasicBehaviourPriority::Medium, this);
		UAnimSequence ThrowOffAnim = WalkerAnimComp.GetRequestedAnimation(FeatureTagWalker::HatchFlight, SubTagWalkerHatchFlight::ThrowOff);
		ShakeOffPlayersTime = ActiveDuration + ThrowOffAnim.GetAnimNotifyStateStartTime(UBasicAIActionAnimNotify);
		RecoverCompleteTime = ActiveDuration + ThrowOffAnim.GetScaledPlayLength() + Settings.HeadEscapePostAnimRecoverDuration;
		RecoverAllowMovementTime = ActiveDuration + ThrowOffAnim.GetAnimNotifyStateEndTime(UBasicAIActionAnimNotify);

		ClearCamera();
	}

	void UpdateCamera()
	{
		if (bRecovering)
			return;

		FHazePointOfInterestFocusTargetInfo Target;
		if (DestinationComp.FollowSplinePosition.CurrentSpline == Spline)
		{
			UHazeSplineComponent POISpline = Spline;
			float POIDistAlongSpline = DestinationComp.FollowSplinePosition.CurrentSplineDistance + 1000.0;
			Target.SetFocusToWorldLocation(POISpline.GetWorldLocationAtSplineDistance(POIDistAlongSpline));
		}
		else
		{
			Target.SetFocusToActor(Owner);
			Target.SetWorldOffset(Owner.ActorForwardVector * 2000.0);
		}
		FApplyPointOfInterestSettings POISettings;
		POISettings.BlendInAccelerationType = ECameraPointOfInterestAccelerationType::Medium;
		Game::Mio.ApplyPointOfInterest(this, Target, POISettings, Priority = EHazeCameraPriority::High);
		Game::Zoe.ApplyPointOfInterest(this, Target, POISettings, Priority = EHazeCameraPriority::High);

		UCameraSettings::GetSettings(Game::Mio).IdealDistance.Apply(600.0, this, 5.0);
		UCameraSettings::GetSettings(Game::Zoe).IdealDistance.Apply(600.0, this, 5.0);
		UCameraSettings::GetSettings(Game::Mio).PivotOffset.Apply(FVector(0.0, 0.0, 80.0), this, 5.0);
		UCameraSettings::GetSettings(Game::Zoe).PivotOffset.Apply(FVector(0.0, 0.0, 80.0), this, 5.0);

		AHazePlayerCharacter ControlPlayer = (Game::Mio.HasControl() ? Game::Mio : Game::Zoe);
		ControlPlayer.ApplyViewSizeOverride(this, EHazeViewPointSize::Fullscreen, EHazeViewPointBlendSpeed::Normal);

		if (bHasActivatedCamera)
			return;

		bHasActivatedCamera = true;

		Game::GetMio().PlayCameraShake(Arena.OnHeadCameraShake, this, 3.0);
		Game::GetZoe().PlayCameraShake(Arena.OnHeadCameraShake, this, 3.0);

		// Game::Mio.ApplyCameraSettings(Arena.OnHeadCameraSettings, 2.0, this, EHazeCameraPriority::Low);
		// Game::Zoe.ApplyCameraSettings(Arena.OnHeadCameraSettings, 2.0, this, EHazeCameraPriority::Low);

	}

	void ClearCamera()
	{
		Game::Mio.ClearPointOfInterestByInstigator(this);
		Game::Zoe.ClearPointOfInterestByInstigator(this);

		UCameraSettings::GetSettings(Game::Mio).IdealDistance.Clear(this);
		UCameraSettings::GetSettings(Game::Zoe).IdealDistance.Clear(this);
		UCameraSettings::GetSettings(Game::Mio).PivotOffset.Clear(this);
		UCameraSettings::GetSettings(Game::Zoe).PivotOffset.Clear(this);

		Game::Mio.ClearViewSizeOverride(this, EHazeViewPointBlendSpeed::Fast);
		Game::Zoe.ClearViewSizeOverride(this, EHazeViewPointBlendSpeed::Fast);

		Game::Mio.DeactivateCameraByInstigator(this);
		Game::Zoe.DeactivateCameraByInstigator(this);

		Game::Mio.StopCameraShakeByInstigator(this);
		Game::Zoe.StopCameraShakeByInstigator(this);

	}

	void TweakDamage()
	{
		UIslandWalkerSettings::SetHeadDamagePerImpact(Owner, Settings.HeadDamagePerImpactHatchPostSwim, this);
	}

	void SetupHurtAnims(int ListLength)
	{
		// Hurts anims are cosmetic, no need to replicate
		HeadComp.EscapeHurtIndex = -1;	
		HurtReactions = Cast<UFeatureAnimInstanceWalker>(Cast<AHazeCharacter>(Owner).Mesh.AnimInstance).HatchHitReactions; 
		int NumAnims = HurtReactions.NumAnimations;
		if ((NumAnims < 2) || (ListLength == 0))
		{
			HeadComp.EscapeHurtIndices.SetNumZeroed(NumAnims);
			return;
		}
		HeadComp.EscapeHurtIndices.SetNum(ListLength);
		HeadComp.EscapeHurtIndices[0] = Math::RandRange(0, NumAnims - 1);
		for (int i = 1; i < HeadComp.EscapeHurtIndices.Num(); i++)
		{
			// Never repeat anim (except at end/start)
			int Index = Math::RandRange(0, NumAnims - 2);
			if (Index >= HeadComp.EscapeHurtIndices[i - 1])
				Index++;
			HeadComp.EscapeHurtIndices[i] = Index;		
		}
	}

	UFUNCTION()
	private void OnTakeDamage(AHazePlayerCharacter Shooter, float RemainingHealth)
	{
		if (!IsActive())
			return;
		if (bRecovering)
			return;
		if (ActiveDuration < HurtAnimCooldown)
			return;
		if (HurtReactions.Sequences.Num() == 0)
			return;	
		int iHurt = (HeadComp.EscapeHurtIndex + 1) % HeadComp.EscapeHurtIndices.Num();	
		if (!HeadComp.EscapeHurtIndices.IsValidIndex(iHurt))
			return;

		// Play hurt reaction on walker head. Player interaction capability will play corresponding hurts for them.		
		HeadComp.EscapeHurtIndex = iHurt;
		HeadComp.EscapeHurtReactionStartTime = Time::GameTimeSeconds;
		FHazePlaySlotAnimationParams Params;
		Params.BlendTime = 0.05;
		Params.Animation = HurtReactions.Sequences[HeadComp.EscapeHurtIndices[iHurt]].Sequence;
		// Owner.PlaySlotAnimation(Params);	
		HurtAnimCooldown = ActiveDuration + Params.Animation.ScaledPlayLength * 0.75;
	}

	UFUNCTION()
	private void OnSkipIntro(EIslandWalkerPhase NewPhase)
	{
		if (NewPhase != EIslandWalkerPhase::Swimming)
			return;

		HeadComp.State = EIslandWalkerHeadState::Swimming;
		Stump.ForceFieldComp.PowerUp();
		Stump.Health = Settings.HeadSwimmingCrashHealthThreshold * 0.1 + Settings.HeadCrashHealthThreshold * 0.9;
		Stump.HealthBarComp.ModifyHealth(Stump.Health);
	}
};