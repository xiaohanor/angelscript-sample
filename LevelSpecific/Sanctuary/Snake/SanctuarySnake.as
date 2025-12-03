UCLASS(Abstract, HideCategories = "InternalHiddenObjects")
class ASanctuarySnake : AHazeCameraActor
{
	UPROPERTY(DefaultComponent)
	UHazeMovementComponent MovementComponent;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComponent;
	default CapabilityComponent.DefaultCapabilities.Add(n"SanctuarySnakeMovementCapability");
	default CapabilityComponent.DefaultCapabilities.Add(n"SanctuarySnakeHeadRotationCapability");
	default CapabilityComponent.DefaultCapabilities.Add(n"SanctuarySnakeTailCapability");
	default CapabilityComponent.DefaultCapabilities.Add(n"SanctuarySnakeEatCapability");
	default CapabilityComponent.DefaultCapabilities.Add(n"SanctuarySnakeSplineFollowCapability");
	default CapabilityComponent.DefaultCapabilities.Add(n"SanctuarySnakeShootCapability");
	default CapabilityComponent.DefaultCapabilities.Add(n"SanctuarySnakeMoveToTargetCapability");
	default CapabilityComponent.DefaultCapabilities.Add(n"SanctuarySnakePlayerDamageCapability");
//	default CapabilityComponent.DefaultCapabilities.Add(n"SanctuarySnakeSelfCollisionCapability");
	default CapabilityComponent.DefaultCapabilities.Add(n"SanctuarySnakeBurrowCapability");

	UPROPERTY(DefaultComponent, RootComponent)
	USphereComponent WorldCollision;	

	UPROPERTY(DefaultComponent, Attach = WorldCollision)
	USceneComponent Pivot;

	UPROPERTY(DefaultComponent, Attach = Pivot)
	UHazeSkeletalMeshComponentBase SkeletalMeshComponent;

	UPROPERTY(DefaultComponent, Attach = Pivot)
	UBasicAIProjectileLauncherComponent ProjectileLauncherComponent;

	UPROPERTY(DefaultComponent, Attach = Pivot)
	USceneComponent RiderAttachpoint;

	UPROPERTY(DefaultComponent, Attach = WorldCollision)
	UHazeOffsetComponent CameraOffsetComponent;

	UPROPERTY(DefaultComponent, ShowOnActor)
	UCameraWeightedTargetComponent FocusTargetComponent;
	default FocusTargetComponent.EmptyTargetDefaultType = ECameraWeightedTargetEmptyInitType::DefaultToBothPlayers;

	UPROPERTY(OverrideComponent = Camera, ShowOnActor)
	UFocusTargetCamera Camera;

	UPROPERTY(DefaultComponent, Attach = Pivot)
	USpringArmCamera RiderCamera;

	UPROPERTY(DefaultComponent)
	UHazeRequestCapabilityOnPlayerComponent RequestComponent;

	UPROPERTY()
	USanctuarySnakeSettings DefaultSettings;

	UPROPERTY(DefaultComponent)
	USanctuarySnakeComponent SanctuarySnakeComponent;

	UPROPERTY(DefaultComponent)
	USanctuarySnakeTailComponent TailComponent;

	UPROPERTY(DefaultComponent)
	USanctuarySnakeSplineFollowComponent SplineFollowComponent;

	UPROPERTY(DefaultComponent)
	USanctuarySnakeBurrowComponent BurrowComponent;

//	bool bHasRider = false;
//	FVector GravityDirection = -FVector::UpVector;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		Camera.AttachToComponent(CameraOffsetComponent, NAME_None, EAttachmentRule::KeepRelative);
	}

	UFUNCTION(BlueprintOverride)
	void PrepareUpdaterForUser(const UHazeCameraUserComponent HazeUser, UHazeCameraUpdater CameraData, FHazeCameraTransform CameraTransform) const
	{
		auto KeepInViewData = Cast<UCameraFocusTargetUpdater>(CameraData);
		auto& Settings = KeepInViewData.UpdaterSettings;
		Settings.Init(HazeUser);
	
		#if EDITOR

		if(CameraData.Type == EHazeCameraUpdaterType::EditorPreview)
		{
			KeepInViewData.FocusTargets = FocusTargetComponent.GetEditorPreviewTargets();
			KeepInViewData.PrimaryTargets = FocusTargetComponent.GetEditorPreviewPrimaryTargets();
		}
		else
		#endif
		{
			auto PlayerOwner = HazeUser.GetPlayerOwner();
			if(PlayerOwner != nullptr)
			{
				KeepInViewData.FocusTargets = FocusTargetComponent.GetFocusTargets(PlayerOwner);
				KeepInViewData.PrimaryTargets = FocusTargetComponent.GetPrimaryTargetsOnly(PlayerOwner);
			}
		}

		KeepInViewData.UseFocusLocation();		
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{	
		ApplyDefaultSettings(DefaultSettings);

		// Setup the resolver
		{
			UMovementResolverSettings::SetMaxRedirectIterations(this, 3, this, EHazeSettingsPriority::Defaults);
			UMovementResolverSettings::SetMaxDepenetrationIterations(this, 2, this, EHazeSettingsPriority::Defaults);
		}

		// Override the gravity settings
		{
			UMovementGravitySettings::SetGravityScale(this, 3, this, EHazeSettingsPriority::Defaults);
		}

		// Everything is sliding
		{
			UMovementStandardSettings::SetWalkableSlopeAngle(this, 120.0, this, EHazeSettingsPriority::Defaults);		
		}

		// Set up ground trace
		{
			//UMovementSweepingSettings::SetCanLeaveGround(this, false, this, EHazeSettingsPriority::Defaults);
		}	
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{

	}

	UFUNCTION()
	void ResetTrail()
	{
		TailComponent.ResetTail(ActorForwardVector, ActorUpVector);
	}

	UFUNCTION()
	void FollowSpline(UObject Spline)
	{
		SplineFollowComponent.SetSplineToFollow(Spline);
		SplineFollowComponent.bFollowSpline = true;
		FTransform TransformAtDistance = SplineFollowComponent.Spline.GetWorldTransformAtSplineDistance(0.0);
		SetActorLocationAndRotation(TransformAtDistance.Location, TransformAtDistance.Rotation);
	}

	UFUNCTION()
	void FollowTarget(AActor Target)
	{
		SanctuarySnakeComponent.Target = Target;
		SanctuarySnakeComponent.bFollowTarget = true;
	}

	UFUNCTION(DevFunction)
	void StartSanctuarySnake()
	{
		BlockCapabilities(n"SanctuarySnakePlayerDamage", this);

		for (auto Player : Game::Players)
		{
			auto SanctuarySnakeRiderComponent = USanctuarySnakeRiderComponent::Get(Player);
			if (SanctuarySnakeRiderComponent != nullptr)
				SanctuarySnakeRiderComponent.Snake = this;

			RequestComponent.StartInitialSheetsAndCapabilities(Player, this);
		}
	}

	UFUNCTION(DevFunction)
	void StopSanctuarySnake()
	{
		UnblockCapabilities(n"SanctuarySnakePlayerDamage", this);

		for (auto Player : Game::Players)
		{
			RequestComponent.StopInitialSheetsAndCapabilities(Player, this);
		}
	}
}