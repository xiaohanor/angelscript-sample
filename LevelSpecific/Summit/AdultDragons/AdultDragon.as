UCLASS(Abstract, NotPlaceable)
class AAdultDragon : AHazeCharacter
{
	UPROPERTY(DefaultComponent, EditDefaultsOnly)
	UHazeCapabilityComponent CapabilityComponent;

	default Mesh.RelativeLocation = FVector(-150.0, 0.0, 0.0);
	default Mesh.ShadowPriority = EShadowPriority::Player;
	default Mesh.VisibilityBasedAnimTickOption = EVisibilityBasedAnimTickOption::AlwaysTickPoseAndRefreshBones;

	default CapsuleComponent.RelativeLocation = FVector(0.0, 0.0, 200.0);
	default CapsuleComponent.CapsuleHalfHeight = 200.0;
	default CapsuleComponent.CapsuleRadius = 200.0;
	default CapsuleComponent.CollisionProfileName = n"PlayerCharacter";
	default CapsuleComponent.bGenerateOverlapEvents = false;
	default CapsuleComponent.SetCollisionEnabled(ECollisionEnabled::PhysicsOnly);

	private AHazePlayerCharacter Player;

	USceneComponent AttachComp;

	FVector CachedMeshOffsetCompLocation;
	FVector CachedMeshCompLocation;
	bool bDelayAttachmentInRidingCapability = false;

	// TODO: (FL) Apply from somewhere else
	UPROPERTY(EditDefaultsOnly, Category = "Settings")
	UAdultDragonInputCameraSettings InputCameraSettings;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player.ApplyDefaultSettings(InputCameraSettings);

		UPlayerAdultDragonComponent DragonComp = GetDragonComponent();
		AttachComp = USceneComponent::Create(this, n"PlayerAttachComponent");
		AttachComp.AttachToComponent(Mesh, DragonComp.PlayerAttachSocket, EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, EAttachmentRule::KeepRelative, true);
		AttachComp.SetRelativeLocation(DragonComp.AttachmentOffset);
	}

	void SetControllingPlayer(AHazePlayerCharacter Rider)
	{
		Player = Rider;
	}

	bool IsAcidDragon() const
	{
		return Player == Game::Mio;
	}

	bool IsTailDragon() const
	{
		return Player == Game::Zoe;
	}

	UPlayerAdultDragonComponent GetDragonComponent() const property
	{
		return UPlayerAdultDragonComponent::Get(Player);
	}

	UFUNCTION()
	void AttachPlayerToDragonAfterIntroSequence()
	{
		AttachRootComponentTo(Player.RootComponent, NAME_None, EAttachLocation::SnapToTarget, true);

		Player.MeshOffsetComponent.AttachToComponent(Mesh, n"None", EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, EAttachmentRule::KeepRelative, true);
		Player.MeshOffsetComponent.SnapToRelativeTransform(this, AttachComp, FTransform::Identity);
		Player.MeshOffsetComponent.SetWorldScale3D(FVector(1.0, 1.0, 1.0));

		MeshOffsetComponent.RelativeLocation = CachedMeshOffsetCompLocation;
		Mesh.RelativeLocation = CachedMeshCompLocation;

		bDelayAttachmentInRidingCapability = false;
	}

	UFUNCTION()
	void DetachPlayerFromDragonBeforeIntroSequence()
	{
		DetachRootComponentFromParent();

		Player.GetMeshOffsetComponent().ClearOffset(this);
		Player.MeshOffsetComponent.AttachToComponent(Player.RootOffsetComponent, n"None", EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, EAttachmentRule::KeepRelative, true);
		Player.MeshOffsetComponent.SetRelativeTransform(FTransform::Identity);
		Player.MeshOffsetComponent.SetWorldScale3D(FVector(1.0, 1.0, 1.0));

		CachedMeshOffsetCompLocation = MeshOffsetComponent.RelativeLocation;
		CachedMeshCompLocation = Mesh.RelativeLocation;

		MeshOffsetComponent.RelativeLocation = FVector::ZeroVector;
		Mesh.RelativeLocation = FVector::ZeroVector;

		bDelayAttachmentInRidingCapability = true;
	}

	UFUNCTION()
	void SetWingTrailEffectActive(bool bIsActive)
	{
		BP_WingTrailActive(bIsActive);
	}

	UFUNCTION(BlueprintEvent)
	void BP_WingTrailActive(bool bIsActive) {}
};