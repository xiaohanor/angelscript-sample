UCLASS(HideCategories = "InternalHiddenObjects")
class AHackableMagnetWall : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent PlatformRoot;

	UPROPERTY(DefaultComponent, Attach = PlatformRoot)
	UBoxComponent CollisionComp;
	default CollisionComp.CollisionProfileName = n"BlockAllDynamic"; //d

	UPROPERTY(DefaultComponent, Attach = PlatformRoot)
	USwarmDroneHijackTargetableComponent HijackTargetableComp;

	UPROPERTY(DefaultComponent)
	UHazeMovementComponent MoveComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USpringArmCamera CameraComp;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"HackableMagnetWallCapability");

	UPROPERTY(EditDefaultsOnly)
	UHazeCameraSpringArmSettingsDataAsset HackedCamSettings;

	FVector Start = ActorLocation;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		CapabilityInput::LinkActorToPlayerInput(this, Drone::GetSwarmDronePlayer());
		Start = ActorLocation;
	}
}

class UHackableMagnetWallCapability : UHazeCapability
{
	default CapabilityTags.Add(n"Example");
	
	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 5;

	AHackableMagnetWall MagnetWall;
	AHazePlayerCharacter Player;

	UHazeMovementComponent MoveComp;
	UHazeMovementComponent PlayerMoveComp;
	USteppingMovementData Movement;

	UFUNCTION(BlueprintOverride) 
	void Setup()
	{
		MagnetWall = Cast<AHackableMagnetWall>(Owner);
		Player = Drone::GetSwarmDronePlayer();
		
		MoveComp = UHazeMovementComponent::Get(Owner);
		PlayerMoveComp = UHazeMovementComponent::Get(Player);
		Movement = MoveComp.SetupSteppingMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!MagnetWall.HijackTargetableComp.IsHijacked())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!MagnetWall.HijackTargetableComp.IsHijacked())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.ActivateCamera(MagnetWall.CameraComp,1, this);
		PlayerMoveComp.FollowComponentMovement(MagnetWall.RootComp,this, EMovementFollowComponentType::Teleport);
		Player.ApplyCameraSettings(MagnetWall.HackedCamSettings, 2, this, EHazeCameraPriority::Medium);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.DeactivateCamera(MagnetWall.CameraComp, 1);
		Drone::GetSwarmDronePlayer().SnapCameraBehindPlayer();
		Player.ClearCameraSettingsByInstigator(this, 1.0);
		MagnetWall.ActorLocation = MagnetWall.Start;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (!MoveComp.PrepareMove(Movement))
			return;

		// float VerticalInput = 0.0;
		// if (IsActioning(ActionNames::PrimaryLevelAbility))
		// 	VerticalInput += 1.0;
		// if (IsActioning(ActionNames::SecondaryLevelAbility))
		// 	VerticalInput -= 1.0;

		//FVector VerticalInput = PlayerMoveComp.MovementInput.X;

		FVector Input = PlayerMoveComp.MovementInput;

		FVector DeltaMove = Input * 800.0 * DeltaTime;

		DeltaMove.Y = 0;

		Movement.AddDelta(DeltaMove);

		MoveComp.ApplyMove(Movement);
	}
}