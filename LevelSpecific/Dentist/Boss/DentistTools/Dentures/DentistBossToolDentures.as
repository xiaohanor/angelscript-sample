asset DentistBossDenturesStandardSettings of UMovementStandardSettings
{
	AutoFollowGround = EMovementAutoFollowGroundType::FollowWalkable;
}

asset DentistBossDenturesGravitySettings of UMovementGravitySettings
{
	GravityAmount = 6000.0;
}

event void EDentistBossDenturesEvent();
event void EDentistBossDenturesDamagedEvent(AHazePlayerCharacter PlayerInstigator);

class ADentistBossToolDentures : ADentistBossTool
{
	UPROPERTY(DefaultComponent)
	UHazeOffsetComponent MeshOffsetComp;

	UPROPERTY(DefaultComponent)
	UHazeMeshPoseDebugComponent PoseDebugComp;

	UPROPERTY(DefaultComponent)
	USpotLightComponent SpotlightComp;

	UPROPERTY(DefaultComponent, Attach = MeshOffsetComp)
	UHazeSkeletalMeshComponentBase SkelMesh;

	UPROPERTY(DefaultComponent, Attach = SkelMesh, AttachSocket = "Windup_Socket")
	USceneComponent WindupRoot;

	UPROPERTY(DefaultComponent, Attach = WindupRoot)
	UStaticMeshComponent WindupScrewMesh;

	UPROPERTY(DefaultComponent, Attach = SkelMesh, AttachSocket = "LowerJaw")
	UStaticMeshComponent WeakpointMeshComp;

	UPROPERTY(DefaultComponent, Attach = SkelMesh)
	USceneComponent BiteRoot;

	// UPROPERTY(DefaultComponent, Attach = WeakpointMeshComp)
	// UGodrayComponent WeakpointGodrayComp;

	// UPROPERTY(DefaultComponent, Attach = WeakpointMeshComp)
	// USpotLightComponent WeakpointSpotlightComp;

	UPROPERTY(DefaultComponent, Attach = WeakpointMeshComp)
	UDentistGroundPoundAutoAimComponent GroundPoundAutoAimComp;

	UPROPERTY(DefaultComponent, Attach = WeakpointMeshComp)
	UDentistBossWeakpointLocationComponent WeakpointLocationComp;

	UPROPERTY(DefaultComponent, Attach = WeakpointLocationComp)
	UNiagaraComponent WeakpointEffect;

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedActorPositionComponent CrumbActorPositionComp;
	default CrumbActorPositionComp.SyncRate = EHazeCrumbSyncRate::PlayerSynced;

	UPROPERTY(DefaultComponent)
	UHazeMovementComponent MoveComp;
	default MoveComp.bAllowUsingBoxCollisionShape = true;

	UPROPERTY(DefaultComponent, Attach = MeshOffsetComp)
	UBoxComponent BoxComp;
	default BoxComp.SetCollisionProfileName(n"EnemyCharacter");

	UPROPERTY(DefaultComponent, Attach = SkelMesh, AttachSocket = "UpperJaw")
	UInteractionComponent InteractComp;
	default InteractComp.MovementSettings.Type = EMoveToType::JumpTo;

	UPROPERTY(DefaultComponent)
	UHazeRequestCapabilityOnPlayerComponent RequestComp;
	default RequestComp.InitialStoppedPlayerCapabilities.Add(n"DentistBossToolDenturesInteractionCapability");

	UPROPERTY(DefaultComponent)
	UHazeMovablePlayerTriggerComponent MovablePlayerTrigger;

	UPROPERTY(DefaultComponent)
	UDentistToothMovementResponseComponent ToothResponseComp;
	default ToothResponseComp.OnDashImpact = EDentistToothDashImpactResponse::Disabled;

	UPROPERTY(DefaultComponent)
	UBasicAIHealthComponent HealthComp;

	UPROPERTY(DefaultComponent)
	UBasicAIHealthBarComponent HealthBarComp;

	UPROPERTY(DefaultComponent)
	UMovementImpactCallbackComponent MovementImpactCallbackComp;

	UPROPERTY(DefaultComponent)
	USceneComponent BiteButtonMashWidgetRoot;

	UPROPERTY()
	UHazeCameraSpringArmSettingsDataAsset CamSettings;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.bCanBeDisabled = false;
	default CapabilityComp.DefaultCapabilityClasses.Add(UDentistBossToolDenturesIdleMovementCapability);
	default CapabilityComp.DefaultCapabilityClasses.Add(UDentistBossToolDenturesJumpCapability);
	default CapabilityComp.DefaultCapabilityClasses.Add(UDentistBossToolDenturesSwitchTargetCapability);
	default CapabilityComp.DefaultCapabilityClasses.Add(UDentistBossToolDenturesHitPlayerCapability);
	default CapabilityComp.DefaultCapabilityClasses.Add(UDentistBossToolDenturesHealthBarCapability);
	default CapabilityComp.DefaultCapabilityClasses.Add(UDentistBossToolDenturesJumpRechargeCapability);
	default CapabilityComp.DefaultCapabilityClasses.Add(UDentistBossToolDenturesWindupScrewRotateCapability);
	default CapabilityComp.DefaultCapabilityClasses.Add(UDentistBossToolDenturesWindupScrewSpawnCapability);
	default CapabilityComp.DefaultCapabilityClasses.Add(UDentistBossToolDenturesHitShakeCapability);
	default CapabilityComp.DefaultCapabilityClasses.Add(UDentistBossToolDenturesDeathCapability);

	default CapabilityComp.DefaultCapabilityClasses.Add(UDentistBossToolDenturesRidingControlCapability);
	default CapabilityComp.DefaultCapabilityClasses.Add(UDentistBossToolDenturesRidingRotationCapability);
	default CapabilityComp.DefaultCapabilityClasses.Add(UDentistBossToolDenturesRidingJumpCapability);
	default CapabilityComp.DefaultCapabilityClasses.Add(UDentistBossToolDenturesRidingBiteFingersCapability);
	default CapabilityComp.DefaultCapabilityClasses.Add(UDentistBossToolDenturesRidingBiteFingersInputCapability);
	default CapabilityComp.DefaultCapabilityClasses.Add(UDentistBossToolDenturesRidingFocusTargetCapability);
	default CapabilityComp.DefaultCapabilityClasses.Add(UDentistBossToolDenturesRidingIdleMovementCapability);
	default CapabilityComp.DefaultCapabilityClasses.Add(UDentistBossToolDenturesRidingCameraOffsetCapability);
	
	default CapabilityComp.DefaultCapabilityClasses.Add(UDentistBossMovementFollowCakeCapability);

	UPROPERTY(DefaultComponent)
	UTemporalLogTransformLoggerComponent TransformTemporalLogComp;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedActorComp;
	default ListedActorComp.bDelistWhileActorDisabled = false;

	UPROPERTY(EditDefaultsOnly, Category = "Setup")
	UBasicAIHealthBarSettings HealthBarSettings;

	EDentistBossDenturesEvent OnJump;
	EDentistBossDenturesDamagedEvent OnDamagedByDash;

	bool bIsAttachedToJaw = true;
	bool bHasLandedOnGround = false;
	bool bHasHitTarget = false;
	bool bShouldTraceForPlayerInFront = false;
	bool bLastTimeDestroyedWasBecauseOfGrabberBeingDestroyed = false;
	bool bIsStaggered = false;
	bool bIsRechargingJumps = false;
	bool bIsBitingLeftHand = false;
	bool bIsBitingRightHand = false;
	bool bHasFinishedSpawning = false;
	bool bExplodeEventTriggered = false;
	
	float LastTimeLandedOnGround = 0.0;
	float LastTimeGroundPounded = 0.0;
	float TimeLastJumpStarted = 0.0;
	int JumpsSinceRecharge = 0;
	TOptional<AHazePlayerCharacter> ControllingPlayer;
	TOptional<AHazePlayerCharacter> TargetPlayer;
	TOptional<AHazePlayerCharacter> PlayerJumpingTo;
	TPerPlayer<bool> IsStandingOnDentures;
	default IsStandingOnDentures[EHazePlayer::Mio] = false;
	default IsStandingOnDentures[EHazePlayer::Zoe] = false;

	// ANIM
	bool bIsJumping = false;
	bool bBiteInput = false;
	bool bFallingOverJump = false;
	bool bDamaged = false;
	bool bIsRotatingBack = false;

	TInstigated<bool> EyesSpringinessEnabled;
	default EyesSpringinessEnabled.DefaultValue = true;

	UDentistBossSettings Settings;

	const FName JawSocketName = n"TeethAttach";
	const FName ScrewSocketName = n"Windup_Socket";

	default bActive = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		MoveComp.SetupShapeComponent(BoxComp);
		PlaceDenturesInJaw();
		Settings = UDentistBossSettings::GetSettings(Dentist);

		ApplyDefaultSettings(DentistBossDenturesStandardSettings);
		ApplyDefaultSettings(DentistBossDenturesGravitySettings);
		ApplyDefaultSettings(HealthBarSettings);
		HealthBarComp.SetHealthBarEnabled(false);

		InteractComp.Disable(this);

		for(auto Player : Game::Players)
		{
			MoveComp.AddMovementIgnoresActor(this, Player);
		}

		InteractComp.OnInteractionStarted.AddUFunction(this, n"OnInteractStarted");
		InteractComp.OnInteractionStopped.AddUFunction(this, n"OnInteractStopped");	

		ToothResponseComp.OnGroundPoundedOn.AddUFunction(this, n"OnGroundPoundedOn");

		MovementImpactCallbackComp.OnGroundImpactedByPlayer.AddUFunction(this, n"OnPlayerLandedOnDentures");
		MovementImpactCallbackComp.OnGroundImpactedByPlayerEnded.AddUFunction(this, n"OnPlayerLeftDentures");

		ToggleWeakpointLight(false);

		JoinTeam(AITeams::Default);
	}

	UFUNCTION()
	private void OnPlayerLandedOnDentures(AHazePlayerCharacter Player)
	{
		IsStandingOnDentures[Player] = true;
	}

	UFUNCTION()
	private void OnPlayerLeftDentures(AHazePlayerCharacter Player)
	{
		IsStandingOnDentures[Player] = false;
	}

	UFUNCTION()
	private void OnGroundPoundedOn(AHazePlayerCharacter GroundPoundPlayer, FHitResult Impact)
	{
		if(Impact.Component != WeakpointMeshComp)
			return;

		HealthComp.TakeDamage(1.0 / Settings.DenturesTimesHitToDie, EDamageType::Impact, GroundPoundPlayer);

		FDentistBossEffectHandlerOnDenturesGroundPoundedParams GroundPoundedParams;
		GroundPoundedParams.HitLocation = Impact.ImpactPoint;
		GroundPoundedParams.HitNormal = Impact.ImpactNormal;
		UDentistBossEffectHandler::Trigger_OnDenturesGroundPounded(Dentist, GroundPoundedParams);

		OnDamagedByDash.Broadcast(GroundPoundPlayer);

		if(!Settings.bRefreshStaggerOnHit
		&& bIsStaggered)
			return;
			
		LastTimeGroundPounded = Time::GameTimeSeconds;
	}

	UFUNCTION()
	private void OnInteractStarted(UInteractionComponent InteractionComponent,
	                               AHazePlayerCharacter Player)
	{
		RequestComp.StartInitialSheetsAndCapabilities(Player, this);
		PlayerJumpingTo.Set(Player);
		Player.ApplyCameraSettings(CamSettings, 2.0, this, EHazeCameraPriority::VeryHigh);
	}

	UFUNCTION()
	private void OnInteractStopped(UInteractionComponent InteractionComponent,
	                               AHazePlayerCharacter Player)
	{
		RequestComp.StopInitialSheetsAndCapabilities(Player, this);
		Player.ClearCameraSettingsByInstigator(this, 2.0);
	}

	void Activate() override
	{
		Super::Activate();

		MoveComp.ApplyFollowEnabledOverride(this, EMovementFollowEnabledStatus::FollowEnabled, EInstigatePriority::Normal);
	}

	void Deactivate() override
	{
		Super::Deactivate();
	}

	void GetDestroyed() override
	{
		Super::GetDestroyed();

		for(auto Player : Game::Players)
		{
			Player.RemoveTutorialPromptByInstigator(Dentist);
		}

		Deactivate();
	}

	void ExplodeWithArm()
	{
		if(ControllingPlayer.IsSet())
		{
			ControllingPlayer.Value.DetachFromActor(EDetachmentRule::KeepWorld);
			ControllingPlayer.Value.MeshOffsetComponent.ResetOffsetWithLerp(this, 0.);
		}
		
		BiteButtonMashWidgetRoot.AttachToComponent(RootComponent, NAME_None, EAttachmentRule::KeepWorld);

		FDentistBossEffectHandlerOnDenturesDestroyedWithGrabberParams DenturesEffectParams;
		DenturesEffectParams.Dentures = this;
		UDentistBossEffectHandler::Trigger_OnDenturesDestroyedWithGrabber(Dentist, DenturesEffectParams);

		bExplodeEventTriggered = true;
		bLastTimeDestroyedWasBecauseOfGrabberBeingDestroyed = true;

		GetDestroyed();
	}

	void Reset() override
	{
		Super::Reset();

		HealthComp.Reset();

		FVector PreviousPlayerLocation;
		if(ControllingPlayer.IsSet())
			PreviousPlayerLocation = ControllingPlayer.Value.ActorLocation;

		PlaceDenturesInJaw();

		if(ControllingPlayer.IsSet())
			ControllingPlayer.Value.ActorLocation = PreviousPlayerLocation;

		bHasLandedOnGround = false;
		bLastTimeDestroyedWasBecauseOfGrabberBeingDestroyed = false;
		Dentist.bDenturesFellDown = false;
		
		MoveComp.ClearFollowEnabledOverride(this);

		ControllingPlayer.Reset();

		bIsBitingLeftHand = false;
		bIsBitingRightHand = false;
		bBiteInput = false;
		bIsJumping = false;
		bHasFinishedSpawning = false;
		bIsRotatingBack = false;
		Dentist.bDenturesDestroyedHand = false;
		Dentist.bDenturesAttachedLeftHand = false;
		Dentist.bDenturesAttachedRightHand = false;

		SkelMesh.ResetAllAnimation(true);
	}

	float GetEnergyAlpha() const property
	{
		if(Settings == nullptr)
			return 1.0;
		return (float(Settings.DenturesJumpsBeforeRecharge) - float(JumpsSinceRecharge)) / float(Settings.DenturesJumpsBeforeRecharge);
	}

	void PlaceDenturesInJaw()
	{
		if(Dentist == nullptr)
			Dentist = TListedActors<ADentistBoss>().Single;
		
		AttachToComponent(Dentist.SkelMesh, JawSocketName, EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, EAttachmentRule::KeepWorld, false);
		bIsAttachedToJaw = true;
		EyesSpringinessEnabled.Apply(false, this, EInstigatePriority::High);
		WindupScrewMesh.AddComponentVisualsBlocker(this);
	}

	bool IsRidingDentures(AHazePlayerCharacter Player) const
	{
		if(!ControllingPlayer.IsSet())
			return false;

		return ControllingPlayer.Value == Player;
	}

	bool IsBitingHand() const
	{
		if(bIsBitingLeftHand)
			return true;

		if(bIsBitingRightHand)
			return true;

		return false;
	}

	bool HandGotDestroyed() const
	{
		if(bIsBitingLeftHand)
		{
			if(Dentist.LeftHandHealthComp.IsDead())
				return true;
			
			return false;
		}
		if(bIsBitingRightHand)
		{
			if(Dentist.RightHandHealthComp.IsDead())
				return true;

			return false;
		}
		else 
			return false;
	}

	void KnockAwayPlayersStandingOnDentures()
	{
		for(auto Player : Game::Players)
		{
			if(!IsStandingOnDentures[Player])
				continue;
			FVector PlayerImpulse = FVector::UpVector * Settings.DenturesPlayerStandingOnImpulseUpwards;
			Player.AddMovementImpulse(PlayerImpulse);
		}
	}

	void ToggleWeakpointLight(bool bToggleOn)
	{
		if(bToggleOn)
		{
			WeakpointEffect.Activate();
			// WeakpointGodrayComp.SetGodrayOpacity(1.0);
			// WeakpointSpotlightComp.RemoveComponentVisualsBlocker(this);
		}
		else
		{
			WeakpointEffect.Deactivate();
			// WeakpointGodrayComp.SetGodrayOpacity(0.0);
			// WeakpointSpotlightComp.AddComponentVisualsBlocker(this);
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		TEMPORAL_LOG(this)
			.Sphere("Wind up Screw Location", WindupScrewMesh.WorldLocation, 50, FLinearColor::Blue, 10)
			.Value("Attach Parent", GetAttachParentActor())
		;

		auto TempLog = TEMPORAL_LOG(this, "Animation Variables")
			.Value("Dentures Placed In Jaw", bIsAttachedToJaw)
			.Value("IsJumping" , bIsJumping)
			.Value("BiteInput" , bBiteInput)
			.Value("FallingOverJump" , bFallingOverJump)
			.Value("EyesSpringinessEnabled" , EyesSpringinessEnabled.Get())
			.Value("IsRotatingBack", bIsRotatingBack)
		;
	}

	void TriggerBiteEvent()
	{
		FDentistBossEffectHandlerOnDenturesBiteParams Params;
		Params.BiteRoot = BiteRoot;
		Params.Dentures = this;

		UDentistBossEffectHandler::Trigger_OnDenturesBite(Dentist, Params);
	}
};