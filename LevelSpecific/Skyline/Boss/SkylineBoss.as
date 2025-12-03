asset SkylineBossSheet of UHazeCapabilitySheet
{
	Capabilities.Add(USkylineBossAssembleCompoundCapability);
	Capabilities.Add(USkylineBossCombatCompoundCapability);
	Capabilities.Add(USkylineBossPendingDownCompoundCapability);
	Sheets.Add(SkylineBossFallSheet);
	Sheets.Add(SkylineBossDownSheet);
	Capabilities.Add(USkylineBossRiseCompoundCapability);
	Capabilities.Add(USkylineBossDeadCompoundCapability);
	Capabilities.Add(USkylineBossRocketBarrageLaunchingCapability);
	Capabilities.Add(USkylineBossCutsceneCapability);
	Capabilities.Add(USkylineBossPlayerRespawnCapability);
};

enum ESkylineBossState
{
	Assemble,
	Combat,
	PendingDown,
	Fall,
	Down,
	Rise,
	Dead,
	None
};

enum ESkylineBossLeg
{
	Left = 0,
	Right = 1,
	Center = 2,
	MAX UMETA(Hidden),
};

enum ESkylineBossFallDirection
{
	None,
	FromLeft,
	FromRight,
	FromCenter
};

enum ESkylineBossPhase
{
	First,
	Second
};

struct FSkylineBossMovementData
{
	TArray<USkylineBossFootTargetComponent> FootTargets;
	ASkylineBossSpline SplineActor = nullptr;
	ASkylineBossSplineHub ToHub = nullptr;
	ASkylineBossSplineHub FromHub = nullptr;
	bool bIsReversed = false;

	TArray<ESkylineBossLeg> LegPlacementOrder;

	int LegPlacementOrderTransitionIndex = -1;
	int BodyRotationTransitionIndex = -1;
	TArray<ESkylineBossLeg> NextLegPlacementOrder;
	ASkylineBossSpline NextSplineActor = nullptr;
	bool bNextIsReversed = false;

	float StepAlpha = 0.0;
	int CurrentStep = 0;
	bool bIsStepping = false;
	

	bool IsValid() const
	{
		return FootTargets.Num() != 0;
	}

	bool IsRebasing() const
	{
		return CurrentStep >= FootTargets.Num() - 2;
	}

	bool IsCompleted() const
	{
		return CurrentStep >= FootTargets.Num() - 1;
	}

#if EDITOR
	void LogToTemporalLog(FTemporalLog& TemporalLog, FString Category) const
	{
		TemporalLog.Value(f"{Category};Spline Actor", SplineActor);
		TemporalLog.Value(f"{Category};To Hub", ToHub);
		TemporalLog.Value(f"{Category};From Hub", FromHub);
		TemporalLog.Value(f"{Category};Is Reversed", bIsReversed);
		TemporalLog.Value(f"{Category};Step Alpha", StepAlpha);
		TemporalLog.Value(f"{Category};Current Step", CurrentStep);
		TemporalLog.Value(f"{Category};Is Stepping", bIsStepping);
		TemporalLog.Value(f"{Category};Is Valid", IsValid());
		TemporalLog.Value(f"{Category};Is Rebasing", IsRebasing());
		TemporalLog.Value(f"{Category};Is Completed", IsCompleted());
	}
#endif
}

struct FSkylineBossAnimData
{
	bool bFiringRockets;
	bool bFiringLaser;
	FVector LaserLocation;
	ESkylineBossFallDirection FallDirection;
}

event void FSkylineBossTraversalBeginSignature(ASkylineBossSplineHub FromHub, ASkylineBossSplineHub ToHub);
event void FSkylineBossTraversalEndSignature(ASkylineBossSplineHub FromHub, ASkylineBossSplineHub ToHub);
event void FSkylineBossFootPlacedSignature(ASkylineBossLeg Leg);
event void FSkylineBossFootLiftedSignature(ASkylineBossLeg Leg);
event void FSkylineBossSignature();
event void FSkylineBossOnBeginFallSignature(ASkylineBossSplineHub FallDownHub);

namespace ASkylineBoss
{
	ASkylineBoss Get()
	{
		return TListedActors<ASkylineBoss>().GetSingle();
	}
};

/**
 * AKA Tripod Boss
 */
UCLASS(Abstract)
class ASkylineBoss : AHazeActor
{
	access Compounds = private, USkylineBossCompoundCapability(inherited);

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeSkeletalMeshComponentBase Mesh;
	default Mesh.VisibilityBasedAnimTickOption = EVisibilityBasedAnimTickOption::AlwaysTickPoseAndRefreshBones;

	UPROPERTY(DefaultComponent, Attach = Mesh, AttachSocket = Body)
	USkylineBossRocketBarrageComponent RocketBarrageComp;

	UPROPERTY(DefaultComponent,  Attach = Mesh, AttachSocket = LeftHatchet)
	USceneComponent LeftRampPivot;

	UPROPERTY(DefaultComponent,  Attach = Mesh, AttachSocket = RightHatchet)
	USceneComponent RightRampPivot;

	UPROPERTY(DefaultComponent, Attach = LeftRampPivot)
	UGravityBikeFreeHalfPipeTriggerComponent LeftHalfPipeTrigger;
	default LeftHalfPipeTrigger.JumpToTriggerRef.ComponentProperty = n"RightHalfPipeTrigger";

	UPROPERTY(DefaultComponent, Attach = LeftRampPivot)
	UGravityBikeFreeAutoSteerTargetComponent LeftAutoSteerTargetComp;

	UPROPERTY(DefaultComponent, Attach = RightRampPivot)
	UGravityBikeFreeHalfPipeTriggerComponent RightHalfPipeTrigger;
	default RightHalfPipeTrigger.JumpToTriggerRef.ComponentProperty = n"LeftHalfPipeTrigger";

	UPROPERTY(DefaultComponent, Attach = RightRampPivot)
	UGravityBikeFreeAutoSteerTargetComponent RightAutoSteerTargetComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent HeadPivot;

	UPROPERTY(DefaultComponent, Attach = Mesh, AttachSocket = Body)
	UHazeSphereCollisionComponent BodyCollisionSphere;

	UPROPERTY(DefaultComponent, Attach = Mesh, AttachSocket = Core)
	USphereComponent CoreCollision;
	default CoreCollision.bGenerateOverlapEvents = false;

	UPROPERTY(DefaultComponent, Attach = Mesh, AttachSocket = Core)
	USceneComponent CoreVisual;

	UPROPERTY(DefaultComponent, Attach = Mesh, AttachSocket = Core)
	UGravityBikeWeaponTargetableComponent CoreAutoAimTargetComponent;
	default CoreAutoAimTargetComponent.AutoAimMaxAngle = 15.0;

	UPROPERTY(DefaultComponent, Attach = CoreAutoAimTargetComponent)
	UTargetableOutlineComponent OutlineComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent LegsPivot;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComponent;
	default CapabilityComponent.DefaultSheets.Add(SkylineBossSheet);

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedActorPositionComponent SyncedActorPositionComp;
	default SyncedActorPositionComp.SyncDetailLevel = EHazeActorPositionSyncDetailLevel::TransformOnly;
	default SyncedActorPositionComp.SyncRate = EHazeCrumbSyncRate::Standard;

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedRotatorComponent SyncedHeadPivotRotationComp;
	default SyncedHeadPivotRotationComp.SyncRate = EHazeCrumbSyncRate::Standard;

	UPROPERTY(DefaultComponent)
	UGravityBikeWeaponProjectileResponseComponent ProjectileResponseComponent;

	UPROPERTY(DefaultComponent, Attach = HeadPivot)
	UHazeDecalComponent ShadowDecal;

	UPROPERTY(DefaultComponent)
	UBasicAIHealthComponent HealthComponent;
	default HealthComponent.MaxHealth = 130.0;

	UPROPERTY(DefaultComponent)
	UBasicAIHealthBarComponent HealthBarComponent;

	UPROPERTY(DefaultComponent)
	USkylineBossHalfPipeJumpComponent HalfPipeJumpComponent;

	UPROPERTY(DefaultComponent)
	USkylineBossFootStompComponent FootStompComponent;

	UPROPERTY(DefaultComponent)
	USkylineBossCoreComponent CoreComponent;

	UPROPERTY(DefaultComponent, Attach = CoreVisual)
	UHazeSphereComponent CoreHazeSphere;

	UPROPERTY(DefaultComponent)
	USkylineBossHatchComponent HatchComponent;

	UPROPERTY(DefaultComponent)
	USkylineBossFootMovementComponent FootMoveComp;

	UPROPERTY(DefaultComponent)
	USkylineBossCenterViewTargetComponent CenterViewTargetComp;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedActorComp;
	default ListedActorComp.bDelistWhileActorDisabled = false;

	UPROPERTY(DefaultComponent)
	USkylineBossTankDeathDamageComponent DeathDamageComp;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UTemporalLogTransformLoggerComponent TransformLoggerComp;

	UPROPERTY(DefaultComponent)
	UHazeMeshPoseDebugComponent MeshPoseDebugComp;

	UPROPERTY(DefaultComponent)
	UMovementInstigatorLogComponent MovementInstigatorComp;
#endif

	UPROPERTY(EditInstanceOnly)
	ASplineActor RespawnSpline;

	UPROPERTY(EditAnywhere)
	UMaterialParameterCollection GlobalParametersVFX;

	UPROPERTY(EditAnywhere)
	AActor ConstraintRadiusOrigin;

	UPROPERTY(EditDefaultsOnly)
	USkylineBossSettings DefaultSettings;

	UPROPERTY(EditDefaultsOnly)
	USkylineBossSettings PendingDownSettings;
	
	UPROPERTY(EditDefaultsOnly)
	TArray<FName> LegMaterialSlots;
	default LegMaterialSlots.Add(n"LeftFoot_mat");
	default LegMaterialSlots.Add(n"RightFoot_mat");
	default LegMaterialSlots.Add(n"BackFoot_mat");

	// Called when the boss starts moving between two hubs along a spline.
	UPROPERTY(Category = "Response", Meta = (BPCannotCallEvent))
	FSkylineBossTraversalBeginSignature OnTraversalBegin;
	// Called when the boss finishes moving to a hub, including rebasing.
	UPROPERTY(Category = "Response", Meta = (BPCannotCallEvent))
	FSkylineBossTraversalEndSignature OnTraversalEnd;
	// Called when the boss finishes placing a foot.
	UPROPERTY(Category = "Response", Meta = (BPCannotCallEvent))
	FSkylineBossFootPlacedSignature OnFootPlaced;
	// Called when the boss finishes placing a foot.
	UPROPERTY(Category = "Response", Meta = (BPCannotCallEvent))
	FSkylineBossFootLiftedSignature OnFootLifted;

	UPROPERTY(Category = "Event", Meta = (BPCannotCallEvent))
	FSkylineBossOnBeginFallSignature OnBeginFall;

	UPROPERTY(Category = "Event", Meta = (BPCannotCallEvent))
	FSkylineBossSignature OnFall;

	UPROPERTY(Category = "Event", Meta = (BPCannotCallEvent))
	FSkylineBossSignature OnCloseHatch;

	UPROPERTY(Category = "Event", Meta = (BPCannotCallEvent))
	FSkylineBossSignature OnBeginRise;

	UPROPERTY(Category = "Event", Meta = (BPCannotCallEvent))
	FSkylineBossSignature OnRise;

	UPROPERTY(Category = "Event", Meta = (BPCannotCallEvent))
	FSkylineBossSignature OnDie;

	private ESkylineBossState State = ESkylineBossState::None;
	private float StartStateTime = 0;

	private ESkylineBossPhase Phase = ESkylineBossPhase::First;
	private float StartPhaseTime = 0;

	FSkylineBossAnimData AnimData;

	FVector AngularVelocity;
	
	TInstigated<AHazeActor> LookAtTarget;
	TArray<USkylineBossLegComponent> LegComponents;

	UPROPERTY(NotVisible, BlueprintReadOnly)
	ASkylineBossSplineHub PreviousHub;
	UPROPERTY(NotVisible, BlueprintReadOnly)
	ASkylineBossSplineHub CurrentHub;
	ASkylineBossSpline PreviousPath;

	TMap<ESkylineBossLeg, ESkylineBossLeg> LegOrder;
	FVector ForwardVector = FVector::ForwardVector;
	
	TArray<FSkylineBossMovementData> MovementQueue;

	USkylineBossSettings Settings;

	bool bCanWalk = false;

	bool bHasJustRisen = false;

	private bool bDebugDrawFeetIndex = false;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		SetActorEnableCollision(false);
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Material::SetVectorParameterValue(GlobalParametersVFX, n"SphereMaskOffsetTank", FLinearColor(ConstraintRadiusOrigin.ActorLocation.X, ConstraintRadiusOrigin.ActorLocation.Y, ConstraintRadiusOrigin.ActorLocation.Z, 1.0));

		SetActorEnableCollision(true);

		UBasicAIHealthBarSettings::SetHealthBarVisibility(this, EBasicAIHealthBarVisibility::AlwaysShow, this);

		Settings = USkylineBossSettings::GetSettings(this);

		ApplyDefaultSettings(DefaultSettings);

		// Default order, no redirects
		LegOrder.Add(ESkylineBossLeg::Left, ESkylineBossLeg::Left);
		LegOrder.Add(ESkylineBossLeg::Right, ESkylineBossLeg::Right);
		LegOrder.Add(ESkylineBossLeg::Center, ESkylineBossLeg::Center);

		GetComponentsByClass(LegComponents);
		LegComponents.Sort();

		for (int i = 0; i < LegComponents.Num(); ++i)
		{
			USkylineBossLegComponent LegComponent = LegComponents[i];
			LegComponent.SpawnLeg();
			LegComponent.Leg.SetMaterial(LegMaterialSlots[i]);
		}

		ProjectileResponseComponent.OnImpact.AddUFunction(this, n"HandleProjectileImpact");

		// HatchAnimation.BindUpdate(this, n"HatchAnimationUpdate");
		// HatchAnimation.BindFinished(this, n"HatchAnimationFinished");

		// CoreAnimation.BindUpdate(this, n"CoreAnimationUpdate");
		// CoreAnimation.BindFinished(this, n"CoreAnimationFinished");

		LeftHalfPipeTrigger.OnHalfPipeJumpStarted.AddUFunction(this, n"HandleHalfPipeJumpStarted");
		RightHalfPipeTrigger.OnHalfPipeJumpStarted.AddUFunction(this, n"HandleHalfPipeJumpStarted");

		DisableBoss();

		OnFootLifted.AddUFunction(this, n"FootLifted");
		HealthComponent.OnHealthChange.AddUFunction(this, n"OnHealthChange");

		SyncedHeadPivotRotationComp.SetValue(HeadPivot.WorldRotation);

#if EDITOR
		OnTraversalBegin.AddUFunction(this, n"TemporalLogOnTraversalBegin");
		OnTraversalEnd.AddUFunction(this, n"TemporalLogOnTraversalEnd");
		OnFootPlaced.AddUFunction(this, n"TemporalLogOnFootPlaced");
		OnFootLifted.AddUFunction(this, n"TemporalLogOnFootLifted");
		OnFall.AddUFunction(this, n"TemporalLogOnFall");
		OnRise.AddUFunction(this, n"TemporalLogOnRise");
		OnDie.AddUFunction(this, n"TemporalLogOnDie");
#endif
	}

	UFUNCTION()
	void FootLifted(ASkylineBossLeg Leg)
	{
		Leg.OutlineSkelMesh.bNoSkeletonUpdate = false;
	}

	UFUNCTION()
	private void HandleHalfPipeJumpStarted(AGravityBikeFree GravityBike)
	{
//		auto WeaponUserComp = UGravityBikeWeaponUserComponent::Get(GravityBike.GetDriver());
//		WeaponUserComp.AddCharge(1.0);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(HasControl())
		{
			SyncedHeadPivotRotationComp.SetValue(HeadPivot.WorldRotation);
		}

		auto Trace = Trace::InitChannel(ECollisionChannel::WorldGeometry);
		Trace.IgnoreActor(this);
		auto HitResult = Trace.QueryTraceSingle(HeadPivot.WorldLocation, HeadPivot.WorldLocation - FVector::UpVector * 20000.0);

		ShadowDecal.WorldLocation = HitResult.Location;

#if EDITOR
		TickTemporalLog();

	if(bDebugDrawFeetIndex)
	{
		for(auto LegComp : LegComponents)
			Debug::DrawDebugString(LegComp.Leg.ActorLocation, f"{LegOrder[LegComp.LegIndex]:n}\n(Left)", GetLegIndexColor(LegComp.LegIndex), Scale = 2);
	}

#endif
	}

	UFUNCTION(BlueprintCallable, DevFunction)
	void ToggleDebugDrawFeetIndex()
	{
		bDebugDrawFeetIndex = !bDebugDrawFeetIndex;
	}

	FLinearColor GetLegIndexColor(ESkylineBossLeg LegIndex) const
	{
		switch(LegIndex)
		{
			case ESkylineBossLeg::Left:
				return FLinearColor::Red;

			case ESkylineBossLeg::Right:
				return FLinearColor::Green;

			case ESkylineBossLeg::Center:
				return FLinearColor::LucBlue;
		}

	}

	UFUNCTION(BlueprintCallable)
	void SetState(ESkylineBossState InState)
	{
		if(State == InState)
			return;

		State = InState;
		StartStateTime = Time::GameTimeSeconds;
	}

	UFUNCTION(BlueprintCallable)
	void SnapToTarget()
	{
		if (LookAtTarget.IsDefaultValue())
			SetLookAtTarget(Game::Mio);

		auto TargetBike = Cast<AGravityBikeFree>(LookAtTarget.Get());

		if (TargetBike != nullptr)
			SetLookAtTarget(TargetBike.GetDriver().OtherPlayer);

		FVector LookAtDirection = (LookAtTarget.Get().ActorLocation - HeadPivot.WorldLocation).GetSafeNormal();
			
		HeadPivot.SetWorldRotation(LookAtDirection.ToOrientationQuat());
		SyncedHeadPivotRotationComp.SetValue(HeadPivot.WorldRotation);
		SyncedHeadPivotRotationComp.TransitionSync(this);
	}

	ESkylineBossState GetState() const
	{
		return State;
	}

	bool IsStateActive(ESkylineBossState InState) const
	{
		return State == InState;
	}

	float GetStateActiveDuration() const
	{
		return Time::GetGameTimeSince(StartStateTime);
	}

	access:Compounds
	void SetPhase(ESkylineBossPhase InPhase, bool bForce = false)
	{
		if(!bForce)
		{
			if(!ensure(int(InPhase) == (int(Phase) + 1), "Trying to set the phase to something other than the next phase! This is not allowed (if not forced)."))
				return;
		}

		Phase = InPhase;
		StartPhaseTime = Time::GameTimeSeconds;
	}

	UFUNCTION(BlueprintCallable, DevFunction)
	void SetSecondPhase()
	{
		Phase = ESkylineBossPhase::Second;
		HealthComponent.SetCurrentHealth(HealthComponent.MaxHealth / 2);
	}

	ESkylineBossPhase GetPhase() const
	{
		return Phase;
	}

	bool IsPhaseActive(ESkylineBossPhase InPhase) const
	{
		return Phase == InPhase;
	}

	float GetPhaseActiveDuration() const
	{
		return Time::GetGameTimeSince(StartPhaseTime);
	}

	UFUNCTION()
	void EnableBoss()
	{
		State = ESkylineBossState::Combat;

		if(CenterView::bShowTutorialDuringTripodBoss)
		{
			for(auto Player : Game::Players)
				CenterView::ShowCenterViewTargetTutorial(Player, this);
		}

		if (GetPhase() == ESkylineBossPhase::First)
			USkylineBossEventHandler::Trigger_TripodPhaseOneStart(this);
	}

	UFUNCTION()
	void UnhideBoss()
	{
		RemoveActorDisable(this);

		for (auto LegComponent : LegComponents)
			LegComponent.Leg.RemoveActorDisable(this);
	}

	UFUNCTION()
	void DisableBoss()
	{
		AddActorDisable(this);

		for (auto LegComponent : LegComponents)
			LegComponent.Leg.AddActorDisable(this);

		for(auto Player : Game::Players)
			CenterView::RemoveCenterViewTargetTutorial(Player, this);
	}

	UFUNCTION(DevFunction)
	void TeleportToClosestHubAndFall()
	{
		TListedActors<ASkylineBossSplineHub> Hubs;
		float ClosestDistance = BIG_NUMBER;
		ASkylineBossSplineHub ClosestHub;
		for (auto Hub : Hubs)
		{
			float DistanceToHub = GetDistanceTo(Hub);
			if (DistanceToHub < ClosestDistance)
			{
				ClosestDistance = DistanceToHub;
				ClosestHub = Hub;
			}
		}

		State = ESkylineBossState::Fall;
		TeleportToHub(ClosestHub);

		Debug::DrawDebugSphere(ActorLocation, 5000.0, 12, FLinearColor::Green, 10.0, 5.0);
	}

	UFUNCTION()
	void TeleportPlayersToAlignWithRamp()
	{
		if(!HasControl())
			return;

		FVector Origin = CoreCollision.WorldLocation;
		Origin.Z = CurrentHub.ActorLocation.Z + 200.0;

		float Distance = 25000.0;

		float ForwardOffset = 10000.0;

		FVector OffsetOrigin = Origin + (CurrentHub.ActorForwardVector * ForwardOffset).VectorPlaneProject(FVector::UpVector);

		FVector MioLocation = OffsetOrigin + (CoreCollision.RightVector * -Distance).VectorPlaneProject(FVector::UpVector);
		FVector ZoeLocation = OffsetOrigin + (CoreCollision.RightVector * Distance).VectorPlaneProject(FVector::UpVector);
		FVector MioDirection = (Origin - MioLocation).GetSafeNormal2D();
		FVector ZoeDirection = (Origin - ZoeLocation).GetSafeNormal2D();

		CrumbTeleportPlayersToAlignWithRamp(
			MioLocation,
			MioDirection.Rotation(),
			ZoeLocation,
			ZoeDirection.Rotation()
		);
	}

	UFUNCTION(CrumbFunction)
	private void CrumbTeleportPlayersToAlignWithRamp(
		FVector MioLocation,
		FRotator MioRotation,
		FVector ZoeLocation,
		FRotator ZoeRotation)
	{
		Game::Mio.TeleportActor(MioLocation, MioRotation, this, true);
		Game::Zoe.TeleportActor(ZoeLocation, ZoeRotation, this, true);
	}

	UFUNCTION(BlueprintCallable)
	void TeleportToHub(ASkylineBossSplineHub InHub)
	{
		if (InHub == nullptr)
		{
			devError(f"Teleporting to invalid hub.");
			return;
		}

		PreviousHub = CurrentHub;
		CurrentHub = InHub;
		if(PreviousHub == nullptr)
			PreviousHub = CurrentHub;

		FRotator Rotation = FRotator::MakeFromZX(FVector::UpVector, InHub.ActorForwardVector);

		if(PreviousHub == nullptr && InHub.bIsCenterHub)
			Rotation = FRotator(0, -90, 0);

		SetActorLocationAndRotation(
			InHub.ActorLocation + FVector::UpVector * Settings.BaseHeight,
			Rotation,
			true
		);

		auto FootTargets = CurrentHub.GetOrderedFootTargets(CurrentHub.Paths[0]);		

		for (int i = 0; i < LegComponents.Num(); ++i)
		{
			auto LegComponent = LegComponents[i];
			auto FootTarget = FootTargets[i];
			
			if (FootTarget != nullptr)
			{
				LegComponent.FootTargetComponent = FootTarget;
				LegComponent.Leg.SetFootAnimationTargetLocationAndRotation(FootTarget.WorldLocation, FootTarget.WorldRotation);
			}
		}
	}

	void ResetFootTargets()
	{
		ASkylineBossSplineHub NextHub = CurrentHub.ConnectedHubs[1];

		for (auto Hub : CurrentHub.ConnectedHubs)
		{
			if (Hub.bIsCenterHub && Hub != CurrentHub)
			{
				NextHub = Hub;
				break;
			}
		}
		
		// Update legorder and components to match direction
		ASkylineBossSpline SplineActor = NextHub.GetSplineConnectedToHub(CurrentHub);
		ArrangeLegsBasedOnSpline(SplineActor);
	}

	UFUNCTION(BlueprintCallable)
	void ResetAfterRising()
	{
		SetState(ESkylineBossState::Combat);
		AnimData.FallDirection = ESkylineBossFallDirection::None;
		
		if(!HasControl())
			return;

		PreviousHub = nullptr;
		CurrentHub = SkylineBoss::GetClosestHubTo(ActorLocation);

		//Force tripod to go to center hub after first rise
		MovementQueue.Empty();

		ASkylineBossSplineHub NextHub = CurrentHub.ConnectedHubs[1];

		for(auto Hub : CurrentHub.ConnectedHubs)
		{
			if(Hub.bIsCenterHub && Hub != CurrentHub)
			{
				NextHub = Hub;
				break;
			}
		}

		bHasJustRisen = true;

		CrumbSetNextHub(NextHub);
	}

	void ArrangeLegsBasedOnSpline(ASkylineBossSpline SplineActor)
	{
		auto FootTargets = CurrentHub.GetOrderedFootTargets(SplineActor);
		USkylineBossFootTargetComponent CenterTarget = GetTargetFurthestInDirection(-CurrentHub.ActorForwardVector, FootTargets);
		USkylineBossFootTargetComponent LeftTarget = GetTargetFurthestInDirection(-CurrentHub.ActorRightVector, FootTargets);
		USkylineBossFootTargetComponent RightTarget = GetTargetFurthestInDirection(CurrentHub.ActorRightVector, FootTargets);

		LegComponents[ESkylineBossLeg::Left].FootTargetComponent = LeftTarget;
		LegComponents[ESkylineBossLeg::Left].Leg.SetFootAnimationTargetLocationAndRotation(LeftTarget.WorldLocation, LeftTarget.WorldRotation);

		LegComponents[ESkylineBossLeg::Right].FootTargetComponent = RightTarget;
		LegComponents[ESkylineBossLeg::Right].Leg.SetFootAnimationTargetLocationAndRotation(RightTarget.WorldLocation, RightTarget.WorldRotation);

		LegComponents[ESkylineBossLeg::Center].FootTargetComponent = CenterTarget;
		LegComponents[ESkylineBossLeg::Center].Leg.SetFootAnimationTargetLocationAndRotation(CenterTarget.WorldLocation, CenterTarget.WorldRotation);

		int LeftLegIndex = LegComponents.FindIndex(LegComponents[ESkylineBossLeg::Left]);

		LegOrder[ESkylineBossLeg::Left] = ESkylineBossLeg(LeftLegIndex);
		LegOrder[ESkylineBossLeg::Right] = ESkylineBossLeg(Math::WrapIndex(LeftLegIndex + 1, 0, 3));
		LegOrder[ESkylineBossLeg::Center] = ESkylineBossLeg(Math::WrapIndex(LeftLegIndex + 2, 0, 3));
	}

	USkylineBossFootTargetComponent GetTargetFurthestInDirection(FVector Direction, TArray<USkylineBossFootTargetComponent> Targets) const
	{
		USkylineBossFootTargetComponent FootTarget;
		float MaxDot = -MAX_flt;
		for (auto Target : Targets)
		{
			FVector ToTarget = (Target.WorldLocation - ActorLocation).VectorPlaneProject(FVector::UpVector);
			float Dot = Direction.DotProduct(ToTarget);
			if (Dot > MaxDot)
			{
				MaxDot = Dot;
				FootTarget = Target;
			}
		}
		return FootTarget;
	}

	UFUNCTION(BlueprintCallable)
	void ResetAfterFalling()
	{
		// MovementQueue.Empty();
		SetState(ESkylineBossState::Down);
		CurrentHub = SkylineBoss::GetClosestHubTo(ActorLocation);
		// SetActorLocation(CurrentHub.ActorLocation + FVector::UpVector * Settings.BaseHeight);
	}

	UFUNCTION(BlueprintCallable)
	void MoveAlongSpline(ASkylineBossSpline SplineActor)
	{
		if (SplineActor == nullptr)
		{
			devError(f"Invalid spline actor was passed in as an argument.");
			return;
		}

		ASkylineBossSplineHub ToHub = nullptr;
		TListedActors<ASkylineBossSplineHub> AvailableHubs;
		for (auto Hub : AvailableHubs)
		{
			// Ignore current hub and hubs that are not at either end
			//  of the spline
			if (Hub == CurrentHub ||
				Hub.Paths.Contains(SplineActor))
				continue;

			ToHub = Hub;
			break;
		}

		if (ToHub == nullptr)
		{
			devError(f"There is no target hub along the selected spline.");
			return;
		}

		MoveToHub(ToHub);
	}

	UFUNCTION(BlueprintCallable)
	void MoveToHub(ASkylineBossSplineHub TargetHub)
	{
		// Only Control handles the movement queue
		if(!HasControl())
			return;

		if (!ensure(CurrentHub != nullptr, "Invalid hub was passed in as an argument."))
			return;

		ASkylineBossSplineHub Previous = CurrentHub;
		if (!MovementQueue.IsEmpty())
			Previous = MovementQueue.Last().ToHub;

		if (TargetHub == Previous)
			return;

		// Find the spline that connects our current hub to the target one
		ASkylineBossSpline SplineActor = Previous.GetSplineConnectedToHub(TargetHub);

		if (SplineActor == nullptr)
			return;

		// Are we moving from start or end of the spline?
		bool bIsStartingPoint = false;
		Previous.GetClosestSplineEndIndex(SplineActor.Spline, Previous.ActorLocation, bIsStartingPoint);

		// Left foot is whichever foot is standing on the spline
		//  we are going to be moving along
		if (!bHasJustRisen)
		{
			int LeftLegIndex = 0;
			for (int j = 0; j < LegComponents.Num(); ++j)
			{
				auto LegComponent = LegComponents[j];
				if (LegComponent.FootTargetComponent.Owner == SplineActor)
				{
					LeftLegIndex = j;
					break;
				}
			}

			LegOrder[ESkylineBossLeg::Left] = ESkylineBossLeg(LeftLegIndex);
			LegOrder[ESkylineBossLeg::Right] = ESkylineBossLeg(Math::WrapIndex(LeftLegIndex + 1, 0, 3));
			LegOrder[ESkylineBossLeg::Center] = ESkylineBossLeg(Math::WrapIndex(LeftLegIndex + 2, 0, 3));
		}

		// Rebase forward vector, used to offset the forward vector when moving
		//  along the spline
		auto CenterLegComponent = GetLegComponent(ESkylineBossLeg::Center);
		ForwardVector = CenterLegComponent.WorldTransform.InverseTransformVectorNoScale(ActorForwardVector);

		auto FootTargets = SplineActor.FootTargets;

		// Moving in reverse on the spline, reverse the foot targets
		if (!bIsStartingPoint)
		{
			FootTargets.SetNumZeroed(FootTargets.Num());
			for (int t = 0; t < FootTargets.Num(); ++t)
			{
				int ReverseIndex = (FootTargets.Num() - 1) - t;
				FootTargets[ReverseIndex] = SplineActor.FootTargets[t];
			}
		}

		bHasJustRisen = false;

		// Include hub foot targets, right foot will already be properly placed
		auto HubFootTargets = TargetHub.GetOrderedFootTargets(SplineActor);
		FootTargets.Add(HubFootTargets[ESkylineBossLeg::Left]);
		FootTargets.Add(HubFootTargets[ESkylineBossLeg::Center]);

		// Default leg placement order
		TArray<ESkylineBossLeg> LegPlacementOrder;
		LegPlacementOrder.Add(ESkylineBossLeg::Left);
		LegPlacementOrder.Add(ESkylineBossLeg::Center);
		LegPlacementOrder.Add(ESkylineBossLeg::Right);

		FSkylineBossMovementData MovementData = FSkylineBossMovementData();
		MovementData.SplineActor = SplineActor;
		MovementData.ToHub = TargetHub;
		MovementData.FromHub = Previous;
		MovementData.FootTargets = FootTargets;
		MovementData.bIsReversed = !bIsStartingPoint;
		MovementData.LegPlacementOrder = LegPlacementOrder;
		MovementData.CurrentStep = 0;
		MovementQueue.Add(MovementData);

#if !RELEASE
		TEMPORAL_LOG(this)
			.Struct("MoveToHub Movement Data", MovementData)
			.Value("MoveToHub LegOrder Left", LegOrder[ESkylineBossLeg::Left])
			.Value("MoveToHub LegOrder Right", LegOrder[ESkylineBossLeg::Right])
			.Value("MoveToHub LegOrder Center", LegOrder[ESkylineBossLeg::Center]);
#endif
	}

	ESkylineBossLeg SwapLeg(ESkylineBossLeg Leg)
	{
		if (Leg == ESkylineBossLeg::Left)
			return ESkylineBossLeg::Center;

		if (Leg == ESkylineBossLeg::Right)
			return ESkylineBossLeg::Left;

		return ESkylineBossLeg::Right;
	}

	void AddNewHubToCurrentPath(ASkylineBossSplineHub TargetHub)
	{
		check(HasControl());

		if(MovementQueue.IsEmpty())
		{
			MoveToHub(TargetHub);
			return;
		}

		MoveToHub(TargetHub);
		
		MovementQueue[MovementQueue.Num() - 2].LegPlacementOrderTransitionIndex = MovementQueue[MovementQueue.Num() - 2].FootTargets.Num();
		MovementQueue[MovementQueue.Num() - 2].BodyRotationTransitionIndex = MovementQueue[MovementQueue.Num() - 2].FootTargets.Num();
		
		for(auto FootTarget : MovementQueue.Last().FootTargets)
			MovementQueue[MovementQueue.Num() - 2].FootTargets.Add(FootTarget);

		for(auto PlacementOrder : MovementQueue.Last().LegPlacementOrder)
			MovementQueue[MovementQueue.Num() - 2].NextLegPlacementOrder.Add(SwapLeg(PlacementOrder));

		MovementQueue[MovementQueue.Num() - 2].FromHub = MovementQueue.Last().FromHub;
		MovementQueue[MovementQueue.Num() - 2].ToHub = TargetHub;
		MovementQueue[MovementQueue.Num() - 2].NextSplineActor = MovementQueue.Last().SplineActor;
		MovementQueue[MovementQueue.Num() - 2].bNextIsReversed = MovementQueue.Last().bIsReversed;
		MovementQueue.RemoveAt(MovementQueue.Num() - 1);

	}

	void TraversalToHubCompleted()
	{
		if(!HasControl())
			return;

		devCheck(!MovementQueue.IsEmpty());	

		PreviousPath = MovementQueue[0].SplineActor;
		ASkylineBossSplineHub Previous = CurrentHub;
		CurrentHub = MovementQueue[0].ToHub;
		MovementQueue.RemoveAt(0);

		if(MovementQueue.IsEmpty())
		{
			ASkylineBossSplineHub NextHub = CurrentHub.ConnectedHubs[Math::RandRange(0, CurrentHub.ConnectedHubs.Num()-1)];
			while(NextHub == Previous)
			{
				NextHub = CurrentHub.ConnectedHubs[Math::RandRange(0, CurrentHub.ConnectedHubs.Num()-1)];
			}

			CrumbSetNextHub(NextHub);
		}

		PreviousHub = Previous;
		OnTraversalEnd.Broadcast(PreviousHub, CurrentHub);
	}

	UFUNCTION(CrumbFunction)
	void CrumbSetNextHub(ASkylineBossSplineHub NextHub)
	{
		MoveToHub(NextHub);
	}

	USkylineBossLegComponent GetLegComponent(ESkylineBossLeg Leg) const
	{
		return LegComponents[LegOrder[Leg]];
	}

	UFUNCTION()
	void SetLookAtTarget(AHazeActor Target)
	{
		AHazeActor BikeTarget = GetBikeFromTarget(Target);

		LookAtTarget.Empty();
		LookAtTarget.Apply(BikeTarget, this);
	}

	UFUNCTION()
	void AddLookAtTarget(AHazeActor Target, FInstigator Instigator)
	{
		AHazeActor BikeTarget = GetBikeFromTarget(Target);

		LookAtTarget.Apply(BikeTarget, Instigator);
	}

	UFUNCTION()
	void ClearLookAtTarget(FInstigator Instigator)
	{
		LookAtTarget.Clear(Instigator);
	}

	bool AreAllLegsDestroyed() const
	{
		for (auto LegComponent : LegComponents)
		{
			if(!LegComponent.Leg.IsDestroyed())
				return false;
		}

		return true;
	}

	UFUNCTION()
	void RestoreLegs()
	{
		for (auto LegComponent : LegComponents)
		{
			LegComponent.Leg.RestoreLeg();
		}
	}

	UFUNCTION()
	private void HandleProjectileImpact(FGravityBikeWeaponImpactData ImpactData)
	{
		if (ImpactData.HitComponent == CoreCollision)
		{
			float Damage = ImpactData.Damage;

//			if (Phase == ESkylineBossPhase::First && HealthComponent.GetHealthFraction() <= 0.5)
//				Damage = 0.0;

			FSkylineBossCoreDamagedEventData EventData;
			EventData.HitComponent = ImpactData.HitComponent;
			EventData.ImpactPoint = ImpactData.ImpactPoint;
			EventData.ImpactNormal = ImpactData.ImpactNormal;
			EventData.Player = Cast<AHazePlayerCharacter>(ImpactData.Instigator);
			USkylineBossEventHandler::Trigger_CoreDamaged(this, EventData);

			HealthComponent.TakeDamage(Damage, EDamageType::Default, ImpactData.Instigator);
		}
	}

	UFUNCTION()
	private void OnHealthChange()
	{
		if(HasControl())
		{
			if (State != ESkylineBossState::Dead && HealthComponent.CurrentHealth <= 0.0)
				CrumbDie();
		}
	}

	ASkylineBossSplineHub GetNextHub() const
	{
		check(HasControl());

		if(MovementQueue.IsEmpty())
			return CurrentHub;
		
		return MovementQueue[0].ToHub;
	}

	AGravityBikeFree GetBikeFromTarget(AHazeActor Target)
	{
		auto DriverComp = UGravityBikeFreeDriverComponent::Get(Target);
		if (DriverComp != nullptr)
		{
			return DriverComp.GetGravityBike();
		}

		return nullptr;
	}

	UFUNCTION(BlueprintEvent)
	void BP_LowState()
	{

	}

	UFUNCTION(CrumbFunction)
	void CrumbDie()
	{
		State = ESkylineBossState::Dead;
		OnDie.Broadcast();
		BP_Die();

		USkylineBossEventHandler::Trigger_CoreDestroyed(this);		
	}

	UFUNCTION(BlueprintEvent)
	void BP_Die() { }

	UFUNCTION(BlueprintPure)
	FTransform GetFootTransform(ESkylineBossLeg LegIndex) const
	{
		if (LegComponents.Num() == 0)
			return FTransform();

		FVector Location;
		FRotator Rotation;
		LegComponents[LegIndex].Leg.GetFootLocationAndRotation(Location, Rotation);
		return FTransform(Rotation, Location, Mesh.WorldScale);
	}

	/* Utility functions for animation */
	UFUNCTION(BlueprintPure)
	FTransform GetFootAnimationTargetTransform(ESkylineBossLeg LegIndex) const
	{
		if (LegComponents.Num() == 0)
			return FTransform();

		FVector Location;
		FRotator Rotation;
		LegComponents[LegIndex].Leg.GetFootAnimationTargetTransform(Location, Rotation);
		return FTransform(Rotation, Location, Mesh.WorldScale);
	}

	UFUNCTION(BlueprintPure)
	FTransform GetHeadTransform() const
	{
		return HeadPivot.WorldTransform;
	}

	UFUNCTION(BlueprintPure)
	FTransform GetWeaponTransform(FTransform WeaponWorldTransform) const
	{
		if (LookAtTarget.IsDefaultValue())	
			return WeaponWorldTransform;

		FVector WeaponDirection = LookAtTarget.Get().ActorLocation - WeaponWorldTransform.Location;

		FTransform Transform = WeaponWorldTransform;
		Transform.Rotation = WeaponDirection.ToOrientationQuat();

		return Transform;
	}

	FName GetMeshSocketNameForFootFloorBone(ESkylineBossLeg Leg) const
	{
		switch(Leg)
		{
			case ESkylineBossLeg::Left:
				return n"LeftFrontLegFloor";

			case ESkylineBossLeg::Right:
				return n"RightFrontLegFloor";

			case ESkylineBossLeg::Center:
				return n"BackLegFloor";
		}
	}

	FName GetMeshSocketNameForFootEndBone(ESkylineBossLeg Leg) const
	{
		switch(Leg)
		{
			case ESkylineBossLeg::Left:
				return n"LeftFrontLeg31";

			case ESkylineBossLeg::Right:
				return n"RightFrontLeg31";

			case ESkylineBossLeg::Center:
				return n"BackLeg31";
		}
	}

	UFUNCTION(BlueprintPure)
	bool IsActivaPhase(ESkylineBossPhase ActivatePhase)
	{
		return ActivatePhase == GetPhase();
	}

	UFUNCTION(DevFunction)
	private void DestroyAllLegs()
	{
		for(USkylineBossLegComponent LegComp : LegComponents)
		{
			if(!LegComp.Leg.IsDestroyed())
			{
				LegComp.Leg.HealthComp.Die();
			}
		}
	}

	UFUNCTION(DevFunction)
	private void DamageCore()
	{
		if(State != ESkylineBossState::Down)
		{
			PrintWarning("Must be in the Down state to destroy core!");
			return;
		}

		if(!CoreComponent.IsCoreExposed())
		{
			PrintWarning("Core must be exposed to damage core!");
			return;
		}

		HealthComponent.TakeDamage(0.5 * HealthComponent.MaxHealth, EDamageType::Explosion, this);
		PrintToScreen("Damaged Core!", 5);
	}

	UFUNCTION(BlueprintEvent)
	TArray<UPrimitiveComponent> BP_GetKillPlayerPrimitives() const
	{
		return TArray<UPrimitiveComponent>();
	}

#if EDITOR
	void TickTemporalLog()
	{
		FTemporalLog TemporalLog = TEMPORAL_LOG(this);

		TemporalLog.Value("01#State;Boss State", State);
		TemporalLog.Value("01#State;Boss Phase", Phase);
		TemporalLog.Value("01#State;Hatch Open", HatchComponent.IsHatchOpen());
		TemporalLog.Value("01#State;Core Exposed", CoreComponent.IsCoreExposed());

		TemporalLog.Value("02#Targets;Look at Target;Actor", LookAtTarget.Get());
		TemporalLog.Value("02#Targets;Look at Target;Instigator", LookAtTarget.CurrentInstigator);

		TemporalLog.Value("03#Hubs;Current Hub", CurrentHub);
		TemporalLog.Value("03#Hubs;Previous Hub", PreviousHub);

		for(auto LegComp : LegComponents)
		{
			TemporalLog.Text(f"04#Leg Order; Leg {LegComp.LegIndex:n}", LegComp.Leg.ActorLocation, f"{LegOrder[LegComp.LegIndex]:n}\n({LegComp.LegIndex:n})", GetLegIndexColor(LegComp.LegIndex), Scale = 2);
		}

		TemporalLog.Transform("05#Transforms;Actor Transform", ActorTransform, 5000, 100);
		TemporalLog.Transform("05#Transforms;Head Pivot Transform", HeadPivot.WorldTransform, 5000, 100);
		TemporalLog.Transform("05#Transforms;Legs Pivot Transform", LegsPivot.WorldTransform, 5000, 100);
		TemporalLog.DirectionalArrow("05#Transforms;Forward Vector", ActorLocation, ForwardVector * 10000, 200, 1000000);
		
		if(CurrentHub != nullptr)
			TemporalLog.DirectionalArrow("Current hub", CurrentHub.ActorLocation + FVector::UpVector * 10000, FVector::DownVector * 10000, 200, 1000000, FLinearColor::Green);


		if((State == ESkylineBossState::Down || State == ESkylineBossState::Rise) && PreviousHub != nullptr)
		{
			ASkylineBossSpline SplineActor = CurrentHub.GetSplineConnectedToHub(PreviousHub);
			auto FootTargets = CurrentHub.GetOrderedFootTargets(SplineActor);

			for(int i = 0; i < FootTargets.Num(); i++)
				TemporalLog.Text(f"Target {i}", FootTargets[i].WorldLocation, f"{i}", FLinearColor::White, Scale = 2);
		}

		if(HasControl())
		{
			if(!MovementQueue.IsEmpty())
				MovementQueue[0].LogToTemporalLog(TemporalLog, "06#MovementData");

			FTemporalLog MovementQueueLog = TemporalLog.Page("Movement Queue");
			for(int i = 0; i < MovementQueue.Num(); i++)
			{
				FString Category = f"Movement Data {i}";
				MovementQueue[i].LogToTemporalLog(MovementQueueLog, Category);

				if(i == 0)
					MovementQueueLog.Arrow(f"{Category};From Previous to Target Hub", ActorLocation, MovementQueue[i].ToHub.ActorLocation, 100, 500);
				else
					MovementQueueLog.Arrow(f"{Category};From Previous to Target Hub", MovementQueue[i - 1].ToHub.ActorLocation, MovementQueue[i].ToHub.ActorLocation, 100, 500);
			}
		}
	}

	UFUNCTION()
	private void TemporalLogOnTraversalBegin(ASkylineBossSplineHub FromHub, ASkylineBossSplineHub ToHub)
	{
		TEMPORAL_LOG(this).Event(f"Traversal Begin from {FromHub.Name} to {ToHub.Name}");
	}

	UFUNCTION()
	private void TemporalLogOnTraversalEnd(ASkylineBossSplineHub FromHub, ASkylineBossSplineHub ToHub)
	{
		TEMPORAL_LOG(this).Event(f"Traversal End from {FromHub.Name} to {ToHub.Name}");
	}

	UFUNCTION()
	private void TemporalLogOnFootPlaced(ASkylineBossLeg Leg)
	{
		TEMPORAL_LOG(this, "Foot Placement").Event(f"On Foot Placed: {Leg.LegIndex}");
	}

	UFUNCTION()
	private void TemporalLogOnFootLifted(ASkylineBossLeg Leg)
	{
		TEMPORAL_LOG(this, "Foot Placement").Event(f"On Foot Lifted: {Leg.LegIndex}");
	}

	UFUNCTION()
	private void TemporalLogOnFall()
	{
		TEMPORAL_LOG(this).Event(f"OnFall");
	}

	UFUNCTION()
	private void TemporalLogOnRise()
	{
		TEMPORAL_LOG(this).Event(f"OnRise");
	}

	UFUNCTION()
	private void TemporalLogOnDie()
	{
		TEMPORAL_LOG(this).Event(f"OnDie");
	}
#endif
};