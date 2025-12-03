event void FDentistBossHealthEvent(float Damage);
event void FDentistBossDeathEvent();
event void FDentistBossGrabberDestroyedEvent();
event void FDentistBossStateEvent(EDentistBossState State);

asset DentistBossSheet of UHazeCapabilitySheet
{
	Capabilities.Add(UDentistBossActionSelectionCapability);

	Capabilities.Add(UDentistBossLookAtPlayerCapability);
	Capabilities.Add(UDentistBossMalfunctioningEyesCapability);

	Capabilities.Add(UDentistBossLeftArmDeathCapability);
	Capabilities.Add(UDentistBossRightArmDeathCapability);
	Capabilities.Add(UDentistBossLeftArmSwatAwayPlayerCapability);
	Capabilities.Add(UDentistBossRightArmSwatAwayPlayerCapability);

	Capabilities.Add(UDentistBossSetLeanBlendSpaceValuesCapability);
}

enum EDentistBossState
{
	Start,
	RestrainedInChair,
	ToothBrushOne,
	DentureSpawning,
	DenturesSpawned,
	CupSpawning,
	CupSuccessfullyChosen,
	CupPoorlyChosen,
	SpinningCake,
	ToothBrushTwo,
	HookTwo,
	DentureSpawningTwo,
	DenturesSpawnedTwo,
	Defeated,
	Chase,
	Debugging,
	MAX
}

enum EDentistBossArm
{
	LeftTop,
	LeftMiddle,
	LeftBottom,
	RightTop,
	RightMiddle,
	RightBottom
}

enum EDentistBossTool
{
	Drill,
	MioChair,
	ZoeChair,
	Dentures,
	ToothBrush,
	CupMiddle,
	CupLeft,
	CupRight,
	Scraper,
	Hammer,
	ToothPasteTube,
}

struct FDentistBossCapabilityBlocks
{
	TArray<FName> Blocks;
}

class ADentistBoss : AHazeActor
{
	UPROPERTY(DefaultComponent)
	UHazeMovementAudioComponent MoveAudioComp;
	
	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.InitialStoppedSheets.Add(DentistBossSheet);
	default CapabilityComp.DefaultCapabilityClasses.Add(UDentistBossPlayerDrillFinisherCapability);

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedActorComp;
	
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UHazeSkeletalMeshComponentBase SkelMesh;

	UPROPERTY(DefaultComponent, Attach = SkelMesh, AttachSocket = TeethAttach)
	USceneComponent FinisherDrillNeckRoot;

	UPROPERTY(DefaultComponent, Attach = SkelMesh, AttachSocket = Head)
	USquishTriggerBoxComponent FallOverArenaSquishTrigger;


	UPROPERTY(DefaultComponent, Attach = SkelMesh, AttachSocket = LeftHandWeakpointSocket)
	UStaticMeshComponent LeftHandWeakpointMesh;

	UPROPERTY(DefaultComponent, Attach = LeftHandWeakpointMesh)
	UDentistGroundPoundAutoAimComponent LeftHandAutoAimComp;
	default LeftHandAutoAimComp.MoveToRadius = 0.0;
	default LeftHandAutoAimComp.MaxRadius = 250.0;
	default LeftHandAutoAimComp.Height = 750.0;

	UPROPERTY(DefaultComponent, Attach = SkelMesh, AttachSocket = LeftHandWeakpointSocket)
	USquishTriggerBoxComponent LeftHandPlayerSquishTraceBox;

	UPROPERTY(DefaultComponent, Attach = SkelMesh, AttachSocket = LeftHandWeakpointSocket)
	UStaticMeshComponent LeftHandBiteTrigger;

	UPROPERTY(DefaultComponent)
	UBasicAIHealthComponent LeftHandHealthComp;

	UPROPERTY(DefaultComponent, Attach = SkelMesh, AttachSocket = LeftHandWeakpointSocket)
	UDentistBossArmWeakpointHealthBarComponent LeftHandHealthBarComp;

	UPROPERTY(DefaultComponent, Attach = SkelMesh, AttachSocket = LeftHandWeakpointSocket)
	UHazeMovablePlayerTriggerComponent LeftHandSwattingPlayerTrigger;

	// UPROPERTY(DefaultComponent, Attach = SkelMesh, AttachSocket = LeftHandWeakpointSocket)
	// UGodrayComponent LeftHandWeakpointGodrayComp;

	// UPROPERTY(DefaultComponent, Attach = SkelMesh, AttachSocket = LeftHandWeakpointSocket)
	// USpotLightComponent LeftHandWeakpointSpotlightComp;

	UPROPERTY(DefaultComponent, Attach = SkelMesh, AttachSocket = LeftHandWeakpointSocket)
	UDentistBossWeakpointLocationComponent LeftHandWeakpointLocationComp;

	UPROPERTY(DefaultComponent, Attach = LeftHandWeakpointLocationComp)
	UNiagaraComponent LeftHandWeakpointEffect;


	UPROPERTY(DefaultComponent, Attach = SkelMesh, AttachSocket = RightHandWeakpointSocket)
	UStaticMeshComponent RightHandWeakpointMesh;
	default RightHandAutoAimComp.MoveToRadius = 0.0;
	default RightHandAutoAimComp.MaxRadius = 250.0;
	default RightHandAutoAimComp.Height = 750.0;

	UPROPERTY(DefaultComponent, Attach = RightHandWeakpointMesh)
	UDentistGroundPoundAutoAimComponent RightHandAutoAimComp;

	UPROPERTY(DefaultComponent, Attach = SkelMesh, AttachSocket = RightHandWeakpointSocket)
	USquishTriggerBoxComponent RightHandPlayerSquishTraceBox;

	UPROPERTY(DefaultComponent, Attach = SkelMesh, AttachSocket = RightHandWeakpointSocket)
	UStaticMeshComponent RightHandBiteTrigger;

	UPROPERTY(DefaultComponent)
	UBasicAIHealthComponent RightHandHealthComp;

	UPROPERTY(DefaultComponent, Attach = SkelMesh, AttachSocket = RightHandWeakpointSocket)
	UDentistBossArmWeakpointHealthBarComponent RightHandHealthBarComp;

	UPROPERTY(DefaultComponent, Attach = SkelMesh, AttachSocket = RightHandWeakpointSocket)
	UHazeMovablePlayerTriggerComponent RightHandSwattingPlayerTrigger;

	// UPROPERTY(DefaultComponent, Attach = SkelMesh, AttachSocket = RightHandWeakpointSocket)
	// UGodrayComponent RightHandWeakpointGodrayComp;

	// UPROPERTY(DefaultComponent, Attach = SkelMesh, AttachSocket = RightHandWeakpointSocket)
	// USpotLightComponent RightHandWeakpointSpotlightComp;

	UPROPERTY(DefaultComponent, Attach = SkelMesh, AttachSocket = RightHandWeakpointSocket)
	UDentistBossWeakpointLocationComponent RightHandWeakpointLocationComp;

	UPROPERTY(DefaultComponent, Attach = RightHandWeakpointLocationComp)
	UNiagaraComponent RightHandWeakpointEffect;


	UPROPERTY(DefaultComponent, Attach = SkelMesh, AttachSocket = "Head")
	USphereComponent HeadCameraCollisionSphere;

	UPROPERTY(DefaultComponent, Attach = SkelMesh, AttachSocket = "Spine6")
	USphereComponent TorsoCameraCollisionSphere;

	UPROPERTY(DefaultComponent, Attach = SkelMesh, AttachSocket = "Hips")
	UCapsuleComponent BodyCameraCollisionCapsule;

	UPROPERTY(DefaultComponent, Attach = SkelMesh, AttachSocket = "LowerJaw")
	UCapsuleComponent DefeatedJawCollisionCapsule;

	UPROPERTY(DefaultComponent, Attach = SkelMesh, AttachSocket = "Neck3")
	UCapsuleComponent DefeatedNeckCollisionCapsule;

	UPROPERTY(DefaultComponent, Attach = SkelMesh, AttachSocket = "Head")
	UStaticMeshComponent HeadLightCollisionMesh;


	UPROPERTY(DefaultComponent)
	UDentistToothMovementResponseComponent ToothMovementResponseComp;

	UPROPERTY(DefaultComponent)
	UHazeMeshPoseDebugComponent PoseDebugComp;


	UPROPERTY(DefaultComponent, Attach = SkelMesh, AttachSocket = "HeadLightSocket")
	ULensFlareComponent LensFlareComp;

	UPROPERTY(DefaultComponent)
	UDentistBossTargetComponent TargetComp;

	UPROPERTY(DefaultComponent)
	UHazeRequestCapabilityOnPlayerComponent RequestComp;
	default RequestComp.PlayerCapabilities.Add(n"DentistBossPlayerWiggleRotationCapability");

	UPROPERTY(DefaultComponent)
	UTemporalLogTransformLoggerComponent TransformTemporalLogComp;

	UPROPERTY(DefaultComponent)
	UDentistBossCupSortingComponent CupSortingComp;

	// CLASS REFS
	UPROPERTY(EditDefaultsOnly, Category = "Setup")
	TSubclassOf<ADentistBossToolDrill> DrillClass;

	UPROPERTY(EditDefaultsOnly, Category = "Setup")
	TSubclassOf<ADentistBossToolDentures> DenturesClass;

	UPROPERTY(EditDefaultsOnly, Category = "Setup")
	TSubclassOf<ADentistBossToolToothBrush> ToothBrushClass;

	UPROPERTY(EditDefaultsOnly, Category = "Setup")
	TSubclassOf<ADentistBossToolCup> CupClass;

	UPROPERTY(EditDefaultsOnly, Category = "Setup")
	TSubclassOf<ADentistBossToolScraper> ScraperClass;

	UPROPERTY(EditDefaultsOnly, Category = "Setup")
	TSubclassOf<ADentistBossToolHammer> HammerClass;

	UPROPERTY(EditDefaultsOnly, Category = "Setup")
	TSubclassOf<ADentistBossToolToothPasteTube> ToothPasteTubeClass;

	UPROPERTY(EditDefaultsOnly, Category = "Setup")
	TSubclassOf<ADentistBossToothPasteGlob> ToothPasteGlobClass;

	UPROPERTY(EditDefaultsOnly, Category = "Setup")
	TSubclassOf<UBossHealthBarWidget> HealthBarClass;

	UPROPERTY(EditDefaultsOnly, Category = "Setup")
	FText BossName = NSLOCTEXT("Dentist", "Boss Name", "The Dentist",);

	UPROPERTY(EditDefaultsOnly, Category = "Setup")
	UPhysicsAsset LeftArmDestroyedPhysAsset;

	UPROPERTY(EditDefaultsOnly, Category = "Setup")
	UPhysicsAsset RightArmDestroyedPhysAsset;


	// INSTANCE REFS
	UPROPERTY(EditInstanceOnly, Category = "Setup")
	ADentistBossToolChair MioChair;

	UPROPERTY(EditInstanceOnly, Category = "Setup")
	ADentistBossToolChair ZoeChair;

	UPROPERTY(EditInstanceOnly, Category = "Setup")
	ADentistBossCake Cake;

	UPROPERTY(EditInstanceOnly, Category = "Setup")
	ADentistBossCupManager CupManager;

	UPROPERTY(EditInstanceOnly, Category = "Setup")
	AHazeLevelSequenceActor FinisherSequence;

	UPROPERTY(EditInstanceOnly, Category = "Setup")
	AStaticCameraActor StartCamera;

	UPROPERTY(EditInstanceOnly, Category = "Setup")
	AHazeCameraActor HookedCamera;

	UPROPERTY(EditInstanceOnly, Category = "Setup")
	AHazeCameraActor FinisherCamera;

	UPROPERTY(EditInstanceOnly, Category = "Setup")
	ADoubleInteractionActor FinisherDoubleInteractActor;


	UPROPERTY(EditAnywhere, Category = "Setup")
	UDentistBossSettings DefaultSettings;

	TArray<UHazeActionQueueComponent> ActionQueueComps;

	UDentistBossSettings Settings;
	FDentistBossHeadlightSettings CurrentSpotlightSettings;
	EDentistBossState CurrentState;
	TMap<EDentistBossTool, ADentistBossTool> Tools;
	TArray<ADentistBossTool> ArmAttachedTools;
	TPerPlayer<FDentistBossCapabilityBlocks> CurrentCapabilityBlocks;
	TPerPlayer<bool> HasSwatAmnesty;

	UPROPERTY()
	FDentistBossHealthEvent OnDamageTaken;
	UPROPERTY()
	FDentistBossDeathEvent OnDied;
	UPROPERTY()
	FDentistBossDeathEvent OnFinisherButtonMashCompleted;
	UPROPERTY()
	FDentistBossGrabberDestroyedEvent OnFirstArmLost;
	UPROPERTY()
	FDentistBossGrabberDestroyedEvent OnSecondArmLost;
	UPROPERTY()
	FDentistBossStateEvent OnStateProgressedTo;

	bool bIsActive = false;
	bool bHasActivatedSheets = false;
	bool bFinisherButtonMashActivated = false;
	bool bFinalChaseStarted = false;

	float CurrentHealth;

	const int QueueNum = 3;
	int WeakpointGrabbersStillAlive = 0;

	UHazeActorNetworkedSpawnPoolComponent ToothPastePool;

	bool bLeftArmDestroyed = false;
	float LeftArmCablePhysicsAlpha = 0.0;
	bool bRightArmDestroyed = false;
	float RightArmCablePhysicsAlpha = 0.0;

	// ANIM VARIABLES
	const FName LeftUpperHand_IK = n"LeftUpperHand_IK";
	const FName RightUpperHand_IK = n"RightUpperHand_IK";
	const FName LeftLowerHand_IK = n"LeftLowerHand_IK";
	const FName RightLowerHand_IK = n"RightLowerHand_IK";

	const FName LeftUpperAttach = n"LeftUpperAttach";
	const FName RightUpperAttach = n"RightUpperAttach";

	const FName LeftLowerAttach = n"LeftLowerAttach";
	const FName RightLowerAttach = n"RightLowerAttach";
	
	const FName Align = n"Align";

	FTransform LeftUpperHandTargetingTransform;
	FTransform RightUpperHandTargetingTransform;
	FTransform LeftLowerHandTargetingTransform;
	FTransform RightLowerHandTargetingTransform;

	TInstigated<EDentistBossAnimationState> CurrentAnimationState;
	default CurrentAnimationState.DefaultValue = EDentistBossAnimationState::Idle;

	TInstigated<EDentistIKState> CurrentIKState;
	default CurrentIKState.DefaultValue = EDentistIKState::None;

	TInstigated<FVector2D> LeanBlendSpaceValues;
	TInstigated<bool> UseLeanBlendSpace;
	default UseLeanBlendSpace.DefaultValue = false;

	TInstigated<bool> LookAtEnabled;
	default LookAtEnabled.DefaultValue = true;
	float EyeSpeed = 1.0;

	bool bRightPlayerEscapedChair = false;
	bool bLeftPlayerEscapedChair = false;

	bool bDrillFoundPlayer = false;
	bool bDrillFinished = false;
	bool bDrillExit = false;
	bool bDrillSpinArena = false;
	float DrillingPlayerWobble = 0.0;

	bool bDenturesDestroyedHand = false;
	bool bPreviousArmDestroyedWasLeft = false;
	float DenturesBitingAlpha = 0.0;
	bool bDenturesFellDown = false;
	bool bDenturesAttachedLeftHand = false;
	bool bDenturesAttachedRightHand = false;
	bool bSwatLeftHand = false;
	bool bSwatRightHand = false;

	bool bCupCaptureTelegraphDone = false;
	EDentistBossToolCupSortType CurrentSortType = EDentistBossToolCupSortType::None;
	float CupSortAnimSpeed = 1.0;
	bool bCupChosen = false;

	bool bHookTelegraphDone = false;

	bool bHammerPlayer = false;
	bool bHammerSplitPlayer = false;

	bool bFinisherDoubleInteractStarted = false;
	UPROPERTY(BlueprintReadOnly)
	float FinisherProgress = 0.0;
	UPROPERTY(BlueprintReadOnly)
	float SelfDrillAlpha = 0.0;
	bool bFinisherCompleted = false;

	float CloseMouthMaskAgainAlpha = 0.0;
	FHazeAcceleratedFloat AccMaskOverride;
	bool bShouldHaveMaskOverride = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ApplyDefaultSettings(DefaultSettings);

		DentistBossDevToggles::DentistBossCategory.MakeVisible();

		for(int i = 0; i < QueueNum; i++)
		{
			auto Comp = UHazeActionQueueComponent::Create(this);
			ActionQueueComps.Add(Comp);
		}
		
		Settings = UDentistBossSettings::GetSettings(this);
		CurrentSpotlightSettings = Settings.HasNoTargetSpotlightSettings;

		CurrentHealth = Settings.TotalHealthPerArm * 2;

		for(auto Tool : Tools)
		{
			auto SpawnedRequestComp = UHazeRequestCapabilityOnPlayerComponent::Get(Tool.Value);
			if(SpawnedRequestComp != nullptr)
				RequestComp.AppendRequestsFromOtherComponent(SpawnedRequestComp);
		}

		Tools.Add(EDentistBossTool::MioChair, MioChair);
		MioChair.ToolType = EDentistBossTool::MioChair;
		Tools.Add(EDentistBossTool::ZoeChair, ZoeChair);
		ZoeChair.ToolType = EDentistBossTool::ZoeChair;

		AttachAllTools();

		ToggleActivated(false);

		ToothPastePool = HazeActorNetworkedSpawnPoolStatics::GetOrCreateSpawnPool(ToothPasteGlobClass, this);
		InitialSpawnToothPasteGlobs(20);

		LeftHandBiteTrigger.OnComponentBeginOverlap.AddUFunction(this, n"OnLeftHandBiteTriggerOverlapped");
		RightHandBiteTrigger.OnComponentBeginOverlap.AddUFunction(this, n"OnRightHandBiteTriggerOverlapped");

		ToothMovementResponseComp.OnGroundPoundedOn.AddUFunction(this, n"OnGroundPoundedOn");

		FinisherDoubleInteractActor.OnDoubleInteractionLockedIn.AddUFunction(this, n"OnFinisherDoubleInteractCompleted");

		ToggleHandWeakpointHittable(false, true);
		ToggleHandWeakpointHittable(false, false);

		FallOverArenaSquishTrigger.AddComponentVisualsAndCollisionAndTickBlockers(this);
	}

	UFUNCTION()
	private void OnFinisherDoubleInteractCompleted()
	{
		bFinisherDoubleInteractStarted = true;
	}

	UFUNCTION()
	private void OnLeftHandBiteTriggerOverlapped(UPrimitiveComponent OverlappedComponent,
	                                             AActor OtherActor, UPrimitiveComponent OtherComp,
	                                             int OtherBodyIndex, bool bFromSweep,
	                                             const FHitResult&in SweepResult)
	{
		HandOverlapped(OtherActor, true);
	}

	UFUNCTION()
	private void OnRightHandBiteTriggerOverlapped(UPrimitiveComponent OverlappedComponent,
	                                              AActor OtherActor, UPrimitiveComponent OtherComp,
	                                              int OtherBodyIndex, bool bFromSweep,
	                                              const FHitResult&in SweepResult)
	{
		HandOverlapped(OtherActor, false);
	}

	void HandOverlapped(AActor OtherActor, bool bLeftHand)
	{
		auto Dentures = Cast<ADentistBossToolDentures>(OtherActor);
		if(Dentures == nullptr)
			return;

		if(!Dentures.ControllingPlayer.IsSet())
			return;
		
		if(bLeftHand)
		{
			bDenturesAttachedLeftHand = true;
			Dentures.bIsBitingLeftHand = true;
		}
		else
		{
			bDenturesAttachedRightHand = true;
			Dentures.bIsBitingRightHand = true;
		}
	}

	UFUNCTION()
	private void OnGroundPoundedOn(AHazePlayerCharacter GroundPoundPlayer, FHitResult Impact)
	{
		if(!GroundPoundPlayer.HasControl())
			return;

		if(Impact.Component == LeftHandWeakpointMesh)
			CrumbArmTakeDamage(true, GroundPoundPlayer, Impact);
		if(Impact.Component == RightHandWeakpointMesh)
			CrumbArmTakeDamage(false, GroundPoundPlayer, Impact);
	}

	UFUNCTION(CrumbFunction, NotBlueprintCallable)
	void CrumbArmTakeDamage(bool bLeftSide, AHazePlayerCharacter GroundPoundPlayer, FHitResult Impact)
	{
		auto HealthComp = bLeftSide ? LeftHandHealthComp : RightHandHealthComp;
		auto HealthBarComp = bLeftSide ? LeftHandHealthBarComp : RightHandHealthBarComp;
		HealthBarComp.ModifyHealth(HealthComp.CurrentHealth - Settings.GrabberGroundPoundedDamageTaken);
		HealthComp.TakeDamage(Settings.GrabberGroundPoundedDamageTaken, EDamageType::Impact, GroundPoundPlayer);

		FDentistBossEffectHandlerOnGrabberGroundPoundedParams EffectParams;
		EffectParams.GroundPoundLocation = Impact.ImpactPoint;
		EffectParams.HealthAfterGroundPound = HealthComp.CurrentHealth;
		UDentistBossEffectHandler::Trigger_OnGrabberGroundPounded(this, EffectParams);
	}

	void AttachAllTools()
	{
		auto Drill = TListedActors<ADentistBossToolDrill>().GetSingle();
		AttachTool(Drill, DefaultSettings.DrillArm);
		ArmAttachedTools.Add(Drill);
		Tools.Add(EDentistBossTool::Drill, Drill);
		Drill.ToolType = EDentistBossTool::Drill;

		auto Dentures = TListedActors<ADentistBossToolDentures>().GetSingle();
		Tools.Add(EDentistBossTool::Dentures, Dentures);
		Dentures.ToolType = EDentistBossTool::Dentures;

		auto ToothBrush = TListedActors<ADentistBossToolToothBrush>().GetSingle();
		Tools.Add(EDentistBossTool::ToothBrush, ToothBrush);
		ToothBrush.ToolType = EDentistBossTool::ToothBrush;
		AttachTool(ToothBrush, EDentistBossArm::LeftTop);

		auto Scraper = TListedActors<ADentistBossToolScraper>().GetSingle();
		Tools.Add(EDentistBossTool::Scraper, Scraper);
		Scraper.ToolType = EDentistBossTool::Scraper;
		AttachTool(Scraper, EDentistBossArm::LeftTop);
		
		auto Hammer = TListedActors<ADentistBossToolHammer>().GetSingle();
		Tools.Add(EDentistBossTool::Hammer, Hammer);
		Hammer.ToolType = EDentistBossTool::Hammer;
		AttachTool(Hammer, EDentistBossArm::RightTop);

		auto ToothPasteTube = TListedActors<ADentistBossToolToothPasteTube>().GetSingle();
		Tools.Add(EDentistBossTool::ToothPasteTube, ToothPasteTube);
		ToothPasteTube.ToolType = EDentistBossTool::ToothPasteTube;
		AttachTool(ToothPasteTube, EDentistBossArm::RightTop);
		
		TArray<ADentistBossToolCup> Cups = TListedActors<ADentistBossToolCup>().GetArray();
		Tools.Add(EDentistBossTool::CupLeft, Cups[0]);
		Cups[0].ToolType = EDentistBossTool::CupLeft;
		Tools.Add(EDentistBossTool::CupMiddle, Cups[1]);
		Cups[1].ToolType = EDentistBossTool::CupMiddle;
		Tools.Add(EDentistBossTool::CupRight, Cups[2]);
		Cups[2].ToolType = EDentistBossTool::CupRight;
	}

#if EDITOR
	UFUNCTION(CallInEditor, Category = "Setup")
	void CreateAllTools()
	{
		CleanUpTools();

		ADentistBossTool Tool;
		Tool = CreateTool(DrillClass);

		CreateTool(DenturesClass);
		CreateTool(ToothBrushClass);
		CreateTool(ScraperClass);
		CreateTool(HammerClass);
		CreateTool(ToothPasteTubeClass);

		CreateTool(CupClass);
		CreateTool(CupClass);
		CreateTool(CupClass);
	}

	private void CleanUpTools()
	{
		auto ToolsInLevel = Editor::GetAllEditorWorldActorsOfClass(ADentistBossTool);
		for(int i = ToolsInLevel.Num() - 1; i >= 0; i--)
		{
			if(ToolsInLevel[i].IsA(ADentistBossToolChair))
				continue;

			ToolsInLevel[i].DestroyActor();
		}

		auto GlobsInLevel = Editor::GetAllEditorWorldActorsOfClass(ADentistBossToothPasteGlob);
		for(int i = GlobsInLevel.Num() - 1; i >= 0; i--)
		{
			GlobsInLevel[i].DestroyActor();
		}

		ArmAttachedTools.Empty();
	}
#endif

	private ADentistBossTool CreateTool(TSubclassOf<ADentistBossTool> ToolClass)
	{
		auto Tool = SpawnActor(ToolClass, bDeferredSpawn = true); 
		Tool.Dentist = this;
		FinishSpawningActor(Tool);
		return Tool;
	}

		
	void AttachTool(ADentistBossTool Tool, EDentistBossArm ArmToAttachTo)
	{
		USceneComponent AttachRoot;
		FName BoneAttach;
		switch(ArmToAttachTo)
		{
			case EDentistBossArm::LeftTop:
			{
				BoneAttach = LeftUpperAttach;
				break;
			}
			case EDentistBossArm::LeftMiddle:
			{
				BoneAttach = LeftLowerAttach;
				break;
			}
			case EDentistBossArm::LeftBottom:
			{
				BoneAttach = LeftUpperAttach;
				break;
			}
			case EDentistBossArm::RightBottom:
			{
				BoneAttach = RightUpperAttach;
				break;
			}
			case EDentistBossArm::RightMiddle:
			{
				BoneAttach = RightLowerAttach;
				break;
			}
			case EDentistBossArm::RightTop:
			{
				BoneAttach = RightUpperAttach;
				break;
			}
		}
		
		Tool.AttachToComponent(SkelMesh, BoneAttach, EAttachmentRule::SnapToTarget);
	}
	
	void SwapToolReferences(EDentistBossTool ToolOne, EDentistBossTool ToolTwo)
	{
		bool bBothAreCups = IsCupTool(ToolOne) && IsCupTool(ToolTwo);
		if (HasControl() && bBothAreCups)
			CrumbSwapTools(ToolOne, ToolTwo);
		else
			LocalSwapToolReferences(ToolOne, ToolTwo); // I don't know if any other tools rely on animations for swapping, but the cups needed to be networked 
	}

	private bool IsCupTool(EDentistBossTool ToolType) const
	{
		if (ToolType == EDentistBossTool::CupMiddle || ToolType == EDentistBossTool::CupMiddle || ToolType == EDentistBossTool::CupMiddle)
			return true;
		return false;
	}

	UFUNCTION(CrumbFunction)
	private void CrumbSwapTools(EDentistBossTool ToolOne, EDentistBossTool ToolTwo)
	{
		LocalSwapToolReferences(ToolOne, ToolTwo);
	}
	
	private void LocalSwapToolReferences(EDentistBossTool ToolOne, EDentistBossTool ToolTwo)
	{
		ADentistBossTool ToolActorOne = Tools[ToolOne];
		ADentistBossTool ToolActorTwo = Tools[ToolTwo];

		if (DentistBossDevToggles::CupPrinting.IsEnabled())
		{
			PrintToScreen("Swap: " + ToolActorOne.ActorNameOrLabel , 10.0, ColorDebug::Rainbow(10.0));
			PrintToScreen(" with " + ToolActorTwo.ActorNameOrLabel , 10.0, ColorDebug::Rainbow(10.0));
		}

		ToolActorOne.ToolType = ToolTwo;
		ToolActorTwo.ToolType = ToolOne;

		Tools.Remove(ToolOne);
		Tools.Remove(ToolTwo);

		Tools.Add(ToolOne, ToolActorTwo);
		Tools.Add(ToolTwo, ToolActorOne);
	}

	UFUNCTION(BlueprintCallable)
	void ToggleActivated(bool bActivate)
	{
		bIsActive = bActivate;

		if(bActivate)
		{
			if(!bHasActivatedSheets)
			{
				CapabilityComp.StartInitialStoppedSheets(this);
				bHasActivatedSheets = true;
			}
		}
		else
		{
			if(bHasActivatedSheets)	
			{
				CapabilityComp.StopInitialStoppedSheets(this);
				bHasActivatedSheets = false;
			}
		} 

		for(auto Comp : ActionQueueComps)
		{
			Comp.SetPaused(!bActivate);
		}
	}

	void TakeDamage(float Damage)
	{
		OnDamageTaken.Broadcast(Damage);
		CurrentHealth -= Damage;
		if(CurrentHealth <= 0)
		{
			ClearActionQueues();
			CurrentState = EDentistBossState::Defeated;
		}
	}

	UFUNCTION(CrumbFunction, NotBlueprintCallable)
	void CrumbDie()
	{
		OnDied.Broadcast();
		for(auto Player  : Game::Players)
		{
			auto HealthSettings = UPlayerHealthSettings::GetSettings(Player);
			HealthSettings.bGameOverWhenBothPlayersDead = false;
		}

		SkelMesh.RemoveTag(n"HideOnCameraOverlap");
		SkelMesh.RemoveTag(n"HideIndividualComponentOnCameraOverlap");
		SkelMesh.AddTag(n"AlwaysBlockCamera");
		DefeatedJawCollisionCapsule.AddTag(n"AlwaysBlockCamera");
		FallOverArenaSquishTrigger.RemoveComponentVisualsAndCollisionAndTickBlockers(this);
	}

	void ClearActionQueues()
	{
		for(auto Comp : ActionQueueComps)
		{
			Comp.Empty();
		}
	}

	void InitialSpawnToothPasteGlobs(int Count)
	{
		TArray<FHazeActorSpawnParameters> SpawnParams;
		for(int i = 0; i < Count; i++)
		{
			FHazeActorSpawnParameters NewParams = FHazeActorSpawnParameters(Tools[EDentistBossTool::ToothPasteTube]);
			SpawnParams.Add(NewParams);
		}
		ToothPastePool.SpawnBatchControl(SpawnParams);
	}

	ADentistBossToothPasteGlob GetToothPasteGlob(FVector SpawnLocation, FRotator SpawnRotation)
	{
		FHazeActorSpawnParameters SpawnParams;
		SpawnParams.Location = SpawnLocation;
		SpawnParams.Rotation = SpawnRotation;
		auto ToothPasteActor = ToothPastePool.SpawnControl(SpawnParams);
		auto ToothPasteGlob = Cast<ADentistBossToothPasteGlob>(ToothPasteActor);

		return ToothPasteGlob;
	}

	void ToothPasteGetDespawned(ADentistBossToothPasteGlob ToothPaste)
	{
		ToothPaste.AddActorDisable(this);
		ToothPastePool.UnSpawn(ToothPaste);
	}

	UFUNCTION(BlueprintCallable)
	void StartDebugMode()
	{
		CurrentState = EDentistBossState::Debugging;
	}

	UFUNCTION(BlueprintCallable)
	void ProgressToState(EDentistBossState State)
	{
		if(State > EDentistBossState::DenturesSpawned)
		{
			LeftHandHealthComp.Die();
		}
		if(State > EDentistBossState::SpinningCake)
		{
			if(HasControl())
			{
				if(State < EDentistBossState::DenturesSpawnedTwo)
					Cake.NetStartRotating(Time::GlobalCrumbTrailTime - Math::Max(Cake.InnerTargetAccelerationDuration, Cake.OuterTargetAccelerationDuration));
			}
		}
		if(State > EDentistBossState::DenturesSpawnedTwo)
		{
			Tools[EDentistBossTool::Dentures].GetDestroyed();
			RightHandHealthComp.Die();
		}
		if(State == EDentistBossState::Chase)
		{
			AddActorDisable(this);
		}

		CurrentState = State;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		float MaskOverrideTarget = bShouldHaveMaskOverride ? 1.0 : 0.0;
		AccMaskOverride.AccelerateToWithStop(MaskOverrideTarget, 1.0, DeltaSeconds, 0.01);
		// AccMaskOverride.SnapTo(MaskOverrideTarget);
		CloseMouthMaskAgainAlpha = AccMaskOverride.Value;

		auto TempLog = TEMPORAL_LOG(this);
		TempLog
			.Value("State", f"{CurrentState}")
			.Value("Current Health", CurrentHealth)
		;

		for(int i = 0; i < ActionQueueComps.Num(); i++)
		{
			TempLog.Value(f"Queue {i}", ActionQueueComps[i]);
		}

		auto AnimPage = TempLog.Page("Animation Variables");

		AnimPage
			.Value("CurrentAnimationState", CurrentAnimationState.Get())
			.Value("LookAtEnabled", LookAtEnabled.Get())
		;

		auto IKSection = AnimPage.Section("IK");
		IKSection.Value("CurrentIKState", CurrentIKState.Get());

		IKSection.Section("Hands")
			.Transform("Left Upper Hand Transform", SkelMesh.GetSocketTransform(LeftUpperHand_IK), 1000, 10)
			.Transform("Right Upper Hand Transform", SkelMesh.GetSocketTransform(RightUpperHand_IK), 1000, 10)
			.Transform("Left Lower Hand Transform", SkelMesh.GetSocketTransform(LeftLowerHand_IK), 1000, 10)
			.Transform("Right Lower Hand Transform", SkelMesh.GetSocketTransform(RightLowerHand_IK), 1000, 10)
		;

		auto AttachSection = IKSection.Section("Attach");
		AttachSection.Section("Left Upper Attach")
			.Transform("Transform", SkelMesh.GetSocketTransform(LeftUpperAttach), 1000, 10)
			.Sphere("Relative Location", SkelMesh.GetSocketLocation(LeftUpperAttach), 50, FLinearColor::Teal, 10)
		;
		AttachSection.Section("Right Upper Attach")
			.Transform("Transform", SkelMesh.GetSocketTransform(RightUpperAttach), 1000, 10)
			.Sphere("Relative Location", SkelMesh.GetSocketLocation(RightUpperAttach), 50, FLinearColor::Teal, 10)
		;
		AttachSection.Section("Left Lower Attach")
			.Transform("Transform", SkelMesh.GetSocketTransform(LeftLowerAttach), 1000, 10)
			.Sphere("Relative Location", SkelMesh.GetSocketLocation(RightLowerAttach), 50, FLinearColor::Teal, 10)
		;
		AttachSection.Section("Right Lower Attach")
			.Transform("Transform", SkelMesh.GetSocketTransform(RightLowerAttach), 1000, 10)
			.Sphere("Relative Location", SkelMesh.GetSocketLocation(RightLowerAttach), 50, FLinearColor::Teal, 10)
		;
		AttachSection.Section("Align")
			.Transform("Transform", SkelMesh.GetSocketTransform(Align), 1000, 10)
			.Value("Cake Relative Location", Cake.ActorLocation - SkelMesh.GetSocketLocation(Align))
		;

		AnimPage.Section("Lean Blend Space")
			.Value("UseLeanBlendSpace", UseLeanBlendSpace.Get())
			.Value("LeanBlendSpaceValues", LeanBlendSpaceValues.Get())
		;
		AnimPage.Section("Chair")
			.Value("bRightPlayerEscapedChair", bRightPlayerEscapedChair)
			.Value("bLeftPlayerEscapedChair", bLeftPlayerEscapedChair)
		;
		AnimPage.Section("Drill")
			.Value("bDrillFoundPlayer", bDrillFoundPlayer)
			.Value("bDrillFinished", bDrillFinished)
			.Value("bDrillExit", bDrillExit)
			.Value("bDrillSpinArena", bDrillSpinArena)
			.Value("DrillingPlayerWobble", DrillingPlayerWobble)
		;
		AnimPage.Section("Dentures")
			.Value("bDenturesDestroyedHand", bDenturesDestroyedHand)
			.Value("DenturesBitingAlpha", DenturesBitingAlpha)
			.Value("bDenturesFellDown", bDenturesFellDown)
			.Value("bDenturesAttachedLeftHand", bDenturesAttachedLeftHand)
			.Value("bDenturesAttachedRightHand", bDenturesAttachedRightHand)
			.Value("bPreviousArmDestroyedWasLeft", bPreviousArmDestroyedWasLeft)
			.Value("bSwatLeftHand", bSwatLeftHand)
			.Value("bSwatRightHand", bSwatRightHand)
			.Transform("Dentures Transform", Tools[EDentistBossTool::Dentures].ActorTransform)
			.Value("Dentures Attach Parent", Tools[EDentistBossTool::Dentures].AttachParentActor)
			.Value("Dentures Attach Socket Name", Tools[EDentistBossTool::Dentures].AttachParentSocketName)
		;
		AnimPage.Section("Cup")
			.Value("bCupCaptureTelegraphDone", bCupCaptureTelegraphDone)
			.Value("CurrentSortType", CurrentSortType)
			.Value("CupSortAnimSpeed", CupSortAnimSpeed)
			.Value("bCupChosen", bCupChosen)
		;
		AnimPage.Section("HookHammer")
			.Value("bHookTelegraphDone", bHookTelegraphDone)
			.Value("bHammerPlayer", bHammerPlayer)
			.Value("bHammerSplitPlayer", bHammerSplitPlayer)
		;
		AnimPage.Section("Finisher")
			.Value("bFinisherButtonMashActivated", bFinisherButtonMashActivated)
			.Value("FinisherProgress", FinisherProgress)
		;
	}

	UFUNCTION(BlueprintCallable)
	void StartFinisherButtonMash()
	{
		bFinisherButtonMashActivated = true;
	}

	UFUNCTION(BlueprintCallable)
	void StopFinisherButtonMash()
	{
		bFinisherButtonMashActivated = false;
	}

	UFUNCTION(BlueprintCallable)
	void FinalChaseStarted()
	{	
		bFinalChaseStarted = true;
		UDentistBossEffectHandler::Trigger_OnDentistChaseStarted(this);
	}

	UFUNCTION(CallInEditor, Category = "Setup")
	void PlaceSkelMeshOnArena()
	{
		if(Cake == nullptr)
			return;

		SkelMesh.WorldLocation = Cake.ActorLocation;
		SkelMesh.WorldRotation = FRotator::MakeFromXZ(Cake.ActorRightVector, FVector::UpVector);
	}

	UFUNCTION(CallInEditor, Category = "Setup")
	void AttachDoubleInteractToArm()
	{
		if(FinisherDoubleInteractActor == nullptr)
			return;
		
		FinisherDoubleInteractActor.AttachToComponent(SkelMesh, n"LeftUpperHand");
		FinisherDoubleInteractActor.SetActorRotation(FRotator::MakeFromZ(FVector::UpVector));
	}

	UFUNCTION(CallInEditor, Category = "Setup")
	void AttachTools()
	{
		AttachAllTools();
		auto Dentures = TListedActors<ADentistBossToolDentures>().Single;
		Dentures.PlaceDenturesInJaw();
	}

	TArray<UHazeMovementComponent> GetPlayerMovementComponents() const
	{
		TArray<UHazeMovementComponent> MoveComps;
		for(auto Player : Game::Players)
		{
			auto MoveComp = UPlayerMovementComponent::Get(Player);
			MoveComps.Add(MoveComp);

			auto DentistSplitToothComp = UDentistToothSplitComponent::Get(Player);
			if(DentistSplitToothComp.SplitToothAI != nullptr)
			{
				auto SplitToothMoveComp = UHazeMovementComponent::Get(DentistSplitToothComp.SplitToothAI);
				MoveComps.Add(SplitToothMoveComp);
			}
		}

		return MoveComps;
	}

	void SetIKTransform(EDentistBossArm ArmToSet, FVector Location, FRotator Rotation)
	{
		FTransform NewTransform;
		NewTransform.Location = Location;
		NewTransform.Rotation = Rotation.Quaternion();
		switch(ArmToSet)
		{
			case EDentistBossArm::LeftTop:
			{
				FTransform BoneOffsetTransform = SkelMesh.GetSocketTransform(LeftUpperAttach, ERelativeTransformSpace::RTS_ParentBoneSpace);
				LeftUpperHandTargetingTransform = BoneOffsetTransform.Inverse() * NewTransform;
				TEMPORAL_LOG(this, "IK").Transform("Left Upper IK Transform", LeftUpperHandTargetingTransform, 1000.0, 10);
				break;
			}
			case EDentistBossArm::RightTop:
			{
				FTransform BoneOffsetTransform = SkelMesh.GetSocketTransform(RightUpperAttach, ERelativeTransformSpace::RTS_ParentBoneSpace);
				RightUpperHandTargetingTransform = BoneOffsetTransform.Inverse() * NewTransform;
				TEMPORAL_LOG(this, "IK").Transform("Right Upper IK Transform", RightUpperHandTargetingTransform, 1000.0, 10);
				break;
			}
			case EDentistBossArm::LeftMiddle:
			{
				FTransform BoneOffsetTransform = SkelMesh.GetSocketTransform(LeftLowerAttach, ERelativeTransformSpace::RTS_ParentBoneSpace);
				LeftLowerHandTargetingTransform = BoneOffsetTransform.Inverse() * NewTransform;
				TEMPORAL_LOG(this, "IK").Transform("Left Lower IK Transform", LeftLowerHandTargetingTransform, 1000.0, 10);
				break;
			}
			case EDentistBossArm::RightMiddle:
			{
				FTransform BoneOffsetTransform = SkelMesh.GetSocketTransform(RightLowerAttach, ERelativeTransformSpace::RTS_ParentBoneSpace);
				RightLowerHandTargetingTransform = BoneOffsetTransform.Inverse() * NewTransform;
				TEMPORAL_LOG(this, "IK").Transform("Right Lower IK Transform", RightLowerHandTargetingTransform, 1000.0, 10);
				break;
			}
			default: break;
		}
		
	}

	FTransform GetIKTransform(EDentistBossArm IKArm) const
	{
		switch(IKArm)
		{
			case EDentistBossArm::LeftTop:
			{
				FTransform BoneTransform = SkelMesh.GetSocketTransform(LeftUpperHand_IK);
				FTransform BoneOffsetTransform = SkelMesh.GetSocketTransform(LeftUpperAttach, ERelativeTransformSpace::RTS_ParentBoneSpace);
				TEMPORAL_LOG(this, "IK").Transform("Gotten Left Upper IK Transform", LeftUpperHandTargetingTransform, 1000.0, 10);
				return BoneOffsetTransform * BoneTransform;
			}
			case EDentistBossArm::RightTop:
			{
				FTransform BoneTransform = SkelMesh.GetSocketTransform(RightUpperHand_IK);
				FTransform BoneOffsetTransform = SkelMesh.GetSocketTransform(RightUpperAttach, ERelativeTransformSpace::RTS_ParentBoneSpace);
				TEMPORAL_LOG(this, "IK").Transform("Gotten Right Upper IK Transform", RightUpperHandTargetingTransform, 1000.0, 10);
				return BoneOffsetTransform * BoneTransform;
			}
			case EDentistBossArm::LeftMiddle:
			{
				FTransform BoneTransform = SkelMesh.GetSocketTransform(LeftLowerHand_IK);
				FTransform BoneOffsetTransform = SkelMesh.GetSocketTransform(LeftLowerAttach, ERelativeTransformSpace::RTS_ParentBoneSpace);
				TEMPORAL_LOG(this, "IK").Transform("Gotten Left Lower IK Transform", LeftLowerHandTargetingTransform, 1000.0, 10);
				return BoneOffsetTransform * BoneTransform;
			}
			case EDentistBossArm::RightMiddle:
			{
				FTransform BoneTransform = SkelMesh.GetSocketTransform(RightLowerHand_IK);
				FTransform BoneOffsetTransform = SkelMesh.GetSocketTransform(RightLowerAttach, ERelativeTransformSpace::RTS_ParentBoneSpace);
				TEMPORAL_LOG(this, "IK").Transform("Gotten Right Lower IK Transform", RightLowerHandTargetingTransform, 1000.0, 10);
				return BoneOffsetTransform * BoneTransform;
			}
			default: return FTransform::Identity;
		}
	}

	void ClearIKState(FInstigator Instigator)
	{
		CurrentIKState.Clear(Instigator);
		LeftUpperHandTargetingTransform = FTransform::Identity;
		RightUpperHandTargetingTransform = FTransform::Identity;
		LeftLowerHandTargetingTransform = FTransform::Identity;
		RightLowerHandTargetingTransform = FTransform::Identity;
	}

	void ToggleHandWeakpointHittable(bool bToggleOn, bool bLeftHand)
	{
		if(bToggleOn)
		{
			if(bLeftHand)
			{
				LeftHandAutoAimComp.Enable(this);
				LeftHandWeakpointMesh.RemoveComponentVisualsAndCollisionAndTickBlockers(this);
			}
			else
			{
				RightHandAutoAimComp.Enable(this);
				RightHandWeakpointMesh.RemoveComponentVisualsAndCollisionAndTickBlockers(this);
			}
		}
		else
		{
			if(bLeftHand)
			{
				LeftHandAutoAimComp.Disable(this);
				LeftHandWeakpointMesh.AddComponentVisualsAndCollisionAndTickBlockers(this);
			}
			else
			{
				RightHandAutoAimComp.Disable(this);
				RightHandWeakpointMesh.AddComponentVisualsAndCollisionAndTickBlockers(this);
			}
		}
	}
};