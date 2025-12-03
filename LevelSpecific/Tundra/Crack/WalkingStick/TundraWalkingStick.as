enum ETundraWalkingStickState
{
	None,
	Rising,
	Walking,
	Falling,
	CrashInWall,
	CrashWithLegs
}

struct FTundraWalkingStickAnimData
{
	UPROPERTY(BlueprintReadOnly)
	bool bWalkFaster = false;

	UPROPERTY(BlueprintReadOnly)
	bool bHitReactionFromLeft = false;

	UPROPERTY(BlueprintReadOnly)
	bool bHitReactionFromFront = false;

	UPROPERTY(BlueprintReadOnly)
	bool bHitReactionFromRight = false;
	
	UPROPERTY(BlueprintReadOnly)
	float WalkPlayRate;

	UPROPERTY(BlueprintReadOnly)
	float WalkFasterPlayRate;

	UPROPERTY(BlueprintReadOnly)
	float SteerInput;

	void SetCurrentSpeed(float CurrentSpeed)
	{
		WalkPlayRate = CurrentSpeed / 5000.0;
		WalkFasterPlayRate = CurrentSpeed / 7000.0;
	}
}

struct FTundraWalkingStickHitReactionInstigatorData
{
	FInstigator Instigator;
	float TimeOfTrigger;
	float Duration;
}

struct FTundraWalkingStickAttachActorHipsParams
{
	UPROPERTY()
	AActor Actor;

	UPROPERTY()
	EAttachmentRule LocationAttachmentRule = EAttachmentRule::KeepWorld;
}

enum ETundraWalkingStickHitReactionType
{
	Left,
	Front,
	Right
}

asset TundraWalkingStickBlendAsset of UCameraDefaultBlend
{
	bIncludeLocationVelocity = true;
}

event void FTundraWalkingStickEventNoParams();

UCLASS(Abstract)
class ATundraWalkingStick : AHazeActor
{
	default PrimaryActorTick.bStartWithTickEnabled = false;

	access ReadOnly = private, * (readonly);

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach=Root)
	USceneComponent CameraRoot;

	UPROPERTY(DefaultComponent, Attach=CameraRoot)
	UHazeCameraComponent EntAttackedCam;

	UPROPERTY(EditInstanceOnly)
	ATundraWalkingStickFrontInteract FrontInteractRef;

	UPROPERTY(EditInstanceOnly)
	ATundraGroundedLifeGivingActor LifeGivingActorRef;

	UPROPERTY(EditAnywhere)
	bool bRespawnSpider = true;

	UPROPERTY(EditAnywhere)
	bool bGameplaySpider = false;

	UPROPERTY(EditAnywhere)
	float TreeAttackedBlendDuration = 2.0;

	UPROPERTY(EditAnywhere)
	float WalkingStickSpeed = 5600.0;

	UPROPERTY(EditAnywhere)
	float WalkingStickAccelerationDuration = 3.0;

	UPROPERTY(EditAnywhere)
	float ScreamChargeUpDuration = 0.5;

	/* If -forward of walking stick is within this angle of the normal of the hit object the walking stick will die, otherwise it will steer to be facing parallel to the wall surface */
	UPROPERTY(EditAnywhere)
	float DeathAngleThreshold = 25.0;

	/* If -forward of walking stick is within this angle of the normal of the hit object (by the legs) the walking stick will die, otherwise it will steer to be facing parallel to the wall surface */
	UPROPERTY(EditAnywhere)
	float DeathCrashWithLegsAngleThreshold = 35.0;

	UPROPERTY(EditAnywhere)
	float TurnInputSpeed = 10.0;

	UPROPERTY(EditAnywhere)
	float AutoSteerTurnSpeed = 10.0;

	UPROPERTY(EditAnywhere)
	FHazeRange SpeedEffectSpeedRange = FHazeRange(5000.0, 7000.0);

	UPROPERTY(EditAnywhere)
	FHazeRange SpeedEffectAmountRange = FHazeRange(0.6, 1.0);

	/* After this amount of seconds has elapsed since we started contacting a specific wall impact actor we will trigger a fail */
	UPROPERTY(EditAnywhere)
	float WallImpactDelayUntilFail = 3.0;

	UPROPERTY(EditInstanceOnly)
	TArray<FTundraWalkingStickAttachActorHipsParams> ActorsToAttachToHips;

	UPROPERTY(EditInstanceOnly)
	TArray<AActor> ActorsToSetLocationToHips;

	UPROPERTY(EditInstanceOnly)
	TArray<ASplineActor> AutoSteerSplines;

	UPROPERTY(DefaultComponent)
	UHazeMovementAudioComponent MoveAudioComp;

	TArray<FTransform> ActorsToSetLocationRelativeTransform;

	UPROPERTY()
	float RootRiseHeightOffset = 6000.0;

	UPROPERTY()
	FRuntimeFloatCurve RiseInterpolation;
	default RiseInterpolation.AddDefaultKey(0.0, 0.0);
	default RiseInterpolation.AddDefaultKey(1.0, 1.0);

	UPROPERTY()
	UClass CharacterABP;

	UPROPERTY()
	UAnimSequence IdleAnimation;

	UPROPERTY()
	UAnimSequence CrashInWallAnimation;

	UPROPERTY()
	UAnimSequence CrashWithLegsFallRightAnimation;

	UPROPERTY()
	UAnimSequence CrashWithLegsFallLeftAnimation;

	UPROPERTY()
	UAnimSequence FallingAnimation;

	UPROPERTY()
	UNiagaraSystem TheShootVFX;

	float StickScreamMaxLength = 30000;

	bool bMakeAIsFlee = false;

	UPROPERTY(DefaultComponent)
	UHazeCharacterSkeletalMeshComponent Mesh;
	default Mesh.RelativeLocation = FVector(0.0, 0.0, 0.0);
	default Mesh.CollisionProfileName = n"NoCollision";

	UPROPERTY(DefaultComponent, Attach = Mesh, AttachSocket = "LeftHand")
	USceneComponent LeftFrontLegCrashWithLegsTraceLocation;
	default LeftFrontLegCrashWithLegsTraceLocation.RelativeRotation = FRotator(0.0, 90.0, 180.0);

	UPROPERTY(DefaultComponent, Attach = Mesh, AttachSocket = "RightHand")
	USceneComponent RightFrontLegCrashWithLegsTraceLocation;
	default RightFrontLegCrashWithLegsTraceLocation.RelativeRotation = FRotator(0.0, -90.0, 180.0);

	UPROPERTY(DefaultComponent, Attach = Mesh, AttachSocket = "LeftFrontFoot")
	USceneComponent LeftSecondLegCrashWithLegsTraceLocation;
	default LeftSecondLegCrashWithLegsTraceLocation.RelativeRotation = FRotator(0.0, 90.0, 180.0);

	UPROPERTY(DefaultComponent, Attach = Mesh, AttachSocket = "RightFrontFoot")
	USceneComponent RightSecondLegCrashWithLegsTraceLocation;
	default RightSecondLegCrashWithLegsTraceLocation.RelativeRotation = FRotator(0.0, -90.0, 180.0);

	UPROPERTY(DefaultComponent, Attach = Mesh, AttachSocket = "Hips")
	USceneComponent CenterHitTraceLocation;

	UPROPERTY(DefaultComponent, Attach = Mesh, AttachSocket = "Hips")
	USceneComponent VFXShootLocation;

	UPROPERTY(DefaultComponent, Attach = Mesh, AttachSocket = "Hips")
	UHazeCameraComponent RisingCamera;
	default RisingCamera.RelativeLocation = FVector(-5030.0, 0.0, 5000.0);
	default RisingCamera.RelativeRotation = FRotator(-30.0, 0.0, 0.0);

	UPROPERTY(DefaultComponent, Attach = "Mesh", AttachSocket = "LeftHand")
	UTundraGnatEntryScenepointComponent LeftFrontScenepoint;
	default LeftFrontScenepoint.RelativeLocation = FVector(-20.0, 3.0, 2330.0);

	UPROPERTY(DefaultComponent, Attach = "Mesh", AttachSocket = "LeftHand")
	UTundraGnapeEntryWayPoint LeftHandWaypoint0;
	default LeftHandWaypoint0.ScenepointSocket = n"LeftHand";
	default LeftHandWaypoint0.Order = 0;

	UPROPERTY(DefaultComponent, Attach = "Mesh", AttachSocket = "LeftHand")
	UTundraGnapeEntryWayPoint LeftHandWaypoint1;
	default LeftHandWaypoint1.ScenepointSocket = n"LeftHand";
	default LeftHandWaypoint1.Order = 1;

	UPROPERTY(DefaultComponent, Attach = "Mesh", AttachSocket = "LeftForeArm")
	UTundraGnapeEntryWayPoint LeftForeArmWaypoint0;
	default LeftForeArmWaypoint0.ScenepointSocket = n"LeftHand";
	default LeftForeArmWaypoint0.Order = 10;

	UPROPERTY(DefaultComponent, Attach = "Mesh", AttachSocket = "LeftForeArm")
	UTundraGnapeEntryWayPoint LeftForeArmWaypoint1;
	default LeftForeArmWaypoint1.ScenepointSocket = n"LeftHand";
	default LeftForeArmWaypoint1.Order = 11;

	UPROPERTY(DefaultComponent, Attach = "Mesh", AttachSocket = "LeftForeArm")
	UTundraGnapeEntryWayPoint LeftForeArmWaypoint2;
	default LeftForeArmWaypoint2.ScenepointSocket = n"LeftHand";
	default LeftForeArmWaypoint2.Order = 12;

	UPROPERTY(DefaultComponent, Attach = "Mesh", AttachSocket = "LeftArm")
	UTundraGnapeEntryWayPoint LeftArmWaypoint0;
	default LeftArmWaypoint0.ScenepointSocket = n"LeftHand";
	default LeftArmWaypoint0.Order = 20;

	UPROPERTY(DefaultComponent, Attach = "Mesh", AttachSocket = "LeftArm")
	UTundraGnapeEntryWayPoint LeftArmWaypoint1;
	default LeftArmWaypoint1.ScenepointSocket = n"LeftHand";
	default LeftArmWaypoint1.Order = 21;

	UPROPERTY(DefaultComponent, Attach = "Mesh", AttachSocket = "Hips")
	UTundraGnapeEntryWayPoint LeftFrontBodyWaypoint0;
	default LeftFrontBodyWaypoint0.ScenepointSocket = n"LeftHand";
	default LeftFrontBodyWaypoint0.Order = 30;

	UPROPERTY(DefaultComponent, Attach = "Mesh", AttachSocket = "Hips")
	UTundraGnapeEntryWayPoint LeftFrontBodyWaypoint1;
	default LeftFrontBodyWaypoint1.ScenepointSocket = n"LeftHand";
	default LeftFrontBodyWaypoint1.Order = 31;

	UPROPERTY(DefaultComponent, Attach = "Mesh", AttachSocket = "Hips")
	UTundraGnapeEntryWayPoint LeftFrontBodyWaypoint2;
	default LeftFrontBodyWaypoint2.ScenepointSocket = n"LeftHand";
	default LeftFrontBodyWaypoint2.Order = 32;

	UPROPERTY(DefaultComponent, Attach = "Mesh", AttachSocket = "Hips")
	UTundraGnapeEntryWayPoint LeftFrontBodyWaypoint3;
	default LeftFrontBodyWaypoint3.ScenepointSocket = n"LeftHand";
	default LeftFrontBodyWaypoint3.Order = 33;

	UPROPERTY(DefaultComponent, Attach = "Mesh", AttachSocket = "LeftFrontFoot")
	UTundraGnatEntryScenepointComponent LeftFrontMiddleScenepoint;
	default LeftFrontMiddleScenepoint.RelativeLocation = FVector(5.0, 17.0, 2200.0);
	default LeftFrontMiddleScenepoint.RelativeRotation = FRotator(-90.0, 0.0, 0.0);

	UPROPERTY(DefaultComponent, Attach = "Mesh", AttachSocket = "LeftFrontFoot")
	UTundraGnapeEntryWayPoint LeftFootWaypoint0;
	default LeftFootWaypoint0.ScenepointSocket = n"LeftFrontFoot";
	default LeftFootWaypoint0.Order = 0;

	UPROPERTY(DefaultComponent, Attach = "Mesh", AttachSocket = "LeftFrontFoot")
	UTundraGnapeEntryWayPoint LeftFootWaypoint1;
	default LeftFootWaypoint1.ScenepointSocket = n"LeftFrontFoot";
	default LeftFootWaypoint1.Order = 1;

	UPROPERTY(DefaultComponent, Attach = "Mesh", AttachSocket = "LeftFrontLeg")
	UTundraGnapeEntryWayPoint LeftLegWaypoint0;
	default LeftLegWaypoint0.ScenepointSocket = n"LeftFrontFoot";
	default LeftLegWaypoint0.Order = 10;

	UPROPERTY(DefaultComponent, Attach = "Mesh", AttachSocket = "LeftFrontLeg")
	UTundraGnapeEntryWayPoint LeftLegWaypoint1;
	default LeftLegWaypoint1.ScenepointSocket = n"LeftFrontFoot";
	default LeftLegWaypoint1.Order = 11;

	UPROPERTY(DefaultComponent, Attach = "Mesh", AttachSocket = "LeftFrontLeg")
	UTundraGnapeEntryWayPoint LeftLegWaypoint2;
	default LeftLegWaypoint2.ScenepointSocket = n"LeftFrontFoot";
	default LeftLegWaypoint2.Order = 12;

	UPROPERTY(DefaultComponent, Attach = "Mesh", AttachSocket = "LeftFrontUpLeg")
	UTundraGnapeEntryWayPoint LeftUpLegWaypoint0;
	default LeftUpLegWaypoint0.ScenepointSocket = n"LeftFrontFoot";
	default LeftUpLegWaypoint0.Order = 20;

	UPROPERTY(DefaultComponent, Attach = "Mesh", AttachSocket = "LeftFrontUpLeg")
	UTundraGnapeEntryWayPoint LeftUpLegWaypoint1;
	default LeftUpLegWaypoint1.ScenepointSocket = n"LeftFrontFoot";
	default LeftUpLegWaypoint1.Order = 21;

	UPROPERTY(DefaultComponent, Attach = "Mesh", AttachSocket = "Hips")
	UTundraGnapeEntryWayPoint LeftMiddleBodyWaypoint0;
	default LeftMiddleBodyWaypoint0.ScenepointSocket = n"LeftFrontFoot";
	default LeftMiddleBodyWaypoint0.Order = 30;

	UPROPERTY(DefaultComponent, Attach = "Mesh", AttachSocket = "Hips")
	UTundraGnapeEntryWayPoint LeftMiddleBodyWaypoint1;
	default LeftMiddleBodyWaypoint1.ScenepointSocket = n"LeftFrontFoot";
	default LeftMiddleBodyWaypoint1.Order = 31;

	UPROPERTY(DefaultComponent, Attach = "Mesh", AttachSocket = "Hips")
	UTundraGnapeEntryWayPoint LeftMiddleBodyWaypoint2;
	default LeftMiddleBodyWaypoint2.ScenepointSocket = n"LeftFrontFoot";
	default LeftMiddleBodyWaypoint2.Order = 32;

	UPROPERTY(DefaultComponent, Attach = "Mesh", AttachSocket = "Hips")
	UTundraGnapeEntryWayPoint LeftMiddleBodyWaypoint3;
	default LeftMiddleBodyWaypoint3.ScenepointSocket = n"LeftFrontFoot";
	default LeftMiddleBodyWaypoint3.Order = 33;

	UPROPERTY(DefaultComponent, Attach = "Mesh", AttachSocket = "RightHand")
	UTundraGnatEntryScenepointComponent RightFrontScenepoint;
	default RightFrontScenepoint.RelativeLocation = FVector(-20.0, 24.0, 2330.0);
	default RightFrontScenepoint.RelativeRotation = FRotator(-90.0, 0.0, 0.0);

	UPROPERTY(DefaultComponent, Attach = "Mesh", AttachSocket = "RightHand")
	UTundraGnapeEntryWayPoint RightHandWaypoint0;
	default RightHandWaypoint0.ScenepointSocket = n"RightHand";
	default RightHandWaypoint0.Order = 0;

	UPROPERTY(DefaultComponent, Attach = "Mesh", AttachSocket = "RightHand")
	UTundraGnapeEntryWayPoint RightHandWaypoint1;
	default RightHandWaypoint1.ScenepointSocket = n"RightHand";
	default RightHandWaypoint1.Order = 1;

	UPROPERTY(DefaultComponent, Attach = "Mesh", AttachSocket = "RightForeArm")
	UTundraGnapeEntryWayPoint RightForeArmWaypoint0;
	default RightForeArmWaypoint0.ScenepointSocket = n"RightHand";
	default RightForeArmWaypoint0.Order = 10;

	UPROPERTY(DefaultComponent, Attach = "Mesh", AttachSocket = "RightForeArm")
	UTundraGnapeEntryWayPoint RightForeArmWaypoint1;
	default RightForeArmWaypoint1.ScenepointSocket = n"RightHand";
	default RightForeArmWaypoint1.Order = 11;

	UPROPERTY(DefaultComponent, Attach = "Mesh", AttachSocket = "RightForeArm")
	UTundraGnapeEntryWayPoint RightForeArmWaypoint2;
	default RightForeArmWaypoint2.ScenepointSocket = n"RightHand";
	default RightForeArmWaypoint2.Order = 12;

	UPROPERTY(DefaultComponent, Attach = "Mesh", AttachSocket = "RightArm")
	UTundraGnapeEntryWayPoint RightArmWaypoint0;
	default RightArmWaypoint0.ScenepointSocket = n"RightHand";
	default RightArmWaypoint0.Order = 20;

	UPROPERTY(DefaultComponent, Attach = "Mesh", AttachSocket = "RightArm")
	UTundraGnapeEntryWayPoint RightArmWaypoint1;
	default RightArmWaypoint1.ScenepointSocket = n"RightHand";
	default RightArmWaypoint1.Order = 21;

	UPROPERTY(DefaultComponent, Attach = "Mesh", AttachSocket = "Hips")
	UTundraGnapeEntryWayPoint RightFrontBodyWaypoint0;
	default RightFrontBodyWaypoint0.ScenepointSocket = n"RightHand";
	default RightFrontBodyWaypoint0.Order = 30;

	UPROPERTY(DefaultComponent, Attach = "Mesh", AttachSocket = "Hips")
	UTundraGnapeEntryWayPoint RightFrontBodyWaypoint1;
	default RightFrontBodyWaypoint1.ScenepointSocket = n"RightHand";
	default RightFrontBodyWaypoint1.Order = 31;

	UPROPERTY(DefaultComponent, Attach = "Mesh", AttachSocket = "Hips")
	UTundraGnapeEntryWayPoint RightFrontBodyWaypoint2;
	default RightFrontBodyWaypoint2.ScenepointSocket = n"RightHand";
	default RightFrontBodyWaypoint2.Order = 32;

	UPROPERTY(DefaultComponent, Attach = "Mesh", AttachSocket = "Hips")
	UTundraGnapeEntryWayPoint RightFrontBodyWaypoint3;
	default RightFrontBodyWaypoint3.ScenepointSocket = n"RightHand";
	default RightFrontBodyWaypoint3.Order = 33;

	UPROPERTY(DefaultComponent, Attach = "Mesh", AttachSocket = "RightFrontFoot")
	UTundraGnatEntryScenepointComponent RightFrontMiddleScenepoint;
	default RightFrontMiddleScenepoint.RelativeLocation = FVector(-5.0, -10.0, 2200.0);
	default RightFrontMiddleScenepoint.RelativeRotation = FRotator(-90.0, 0.0, 0.0);

	UPROPERTY(DefaultComponent, Attach = "Mesh", AttachSocket = "RightFrontFoot")
	UTundraGnapeEntryWayPoint RightFootWaypoint0;
	default RightFootWaypoint0.ScenepointSocket = n"RightFrontFoot";
	default RightFootWaypoint0.Order = 0;

	UPROPERTY(DefaultComponent, Attach = "Mesh", AttachSocket = "RightFrontFoot")
	UTundraGnapeEntryWayPoint RightFootWaypoint1;
	default RightFootWaypoint1.ScenepointSocket = n"RightFrontFoot";
	default RightFootWaypoint1.Order = 1;

	UPROPERTY(DefaultComponent, Attach = "Mesh", AttachSocket = "RightFrontLeg")
	UTundraGnapeEntryWayPoint RightLegWaypoint0;
	default RightLegWaypoint0.ScenepointSocket = n"RightFrontFoot";
	default RightLegWaypoint0.Order = 10;

	UPROPERTY(DefaultComponent, Attach = "Mesh", AttachSocket = "RightFrontLeg")
	UTundraGnapeEntryWayPoint RightLegWaypoint1;
	default RightLegWaypoint1.ScenepointSocket = n"RightFrontFoot";
	default RightLegWaypoint1.Order = 11;

	UPROPERTY(DefaultComponent, Attach = "Mesh", AttachSocket = "RightFrontLeg")
	UTundraGnapeEntryWayPoint RightLegWaypoint2;
	default RightLegWaypoint2.ScenepointSocket = n"RightFrontFoot";
	default RightLegWaypoint2.Order = 12;

	UPROPERTY(DefaultComponent, Attach = "Mesh", AttachSocket = "RightFrontUpLeg")
	UTundraGnapeEntryWayPoint RightUpLegWaypoint0;
	default RightUpLegWaypoint0.ScenepointSocket = n"RightFrontFoot";
	default RightUpLegWaypoint0.Order = 20;

	UPROPERTY(DefaultComponent, Attach = "Mesh", AttachSocket = "RightFrontUpLeg")
	UTundraGnapeEntryWayPoint RightUpLegWaypoint1;
	default RightUpLegWaypoint1.ScenepointSocket = n"RightFrontFoot";
	default RightUpLegWaypoint1.Order = 21;

	UPROPERTY(DefaultComponent, Attach = "Mesh", AttachSocket = "Hips")
	UTundraGnapeEntryWayPoint RightMiddleBodyWaypoint0;
	default RightMiddleBodyWaypoint0.ScenepointSocket = n"RightFrontFoot";
	default RightMiddleBodyWaypoint0.Order = 30;

	UPROPERTY(DefaultComponent, Attach = "Mesh", AttachSocket = "Hips")
	UTundraGnapeEntryWayPoint RightMiddleBodyWaypoint1;
	default RightMiddleBodyWaypoint1.ScenepointSocket = n"RightFrontFoot";
	default RightMiddleBodyWaypoint1.Order = 31;

	UPROPERTY(DefaultComponent, Attach = "Mesh", AttachSocket = "Hips")
	UTundraGnapeEntryWayPoint RightMiddleBodyWaypoint2;
	default RightMiddleBodyWaypoint2.ScenepointSocket = n"RightFrontFoot";
	default RightMiddleBodyWaypoint2.Order = 32;

	UPROPERTY(DefaultComponent, Attach = "Mesh", AttachSocket = "Hips")
	UTundraGnapeEntryWayPoint RightMiddleBodyWaypoint3;
	default RightMiddleBodyWaypoint3.ScenepointSocket = n"RightFrontFoot";
	default RightMiddleBodyWaypoint3.Order = 33;

	UPROPERTY(DefaultComponent, Attach = "Mesh", AttachSocket = "Hips")
	UTundraGnatHostComponent HostComp;

	UPROPERTY(DefaultComponent)
	UTundraWalkingStickMovementComponent MoveComp;
	default MoveComp.bCanRerunMovement = true;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"TundraWalkingStickMovementCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"TundraWalkingStickRiseMovementCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"TundraWalkingStickDeathCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"TundraWalkingStickFallCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"TundraWalkingStickIdleCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"TundraWalkingStickRiseCameraCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"TundraWalkingStickCrashInWallCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"TundraWalkingStickCrashWithLegsCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"TundraWalkingStickActorSetLocationCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"TundraWalkingStickChargeScreamCapability");

	UPROPERTY(DefaultComponent, Attach = "Mesh", AttachSocket = "Hips")
	USphereComponent Collision;
	default Collision.CollisionProfileName = n"PlayerCharacterIgnorePawn";

	UPROPERTY(DefaultComponent)
	UTundraLifeReceivingComponent LifeReceivingComponent;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedActorComp;

	UPROPERTY(DefaultComponent)
	UTundraWalkingStickVisualizerDummyComponent VisualizerDummyComp;
	
	UPROPERTY(EditAnywhere)
	TSubclassOf<UCameraShakeBase> CamShakeScream;

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedActorPositionComponent SyncedPosition;
	default SyncedPosition.SyncDetailLevel = EHazeActorPositionSyncDetailLevel::Player;

	UPROPERTY(DefaultComponent, Attach = "Mesh", AttachSocket = "Hips")
	USceneComponent NosePosition;
	default NosePosition.RelativeLocation = FVector(6000.0, 0.0, 0.0);

	UPROPERTY(NotVisible, BlueprintReadOnly)
	access:ReadOnly ETundraWalkingStickState CurrentState = ETundraWalkingStickState::None;

	UPROPERTY(NotVisible, BlueprintReadOnly)
	access:ReadOnly ETundraWalkingStickState PreviousState = ETundraWalkingStickState::None;

	UPROPERTY(NotVisible, BlueprintReadOnly)
	bool bIsDead = false;

	FTundraWalkingStickAnimData AnimData;

	bool bMoveFaster = false;
	float FasterSpeedAccelerationDuration;
	float FasterTargetSpeed;
	bool bTreeGuardianInteracting = false;
	ETundraWalkingStickCrashWithLegsType CurrentCrashWithLegsType;

	TInstigated<bool> HitReactionLeft;
	TInstigated<bool> HitReactionFront;
	TInstigated<bool> HitReactionRight;
	TArray<FTundraWalkingStickHitReactionInstigatorData> HitReactionInstigators;
	TArray<FInstigator> AutoSteerInstigators;
	TOptional<float> TimeOfStartChargingScream;

	FTutorialPrompt ChargeScreamTutorial;
	default ChargeScreamTutorial.Action = ActionNames::SecondaryLevelAbility;
	default ChargeScreamTutorial.Text = NSLOCTEXT("WalkingStick", "ChargeScream", "Charge scream");
	default ChargeScreamTutorial.DisplayType = ETutorialPromptDisplay::ActionHold;

	FTutorialPrompt ReleaseScreamTutorial;
	default ReleaseScreamTutorial.Action = ActionNames::SecondaryLevelAbility;
	default ReleaseScreamTutorial.Text = NSLOCTEXT("WalkingStick", "Scream", "Scream");
	default ReleaseScreamTutorial.DisplayType = ETutorialPromptDisplay::ActionRelease;

	bool bChargeScreamTutorialShown = false;
	bool bScreamHasEverBeenCalled = false;

	bool bReleaseScreamTutorialShown = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if(bGameplaySpider)
		{
			WalkingStick::WalkingStickAutoSteer.MakeVisible();
			SetActorControlSide(Game::Zoe);
			SyncedPosition.OverrideControlSide(Game::Zoe);
			SyncedPosition.OverrideSyncRate(EHazeCrumbSyncRate::PlayerSynced);
			UTundraWalkingStickContainerComponent::GetOrCreate(Game::Mio).WalkingStick = this;

			LifeGivingActorRef.LifeReceivingComp.OnInteractStart.AddUFunction(this, n"OnEnterInteract");
			LifeGivingActorRef.LifeReceivingComp.OnInteractStop.AddUFunction(this, n"OnExitInteract");
			SetCollisionMode(true);
		}

		for(FTundraWalkingStickAttachActorHipsParams Params : ActorsToAttachToHips)
		{
			Params.Actor.AttachToComponent(Mesh, n"Hips", Params.LocationAttachmentRule);
		}

		FTransform HipsTransform = Mesh.GetSocketTransform(n"Hips");
		for(AActor Actor : ActorsToSetLocationToHips)
		{
			ActorsToSetLocationRelativeTransform.Add(Actor.ActorTransform.GetRelativeTransform(HipsTransform));
			MoveComp.AddMovementIgnoresActor(this, Actor);
		}

		Mesh.SetAnimClass(CharacterABP);

		if(bRespawnSpider)
			AddActorDisable(this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		CheckHitReactionClear();
	}

	UFUNCTION(BlueprintEvent)
	private void SetCollisionMode(bool bComplex) {}

	UFUNCTION()
	private void OnEnterInteract(bool bForced)
	{
		bTreeGuardianInteracting = true;
		if(CurrentState == ETundraWalkingStickState::None)
			ShowScreamTutorial();
	}

	UFUNCTION()
	private void OnExitInteract(bool bForced)
	{
		bTreeGuardianInteracting = false;
	}

	// I am doing this since there is a bug where the bp wont compile if I try to call Super. Luke is working on it
	UFUNCTION(BlueprintCallable)
	void CallThisFromConstructionScript()
	{
		#if EDITOR
		if(bGameplaySpider)
		{
			Mesh.EditorOnlyOverrideAnimationData(IdleAnimation, true, true, 0.0, 0.0);
		}
		else
		{
			Mesh.SetAnimClass(CharacterABP);
		}
		#endif
	}

	void ShowScreamTutorial()
	{
		if(bChargeScreamTutorialShown)
			return;

		Game::Zoe.ShowTutorialPrompt(ChargeScreamTutorial, this);
		bChargeScreamTutorialShown = true;
	}

	void ShowReleaseTutorial()
	{
		if(bReleaseScreamTutorialShown)
			return;

		Game::Zoe.ShowTutorialPrompt(ReleaseScreamTutorial, this);
		bReleaseScreamTutorialShown = true;
	}

	
	void ClearReleaseTutorial()
	{
		if(!bReleaseScreamTutorialShown)
			return;

		Game::Zoe.RemoveTutorialPromptByInstigator(this);
		bReleaseScreamTutorialShown = false;
	}


	void ClearScreamTutorial()
	{
		if(!bChargeScreamTutorialShown)
			return;

		Game::Zoe.RemoveTutorialPromptByInstigator(this);
		bChargeScreamTutorialShown = false;
	}

	UFUNCTION(BlueprintCallable)
	void PlayScream()
	{
		if(CurrentState == ETundraWalkingStickState::None)
		{
			ClearReleaseTutorial();
			ClearScreamTutorial();
			StartWalkingStick(ETundraWalkingStickState::Rising, true);
		}
		else
		{
			bScreamHasEverBeenCalled = true;
		}

		Game::GetZoe().PlayCameraShake(CamShakeScream, this);

		Niagara::SpawnOneShotNiagaraSystemAtLocation(TheShootVFX, VFXShootLocation.WorldLocation, ActorForwardVector.Rotation());
		FHitResult Hit = TraceForObstacles(VFXShootLocation.WorldLocation);
		FTundraWalkingStickScreamEffectParams Params;
		Params.ScreamHit = Hit;

		if(!Hit.bBlockingHit)
			UTundraWalkingStickEffectHandler::Trigger_OnScreamNoTarget(this, Params);
		else if(Hit.Actor == nullptr) // Since obstacles are destroyed the actor will always be null.
			UTundraWalkingStickEffectHandler::Trigger_OnScreamObstacleTarget(this, Params);
		else
			UTundraWalkingStickEffectHandler::Trigger_OnScreamGenericTarget(this, Params);
		
		FrontInteractRef.BP_ScreamWasCalled();
		UTundraWalkingStickFrontInteractEventHandler::Trigger_ScreamStarted(FrontInteractRef);
	}

	// Traces for obstacles and will return the first hit result (even though all hit results will be hit)
	UFUNCTION(BlueprintCallable)
	FHitResult TraceForObstacles(FVector StartLocation)
	{
		FHazeTraceSettings Trace;
		Trace = Trace::InitChannel(ETraceTypeQuery::Visibility);
		Trace.IgnoreActor(this);
		Trace.DebugDraw(10.0);
		Trace.UseLine();
		// Trace.DebugDraw(20.0);
		// Debug::DrawDebugSphere(StartLocation + ActorForwardVector * 30000, 2000, Thickness = 50, Duration = 10);

		FHitResultArray HitResults = Trace.QueryTraceMulti(StartLocation, StartLocation + ActorForwardVector * StickScreamMaxLength);

		TOptional<FHitResult> Hit;

		for(int i = 0; i < HitResults.Num(); i++)
		{
			auto Result = HitResults[i];
			if(Result.Actor == nullptr)
				continue;

			if(!Hit.IsSet())
				Hit.Set(Result);

			auto TundraStickObstacle = Cast<ATundraStickObstacle>(Result.Actor);

			if (TundraStickObstacle != nullptr)
			{
				if(!Hit.IsSet() || !Hit.Value.Actor.IsA(ATundraStickObstacle))
					Hit.Set(Result);

				TundraStickObstacle.BreakObstacle();
			}
		}

		FHitResult DefaultHit;
		DefaultHit.TraceStart = StartLocation;
		DefaultHit.TraceEnd = StartLocation + ActorForwardVector * StickScreamMaxLength;
		return Hit.Get(DefaultHit);
	}

	UFUNCTION(BlueprintCallable)
	void TeleportStickToPosition(ATundraWalkingStick RespawnSpiderRef, bool bStartAfterTeleporting = true, bool bStartWithBlend = false)
	{
		TeleportActor(RespawnSpiderRef.ActorLocation, RespawnSpiderRef.ActorRotation, this);

		if(bStartAfterTeleporting)
			StartWalkingStick(ETundraWalkingStickState::Walking, bStartWithBlend);
	}

	UFUNCTION(BlueprintCallable)
	void StartWalkingStick(ETundraWalkingStickState StartState, bool bWithBlend = false)
	{
		devCheck(CurrentState == ETundraWalkingStickState::None, "Walking stick is already started, cannot start again!");
		devCheck(StartState != ETundraWalkingStickState::None, "Starting state cannot be none when starting walking stick");
		ChangeState(StartState);

		if(bGameplaySpider)
		{
			TListedActors<ATundraWalkingStick> ListedActors;
			for(auto ListedActor : ListedActors)
			{
				if(ListedActor == this)
					continue;

				ListedActor.StartWalkingStick(ETundraWalkingStickState::Walking, bWithBlend);
			}

			OnStartGameplayWalkingStick(bWithBlend);
			SetCollisionMode(false);

			if(!bWithBlend)
				return;

			for(AHazePlayerCharacter Player : Game::Players)
			{
				// Bit wonky because freeze location does not inherit velocity of follows
				Player.MeshOffsetComponent.FreezeRelativeTransformAndLerpBackToParent(this, Collision, 1.0);
				UPlayerMovementComponent::Get(Player).Reset();
			}
		}
	}

	UFUNCTION(BlueprintPure)
	bool IsChargingScream() const
	{
		return TimeOfStartChargingScream.IsSet();
	}

	/* Returns an alpha between 0 and 1 that determines how charged the scream is. If the scream is currently not charging it will return -1.0 */
	UFUNCTION(BlueprintPure)
	float GetScreamChargeAlpha() const
	{
		if(!TimeOfStartChargingScream.IsSet())
			return -1.0;

		float TimeSinceStartChargeUp = Time::GetGameTimeSince(TimeOfStartChargingScream.Value);
		float Alpha = TimeSinceStartChargeUp / (ScreamChargeUpDuration / 0.7);
		Alpha = Math::Saturate(Alpha);
		return Alpha;
	}

	UFUNCTION()
	void DebugTriggerWalking()
	{
		ChangeState(ETundraWalkingStickState::Walking);
	}

	UFUNCTION()
	void TriggerCrashWithLegs(ETundraWalkingStickCrashWithLegsType CrashWithLegsType)
	{
		if(WalkingStick::WalkingStickInvulnerable.IsEnabled())
			return;

		CurrentCrashWithLegsType = CrashWithLegsType;
		ChangeState(ETundraWalkingStickState::CrashWithLegs);
	}

	UFUNCTION(DevFunction)
	void MakeAIsFlee()
	{
		bMakeAIsFlee = true;
	}

	UFUNCTION(DevFunction)
	void StopAIsFleeing()
	{
		bMakeAIsFlee = false;
	}

	UFUNCTION(BlueprintCallable)
	void StopWalkingStick()
	{
		if(bGameplaySpider)
		{
			ChangeState(ETundraWalkingStickState::None);
			// OnStopGameplayWalkingStick();
		}
		else
		{
			ChangeState(ETundraWalkingStickState::None);
		}
	}

	UFUNCTION(BlueprintCallable)
	void EnableAutoSteering(FInstigator Instigator)
	{
		AutoSteerInstigators.AddUnique(Instigator);
	}

	UFUNCTION(BlueprintCallable)
	void DisableAutoSteering(FInstigator Instigator)
	{
		AutoSteerInstigators.RemoveSingleSwap(Instigator);
	}

	UFUNCTION(BlueprintPure)
	bool IsAutoSteering() const
	{
		if(WalkingStick::WalkingStickAutoSteer.IsEnabled())
			return true;

		return AutoSteerInstigators.Num() > 0;
	}

	FSplinePosition GetClosestAutoSteerSplinePosition()
	{
		FSplinePosition ClosestSplinePosition;
		float ClosestDistance = MAX_flt;
		for(auto Spline : AutoSteerSplines)
		{
			FSplinePosition SplinePosition = Spline.Spline.GetClosestSplinePositionToWorldLocation(ActorLocation);
			float Distance = SplinePosition.WorldLocation.DistSquared(ActorLocation);

			if(Distance < ClosestDistance)
			{
				ClosestDistance = Distance;
				ClosestSplinePosition = SplinePosition;
			}
		}

		return ClosestSplinePosition;
	}

	void ChangeState(ETundraWalkingStickState NewState)
	{
		devCheck(NewState != CurrentState, "Trying to change to a state the walking stick is already in");
		PreviousState = CurrentState;
		CurrentState = NewState;
		OnChangeState(NewState);
	}

	UFUNCTION()
	void StartMovingFaster(float SpeedMultiplier = 1.2, float LerpDuration = 0.5)
	{
		FasterSpeedAccelerationDuration = LerpDuration;
		FasterTargetSpeed = WalkingStickSpeed * SpeedMultiplier;
		bMoveFaster = true;
		AnimData.bWalkFaster = true;
	}

	UFUNCTION(DevFunction)
	void DevMove30PercentFaster()
	{
		StartMovingFaster(1.3);
	}

	UFUNCTION(DevFunction)
	void DevMove50PercentFaster()
	{
		StartMovingFaster(1.5);
	}

	UFUNCTION(DevFunction)
	void DevMove60PercentFaster()
	{
		StartMovingFaster(1.6);
	}

	UFUNCTION()
	void TriggerHitReaction(FInstigator Instigator, FVector Forward)
	{
#if !RELEASE
		for(int i = 0; i < HitReactionInstigators.Num(); i++)
		{
			if(HitReactionInstigators[i].Instigator == Instigator)
			{
				devError("Tried to trigger a hit reaction with the same instigator");
				return;
			}
		}
#endif

		FVector LocalForward = Mesh.GetSocketTransform(n"Hips").InverseTransformVectorNoScale(Forward);
		if(Math::Abs(LocalForward.X) > Math::Abs(LocalForward.Y))
		{
			HitReactionFront.Apply(true, Instigator);
		}
		else
		{
			if(LocalForward.Y >= 0.0)
				HitReactionRight.Apply(true, Instigator);
			else
				HitReactionLeft.Apply(true, Instigator);
		}

		FTundraWalkingStickHitReactionInstigatorData Data;
		Data.Instigator = Instigator;
		Data.Duration = 0.1;
		Data.TimeOfTrigger = Time::GetGameTimeSeconds();
		HitReactionInstigators.Add(Data);
		UpdateHitReactionAnimData();
		SetActorTickEnabled(true);
	}

	UFUNCTION()
	void TriggerHitReactionWithType(FInstigator Instigator, ETundraWalkingStickHitReactionType HitReactionType)
	{
#if !RELEASE
		for(int i = 0; i < HitReactionInstigators.Num(); i++)
		{
			if(HitReactionInstigators[i].Instigator == Instigator)
			{
				devError("Tried to trigger a hit reaction with the same instigator");
				return;
			}
		}
#endif

		if(HitReactionType == ETundraWalkingStickHitReactionType::Left)
			HitReactionLeft.Apply(true, Instigator);
		else if(HitReactionType == ETundraWalkingStickHitReactionType::Front)
			HitReactionFront.Apply(true, Instigator);
		else if(HitReactionType == ETundraWalkingStickHitReactionType::Right)
			HitReactionRight.Apply(true, Instigator);
		else
			devError("Forgot to add a case that handles walking stick hit reaction enum");

		FTundraWalkingStickHitReactionInstigatorData Data;
		Data.Instigator = Instigator;
		Data.Duration = 0.1;
		Data.TimeOfTrigger = Time::GetGameTimeSeconds();
		HitReactionInstigators.Add(Data);
		UpdateHitReactionAnimData();
		SetActorTickEnabled(true);
	}

	// This should run in tick
	private void CheckHitReactionClear()
	{
		for(int i = 0; i < HitReactionInstigators.Num(); ++i)
		{	
			FTundraWalkingStickHitReactionInstigatorData Data = HitReactionInstigators[i];
			if(Time::GetGameTimeSince(Data.TimeOfTrigger) > Data.Duration)
			{
				HitReactionLeft.Clear(Data.Instigator);
				HitReactionFront.Clear(Data.Instigator);
				HitReactionRight.Clear(Data.Instigator);
				HitReactionInstigators.RemoveAt(i);
				UpdateHitReactionAnimData();
				--i;
			}
		}

		if(HitReactionInstigators.Num() == 0)
			SetActorTickEnabled(false);
	}

	UFUNCTION(BlueprintPure)
	float GetTargetSpeed() const property
	{
		if(!bGameplaySpider)
			return WalkingStickSpeed;

		if(!bTreeGuardianInteracting)
			return 3000.0;

		if(bMoveFaster)
			return FasterTargetSpeed;

		return WalkingStickSpeed;
	}

	private void UpdateHitReactionAnimData()
	{
		AnimData.bHitReactionFromFront = HitReactionFront.Get();
		AnimData.bHitReactionFromLeft = HitReactionLeft.Get();
		AnimData.bHitReactionFromRight = HitReactionRight.Get();
	}

	UFUNCTION(BlueprintEvent, NotBlueprintCallable)
	void OnStartGameplayWalkingStick(bool bWithBlend) {}

	UFUNCTION(BlueprintEvent, NotBlueprintCallable)
	void OnStopGameplayWalkingStick() {}

	UFUNCTION(BlueprintEvent, NotBlueprintCallable)
	void OnChangeState(ETundraWalkingStickState NewState) {}

	UFUNCTION(BlueprintEvent, NotBlueprintCallable)
	void OnRisingFinalExit() {}

	UFUNCTION(BlueprintEvent, NotBlueprintCallable)
	void OnWalkingStickDeath(bool bGameplayWalkingStick) {}

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnActorModifiedInEditor()
	{
		// TODO: Would be nice to keep entry splines "attached" to hips, so they follow along when you change starting animation etc
	}
#endif
}

UCLASS(NotPlaceable)
class UTundraWalkingStickVisualizerDummyComponent : UActorComponent
{
	default bIsEditorOnly = true;
}

class UTundraWalkingStickVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UTundraWalkingStickVisualizerDummyComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		auto WalkingStick = Cast<ATundraWalkingStick>(Component.Owner);

		for(FTundraWalkingStickAttachActorHipsParams Params : WalkingStick.ActorsToAttachToHips)
		{
			if(Params.Actor == nullptr)
				continue;

			DrawWireSphere(Params.Actor.ActorLocation, 300.0, FLinearColor::Red, 5);
			DrawWorldString("Attached to hips", Params.Actor.ActorLocation, FLinearColor::Red);
		}
	}
}