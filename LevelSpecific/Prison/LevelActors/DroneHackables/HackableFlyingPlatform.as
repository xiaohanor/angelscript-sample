class AHackableFlyingPlatform : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent PlatformRoot;

	UPROPERTY(DefaultComponent, Attach = PlatformRoot)
	UBoxComponent CollisionComp;
	default CollisionComp.CollisionProfileName = n"BlockAllDynamic";

	UPROPERTY(DefaultComponent, Attach = PlatformRoot)
	USwarmDroneHijackTargetableComponent HijackTargetableComp;

	UPROPERTY(DefaultComponent)
	UHazeMovementComponent MoveComp;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"HackableFlyingPlatformCapability");

	UPROPERTY(EditDefaultsOnly)
	UHazeCameraSpringArmSettingsDataAsset HackedCamSettings;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		CapabilityInput::LinkActorToPlayerInput(this, Drone::GetSwarmDronePlayer());
	}
}

class UHackableFlyingPlatformCapability : UHazeCapability
{
	default CapabilityTags.Add(n"Example");
	
	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 5;

	AHackableFlyingPlatform FlyingPlatform;
	AHazePlayerCharacter Player;

	UHazeMovementComponent MoveComp;
	UHazeMovementComponent PlayerMoveComp;
	USteppingMovementData Movement;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		FlyingPlatform = Cast<AHackableFlyingPlatform>(Owner);
		Player = Drone::GetSwarmDronePlayer();

		MoveComp = UHazeMovementComponent::Get(Owner);
		PlayerMoveComp = UHazeMovementComponent::Get(Player);
		Movement = MoveComp.SetupSteppingMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!FlyingPlatform.HijackTargetableComp.IsHijacked())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!FlyingPlatform.HijackTargetableComp.IsHijacked())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		// Player.AttachToActor(FlyingPlatform, NAME_None, EAttachmentRule::KeepWorld);
		PlayerMoveComp.FollowComponentMovement(FlyingPlatform.RootComp,this, EMovementFollowComponentType::Teleport);
		Player.ApplyCameraSettings(FlyingPlatform.HackedCamSettings, 2, this, EHazeCameraPriority::Medium);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.ClearCameraSettingsByInstigator(this, 1.0);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (!MoveComp.PrepareMove(Movement))
			return;

		float VerticalInput = 0.0;
		if (IsActioning(ActionNames::PrimaryLevelAbility))
			VerticalInput += 1.0;
		if (IsActioning(ActionNames::SecondaryLevelAbility))
		 	VerticalInput -= 1.0;

		FVector Input = PlayerMoveComp.MovementInput;

		FVector DeltaMove = Input * 800.0 * DeltaTime;
		DeltaMove.Z += VerticalInput * 400.0 * DeltaTime;

		Movement.AddDelta(DeltaMove);

		MoveComp.ApplyMove(Movement);
	}
}