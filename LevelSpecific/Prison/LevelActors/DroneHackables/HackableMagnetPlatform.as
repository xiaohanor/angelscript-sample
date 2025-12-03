class AHackableMagnetPlatform : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent PlatformRoot;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"HackableMagnetPlatformCapability");

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent PlatformTarget;

	UPROPERTY(DefaultComponent)
	UHazeMovementComponent MoveComp;

	UPROPERTY()
	float ForwardMove;

	UPROPERTY(DefaultComponent)
	USwarmDroneHijackTargetableComponent HijackTargetableComp;

	UPROPERTY(DefaultComponent, Attach = PlatformRoot)
	UHazeCameraComponent CameraComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		CapabilityInput::LinkActorToPlayerInput(this, Drone::GetSwarmDronePlayer());
	}
}

class UHackableMagnetPlatformCapability: UHazeCapability
{
	default CapabilityTags.Add(n"Example");
	
	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 104;

	AHazePlayerCharacter Player;

	UHazeMovementComponent MoveComp;
	UHazeMovementComponent PlayerMoveComp;
	USteppingMovementData Movement;

	AHackableMagnetPlatform Platform;

	float MovementSpeed = 1000.0;
	float RotationSpeed = 100.0;

	float CurrentVelocity = 0.0;
	float CurrentRotationSpeed = 0.0;

	float Speed;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Platform = Cast<AHackableMagnetPlatform>(Owner);
		Player = Drone::GetSwarmDronePlayer();

		MoveComp = UHazeMovementComponent::Get(Owner);
		PlayerMoveComp = UHazeMovementComponent::Get(Player);
		Movement = MoveComp.SetupSteppingMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{		
		if (MoveComp.HasMovedThisFrame())
			return false;

		if (!Platform.HijackTargetableComp.IsHijacked())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;

		if (!Platform.HijackTargetableComp.IsHijacked())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.ActivateCamera(Platform.CameraComp,1, this);
		//Player.AttachToActor(Platform, NAME_None, EAttachmentRule::KeepWorld);

		PlayerMoveComp.FollowComponentMovement(Platform.RootComp, this, EMovementFollowComponentType::ResolveCollision);

		// Player.ApplyCameraSettings(Platform.HackedCamSettings, 2, this, EHazeCameraPriority::Medium);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.DeactivateCamera(Platform.CameraComp, 1);
		Drone::GetSwarmDronePlayer().SnapCameraBehindPlayer();
		Player.ClearCameraSettingsByInstigator(this, 1.0);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector2D Input = GetAttributeVector2D(AttributeVectorNames::MovementRaw);

		// Platform.PlatformRoot.AddRelativeLocation(FVector(Input.X * 1000 * DeltaTime,0,0));

		if (!MoveComp.PrepareMove(Movement))
			return;

		// float VerticalInput = 0.0;
		// if (IsActioning(ActionNames::PrimaryLevelAbility))
		// 	VerticalInput += 1.0;
		// if (IsActioning(ActionNames::SecondaryLevelAbility))
		//  	VerticalInput -= 1.0;

		// FVector Input = PlayerMoveComp.MovementInput;



		Speed = Math::FInterpTo(Speed,Input.X*500, DeltaTime, 5); 

		FVector DeltaMove = (Platform.ActorForwardVector * Speed * DeltaTime);


		// DeltaMove +=  + Platform.ActorRightVector * Input.Y * 800 * DeltaTime;

		// Platform.ForwardMove = Input.X;

		//DeltaMove = FVector(Input.X * 800.0 * DeltaTime, Input.Y * 800.0 * DeltaTime,0);
		// DeltaMove.Y += VerticalInput * 400.0 * DeltaTime;

		Movement.AddDelta(DeltaMove);

		MoveComp.ApplyMove(Movement);

	}
}