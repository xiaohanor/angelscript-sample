class AHackableWater : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent MeshComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent WaterComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent TargetLocation;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USwarmDroneHijackTargetableComponent HijackTargetableComp;

	UPROPERTY(DefaultComponent)
	UHazeMovementComponent MoveComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UHazeCameraComponent CameraComp;

	UPROPERTY()
	float MoveOffset;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"HackableWatarCapability");

	UPROPERTY(EditDefaultsOnly)
	UHazeCameraSpringArmSettingsDataAsset HackedCamSettings;

	FVector WaterStartLocation;

	// So we can keep track of the old copied settings
	UPROPERTY(EditAnywhere, Category = "InternalHiddenObjects")
	protected bool bInternalHasAppliedSettings = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		WaterStartLocation = WaterComp.RelativeLocation;

		CapabilityInput::LinkActorToPlayerInput(this, Drone::GetSwarmDronePlayer());
		WaterStartLocation = WaterComp.RelativeLocation;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (MoveOffset == 0)
			WaterComp.RelativeLocation = Math::VInterpConstantTo(WaterComp.RelativeLocation, WaterStartLocation, DeltaSeconds, 250);
	}
}

class UHackableWatarCapability : UHazeCapability
{
	default CapabilityTags.Add(n"Example");
	
	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 5;

	AHackableWater Water;
	AHazePlayerCharacter Player;

	UHazeMovementComponent MoveComp;
	UHazeMovementComponent PlayerMoveComp;
	// USteppingMovementData Movement;

	UFUNCTION(BlueprintOverride) 
	void Setup()
	{
		Water = Cast<AHackableWater>(Owner);
		Player = Drone::GetSwarmDronePlayer();
		
		MoveComp = UHazeMovementComponent::Get(Owner);
		PlayerMoveComp = UHazeMovementComponent::Get(Player);
		// Movement = MoveComp.SetupSteppingMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Water.HijackTargetableComp.IsHijacked())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!Water.HijackTargetableComp.IsHijacked())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.ActivateCamera(Water.CameraComp,1, this);
		Player.AttachToActor(Water, NAME_None, EAttachmentRule::KeepWorld);
		Player.ApplyCameraSettings(Water.HackedCamSettings, 2, this, EHazeCameraPriority::Medium);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.DeactivateCamera(Water.CameraComp, 1);
		Drone::GetSwarmDronePlayer().SnapCameraBehindPlayer();
		Player.ClearCameraSettingsByInstigator(this, 1.0);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// if (!MoveComp.PrepareMove(Movement))
		// 	return;

		FVector2D Input = GetAttributeVector2D(AttributeVectorNames::MovementRaw);
		Print("waterspeed "+Input);

		Water.MoveOffset = Input.X * -1;
		//Water.WaterComp.AddLocalOffset(FVector(0,0, Input.X * DeltaTime*100));

		Water.WaterComp.RelativeLocation = Math::VInterpConstantTo(Water.WaterComp.RelativeLocation, Water.TargetLocation.RelativeLocation, DeltaTime,Input.X * -1000);

		// FVector DeltaMove = FVector(0,0,Input * 800.0 * DeltaTime);
	}
}