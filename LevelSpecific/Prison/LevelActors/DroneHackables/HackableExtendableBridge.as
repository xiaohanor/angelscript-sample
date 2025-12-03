class AHackableExtendableBridge : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent PlatformRoot;

	UPROPERTY(DefaultComponent, Attach = PlatformRoot)
	USwarmDroneHijackTargetableComponent HijackTargetableComp;

	UPROPERTY(DefaultComponent)
	UHazeMovementComponent MoveComp;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"HackableExtendableBridgeCapability");

	UPROPERTY(EditDefaultsOnly)
	UHazeCameraSpringArmSettingsDataAsset HackedCamSettings;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		CapabilityInput::LinkActorToPlayerInput(this, Drone::GetSwarmDronePlayer());
	}
}

class UHackableExtendableBridgeCapability : UHazeCapability
{
	default CapabilityTags.Add(n"Example");
	
	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 5;

	AHackableExtendableBridge ExtandableBridge;
	AHazePlayerCharacter Player;

	UHazeMovementComponent MoveComp;
	UHazeMovementComponent PlayerMoveComp;
	USteppingMovementData Movement;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		ExtandableBridge = Cast<AHackableExtendableBridge>(Owner);
		Player = Drone::GetSwarmDronePlayer();

		MoveComp = UHazeMovementComponent::Get(Owner);
		PlayerMoveComp = UHazeMovementComponent::Get(Player);
		Movement = MoveComp.SetupSteppingMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!ExtandableBridge.HijackTargetableComp.IsHijacked())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!ExtandableBridge.HijackTargetableComp.IsHijacked())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		// Player.AttachToActor(ExtandableBridge, NAME_None, EAttachmentRule::KeepWorld);
		Player.ApplyCameraSettings(ExtandableBridge.HackedCamSettings, 2, this, EHazeCameraPriority::Medium);
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

		//  float VerticalInput = 0.0;
		//  if (IsActioning(ActionNames::PrimaryLevelAbility))
		// 	VerticalInput += 1.0;
		//  if (IsActioning(ActionNames::SecondaryLevelAbility))
		//  	VerticalInput -= 1.0;

		FVector Input = PlayerMoveComp.MovementInput;

		FVector DeltaMove = Input * 800.0 * DeltaTime;
		//  DeltaMove.Z += VerticalInput * 400.0 * DeltaTime;

		Movement.AddDelta(DeltaMove);

		MoveComp.ApplyMove(Movement);
	}
}