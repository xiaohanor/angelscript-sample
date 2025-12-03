class UIslandWalkerHeadEscapeBehaviour : UBasicBehaviour
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
	bool bSwimmingPrepared;
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
		if (!Arena.EscapeOrder.IsValidIndex(iEscapeSpline))
			return false;
		if (Arena.EscapeOrder[iEscapeSpline].RecoverSpline == nullptr)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		// Normally this will deactivate due to level BP starting phase3->phase4 transition cutscene 
		if (Super::ShouldDeactivate())
			return true;
		if (ActiveDuration > Settings.HeadEscapeSwitchCameraDuration + 20.0)
			return true; // We hit backup time
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();

		// We can take damage, but should show as ignoring since you only shoot into hatch
		// ShowAllowDamage is called after cutscene following this behaviour (the only ways 
		// you can deactivate this is by going into next phase or destroying the walker)
		Stump.ShowIgnoreDamage(); 

		if (!Arena.EscapeOrder.IsValidIndex(iEscapeSpline))
		{
			Cooldown.Set(10.0);
			return;
		}

		// Move along recover spline
		Spline = Arena.EscapeOrder[iEscapeSpline].RecoverSpline.Spline;
		HeadComp.HeadEscapeStartDistanceAlongSpline = Spline.GetClosestSplineDistanceToWorldLocation(Owner.ActorLocation);

		bHasDetachedPlayers = false;
		HeadComp.bAtEndOfEscape = false;
		HeadComp.bHeadEscapeSuccess = false;
		Stump.ForceFieldComp.PowerDown();
		BulletReflectComp.AddReflectBlockerForBothPlayers(this);
		
		bSwimmingPrepared = false;

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
		UIslandWalkerHeadEffectHandler::Trigger_OnStartSplineRunToSwimmingPhase(Cast<AHazeActor>(Owner));
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();

		// Time to progress to swimming phase, regardless of whether we've been damaged enough or not
		HeadComp.bHeadShakeOffPlayers = false;
		HeadComp.bHeadEscapeSuccess = true; // Cannot fail; we always progress to swimming phase after initial phase escape
		HeadComp.bAtEndOfEscape = false;
		Stump.ForceFieldComp.PowerUp();

		UIslandWalkerHeadEffectHandler::Trigger_OnEndSplineRunToSwimmingPhase(Cast<AHazeActor>(Owner));

		HeadComp.State = EIslandWalkerHeadState::Swimming;
		WalkerPhaseComp.Phase = EIslandWalkerPhase::Swimming; 	

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
		for (UIslandWalkerHeadHatchInteractionComponent Interact : HatchInteracts)
		{
			Interact.State = EWalkerHeadHatchInteractionState::ThrownOff;
		}

		ClearCamera();
		Owner.ClearSettingsByInstigator(this);

		// Stop any ongoing hurts
		Owner.StopSlotAnimation(EHazeSlotAnimType::SlotAnimType_Default, 0.05);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (HasControl() && !bSwimmingPrepared && (ActiveDuration > Settings.HeadEscapeSwitchCameraDuration))
			CrumbPrepareSwimming();

		TweakDamage();	

		if (!bIsMovingAlongSpline)
		{
			// Writhe in pain a short while, using root motion only for movement. Then take off towards spline.
			if (ActiveDuration > StartMovingTime)
				bIsMovingAlongSpline = true;
		}	
		else 
		{
			// Follow spline
			DestinationComp.MoveAlongSpline(Spline, Settings.HeadEscapeSpeed);
		}

		UpdateCamera();

#if EDITOR
		if (Owner.bHazeEditorOnlyDebugBool)
		{
			Spline.DrawDebug(400.0, FLinearColor::Yellow, 5.0);
			if (DestinationComp.FollowSplinePosition.CurrentSpline == nullptr)
				Debug::DrawDebugLine(Owner.ActorLocation, Spline.GetWorldLocationAtSplineDistance(HeadComp.HeadEscapeStartDistanceAlongSpline), FLinearColor::Green, 3.0);
			if (bSwimmingPrepared)
			{
				Debug::DrawDebugSphere(Game::Mio.FocusLocation, 50.0, 4, FLinearColor::Red );
				Debug::DrawDebugSphere(Game::Zoe.FocusLocation, 50.0, 4, FLinearColor::Red );
			}
		}
#endif		
	}

	UFUNCTION(CrumbFunction)
	void CrumbPrepareSwimming()
	{
		bSwimmingPrepared = true;	

		Game::Mio.UnblockCapabilities(n"Death", this);
		Game::Zoe.UnblockCapabilities(n"Death", this);
		bPlayersAreInvulnerable = false;
/*
		if (Arena.PhaseTransitionCameraActors.Num() != 0)
		{
			// Find the camera closest to us on the other long side of pool
			FVector WantedCameraLoc = Arena.ActorTransform.InverseTransformPosition(Owner.ActorLocation);
			WantedCameraLoc.Y = -Math::Sign(WantedCameraLoc.Y) * 2000;
			WantedCameraLoc.Z = 0;
			WantedCameraLoc = Arena.ActorTransform.TransformPosition(WantedCameraLoc);

			float BestDist = BIG_NUMBER;
			AHazeCameraActor BestCamera = Arena.PhaseTransitionCameraActors[0];
			for (AHazeCameraActor Camera : Arena.PhaseTransitionCameraActors)
			{
				float Dist = Camera.ActorLocation.Dist2D(WantedCameraLoc);
				if (Dist > BestDist)
					continue;
				BestDist = Dist;
				BestCamera = Camera;
			}

			Game::Mio.ActivateCamera(BestCamera, 2.0, this);
			Game::Zoe.ActivateCamera(BestCamera, 2.0, this);
		}
*/
		Game::Mio.ClearCameraSettingsByInstigator(this);
		Game::Zoe.ClearCameraSettingsByInstigator(this);
		Game::Mio.ApplyCameraSettings(Arena.OnHeadCloseCameraSettings, 4.0, this, EHazeCameraPriority::VeryHigh);


		Arena.OnPhaseChange.Broadcast(EIslandWalkerPhase::ReadyForSwimming);		
	}



	void UpdateCamera()
	{
		if (bSwimmingPrepared)
			return;
		
		FHazePointOfInterestFocusTargetInfo Target;
		if (DestinationComp.FollowSplinePosition.CurrentSpline == Spline)
		{
			UHazeSplineComponent POISpline = Spline;
			float POIDistAlongSpline = DestinationComp.FollowSplinePosition.CurrentSplineDistance + 2000.0;
			Target.SetFocusToWorldLocation(POISpline.GetWorldLocationAtSplineDistance(POIDistAlongSpline));
		}
		else
		{
			Target.SetFocusToActor(Owner);
			// Target.SetWorldOffset(Owner.ActorForwardVector * 2000.0);
			Target.SetWorldOffset(Owner.ActorForwardVector * 4000.0);
		}
		FApplyPointOfInterestSettings POISettings;
		POISettings.BlendInAccelerationType = ECameraPointOfInterestAccelerationType::Slow;
		Game::Mio.ApplyPointOfInterest(this, Target, POISettings, Priority = EHazeCameraPriority::High);
		Game::Zoe.ApplyPointOfInterest(this, Target, POISettings, Priority = EHazeCameraPriority::High);

		/*UCameraSettings::GetSettings(Game::Mio).IdealDistance.Apply(800.0, this, 8.0);
		UCameraSettings::GetSettings(Game::Zoe).IdealDistance.Apply(800.0, this, 8.0);
		UCameraSettings::GetSettings(Game::Mio).PivotOffset.Apply(FVector(0.0, 0.0, 80.0), this, 3.0);
		UCameraSettings::GetSettings(Game::Zoe).PivotOffset.Apply(FVector(0.0, 0.0, 80.0), this, 3.0);*/

		
		if (bHasActivatedCamera)
			return;

		bHasActivatedCamera = true;

		Game::GetMio().PlayCameraShake(Arena.OnHeadCameraShake, this, 2.0);
		Game::GetZoe().PlayCameraShake(Arena.OnHeadCameraShake, this, 2.0);

		Game::GetMio().BlockCapabilities(n"ContextualMoves", this);
		Game::GetZoe().BlockCapabilities(n"ContextualMoves", this);

		Game::Mio.ApplyCameraSettings(Arena.OnHeadCameraSettings, 6.0, this, EHazeCameraPriority::High);
		Game::Zoe.ApplyCameraSettings(Arena.OnHeadCameraSettings, 6.0, this, EHazeCameraPriority::High);

		Timer::SetTimer(this, n"SetWalkerHeadFullScreen", 2.7);

	}

	UFUNCTION()
	void SetWalkerHeadFullScreen()
	{
		AHazePlayerCharacter ControlPlayer = (Game::Mio.HasControl() ? Game::Mio : Game::Zoe);
		ControlPlayer.ApplyViewSizeOverride(this, EHazeViewPointSize::Fullscreen, EHazeViewPointBlendSpeed::Normal);
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

		Game::Mio.ClearCameraSettingsByInstigator(this);
		Game::Zoe.ClearCameraSettingsByInstigator(this);

		Game::Mio.StopCameraShakeByInstigator(this);
		Game::Zoe.StopCameraShakeByInstigator(this);

		Game::GetMio().UnblockCapabilities(n"ContextualMoves", this);
		Game::GetZoe().UnblockCapabilities(n"ContextualMoves", this);
	}

	void TweakDamage()
	{
		// We should not fall below half of second health bar segment at this stage
		float MinHealth = (Settings.HeadCrashHealthThreshold + Settings.HeadSwimmingCrashHealthThreshold) * 0.5;
		float Span = (Settings.HeadCrashHealthThreshold - Settings.HeadSwimmingCrashHealthThreshold) * 0.6;
		float Damage = Settings.HeadDamagePerImpactHatchInitial;
		if (Stump.Health < MinHealth + Span)
			Damage *= Math::GetMappedRangeValueClamped(FVector2D(MinHealth + Span, MinHealth + Span * 0.1), FVector2D(0.25, 0.01), Stump.Health); 
		UIslandWalkerSettings::SetHeadDamagePerImpact(Owner, Damage, this);
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
		if (bSwimmingPrepared)
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
		//Owner.PlaySlotAnimation(Params);	
		HurtAnimCooldown = ActiveDuration + Params.Animation.ScaledPlayLength * 0.75;
	}

	UFUNCTION()
	private void OnSkipIntro(EIslandWalkerPhase NewPhase)
	{
		// Nothing needed for non-swimming escape, swimming escape intro skip is handled in it's own capability.
	}
};
