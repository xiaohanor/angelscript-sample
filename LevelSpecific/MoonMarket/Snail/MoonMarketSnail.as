UCLASS(Abstract)
class AMoonMarketSnail : AMoonMarketInteractableActor
{
	default InteractableTag = EMoonMarketInteractableTag::Vehicle;
	default bCancelByThunder = true;
	default CompatibleInteractions.Add(EMoonMarketInteractableTag::Balloon);
	default CompatibleInteractions.Add(EMoonMarketInteractableTag::FlowerHat);
	default CompatibleInteractions.Add(EMoonMarketInteractableTag::Lantern);
	
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USphereComponent MovementCollisionComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeCharacterSkeletalMeshComponent SkelMeshComp;
	//UPoseableMeshComponent MeshComp;

	UPROPERTY(DefaultComponent, Attach = SkelMeshComp, AttachSocket = "Shell")
	USceneComponent RiderPosition;

	UPROPERTY(DefaultComponent, Attach = Root, AttachSocket = "Shell")
	USphereComponent ShellCollission;

	UPROPERTY(DefaultComponent)
	UHazeRequestCapabilityOnPlayerComponent RequestComp;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"MoonMarketSnailMovementCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"MoonMarketSnailIdleCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"MoonMarketSnailMoveHomeCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"MoonMarketNPCStunCapability");

	UPROPERTY(DefaultComponent)
	UPolymorphResponseComponent PolymorphResponseComp;

	UPROPERTY(DefaultComponent)
	UMoonMarketPolymorphAutoAimComponent PolymorphAutoAimComp;

	UPROPERTY(DefaultComponent)
	UMoonMarketThunderStruckComponent ThunderStruckComp;

	UPROPERTY(DefaultComponent)
	UFireworksResponseComponent FireworkResponseComp;

	UPROPERTY(DefaultComponent)
	UMoonMarketNPCStunComponent StunComponent;
	default StunComponent.FireworkStunDuration = 1;

	UPROPERTY(DefaultComponent)
	UHazeMovementComponent MoveComp;

	UPROPERTY(DefaultComponent)
	UMoonMarketSnailTrailComponent TrailComp;

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedActorPositionComponent SyncedPositionComp;
	default SyncedPositionComp.SyncDetailLevel = EHazeActorPositionSyncDetailLevel::Character;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;

	UPROPERTY(EditDefaultsOnly)
	const TPerPlayer<FHazePlaySlotAnimationParams> RideAnimationEnter;

	UPROPERTY(EditDefaultsOnly)
	const TPerPlayer<FHazePlaySlotAnimationParams> RideAnimation;

	FQuat OriginalSpineRelativeRotation;

	UPROPERTY(EditAnywhere)
	const float MoveSpeed = 100;

	UPROPERTY(EditAnywhere)
	const float RotateSpeed = 0.4;

	FVector OriginalPosition;
	bool bIsHome = true;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		OriginalPosition = ActorLocation;
		MoveComp.SetupShapeComponent(MovementCollisionComp);
		MoveComp.ApplyResolverExtension(UMoonMarketYarnBallMovementResolverExtension, this);

		PolymorphResponseComp.OnPolymorphTriggered.AddUFunction(this, n"OnPolymorphed");
		PolymorphResponseComp.OnUnmorphed.AddUFunction(this, n"OnUnmorphed");
		FireworkResponseComp.OnFireWorksImpact.AddUFunction(this, n"OnFireworkHit");
		//OriginalSpineRelativeRotation = MeshComp.GetBoneRotationByName(n"Spine1", EBoneSpaces::ComponentSpace).Quaternion();

		MoveComp.ApplySplineCollision(TListedActors<AMoonMarketSnailSplineCollisionManager>().Single.CollisionSplines, this);

		InteractComp.AttachToComponent(RiderPosition);
	}
	
	private void OnInteractionStarted(UInteractionComponent InteractionComponent,
	                                  AHazePlayerCharacter Player) override
	{
		Super::OnInteractionStarted(InteractionComponent, Player);
		auto SnailComp = UMoonMarketRideSnailComponent::Get(Player);
		SnailComp.Snail = this;
		SnailComp.RideStartTime = Time::GameTimeSeconds;

		SkelMeshComp.bEnableUpdateRateOptimizations = false;
		UMoonMarketSnailRiderEventHandler::Trigger_OnStartRidingSnail(Player, FMoonMarketSnailEventParams(Player, this));
		UMoonMarketSnailEventHandler::Trigger_OnPlayerStartRide(this, FMoonMarketSnailPlayerParams(Player));
	}

	private void OnInteractionStopped(AHazePlayerCharacter Player) override
	{
		UMoonMarketSnailRiderEventHandler::Trigger_OnStopRidingSnail(Player, FMoonMarketSnailEventParams(Player, this));
		UMoonMarketSnailEventHandler::Trigger_OnPlayerStopRide(this, FMoonMarketSnailPlayerParams(Player));
		UMoonMarketRideSnailComponent::Get(Player).Snail = nullptr;
		Super::OnInteractionStopped(Player);

		SkelMeshComp.bEnableUpdateRateOptimizations = true;
	}
	
	UFUNCTION()
	private void OnUnmorphed()
	{
		InteractComp.Enable(this);
	}

	UFUNCTION()
	private void OnFireworkHit(FMoonMarketFireworkImpactData Data)
	{
		SkelMeshComp.PlaySlotAnimation(ThunderStruckComp.ThunderStruckAnimation);
	}

	UFUNCTION()
	private void OnPolymorphed()
	{
		StopInteraction(InteractingPlayer);
		InteractComp.Disable(this);
	}
};