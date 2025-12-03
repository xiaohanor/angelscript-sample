class AHackableForklift : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent FortliftRoot;

	UPROPERTY(DefaultComponent, Attach = FortliftRoot)
	UBoxComponent CollisionComp;
	default CollisionComp.RelativeLocation = FVector(0.0, 0.0, 100.0);
	default CollisionComp.BoxExtent = FVector(150.0, 75.0, 100.0);
	default CollisionComp.CollisionProfileName = n"BlockAllDynamic";


	// UPROPERTY(DefaultComponent, Attach = RootComp)
	// UHazeCameraComponent CameraComp;


	// default CameraComp.RelativeLocation = FVector(-615.0, 0.0, 500.0);
	// default CameraComp.RelativeRotation = FRotator(-15.0, 0.0, 0.0);

	UPROPERTY(DefaultComponent, Attach = FortliftRoot)
	USceneComponent LiftRoot;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"HackableForkliftCapability");

	UPROPERTY(DefaultComponent)
	UHazeMovementComponent MoveComp;

	UPROPERTY(DefaultComponent)
	USwarmDroneHijackTargetableComponent HijackTargetableComp;

	bool bHacked = false;

	UPROPERTY()
	bool bLifting = false;

	UPROPERTY()
	bool bBottom = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		CapabilityInput::LinkActorToPlayerInput(this, Drone::GetSwarmDronePlayer());
	}
}

class UHackableForkliftCapability: UHazeCapability
{
	default CapabilityTags.Add(n"Example");
	
	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;

	UHazeMovementComponent MoveComp;
	USteppingMovementData Movement;

	AHackableForklift Forklift;

	float ForkliftOffset = 0.0;
	float ForkSpeed = 300.0;

	float MovementSpeed = 1000.0;

	float RotationSpeed = 100.0;

	float CurrentVelocity = 0.0;
	float CurrentRotationSpeed = 0.0;
	float CurrentForkSpeed = 0.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Player = Drone::GetSwarmDronePlayer();

		MoveComp = UHazeMovementComponent::Get(Owner);
		Movement = MoveComp.SetupSteppingMovementData();

		Forklift = Cast<AHackableForklift>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{		
		if (MoveComp.HasMovedThisFrame())
			return false;

		if (!Forklift.HijackTargetableComp.IsHijacked())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;

		if (!Forklift.HijackTargetableComp.IsHijacked())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		// Player.ActivateCamera(Forklift.CameraComp, 1.0, this);

		ForkliftOffset = Forklift.LiftRoot.RelativeLocation.Z;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		// Player.DeactivateCamera(Forklift.CameraComp, 1.0);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (!MoveComp.PrepareMove(Movement))
			return;

		FVector2D Input = GetAttributeVector2D(AttributeVectorNames::MovementRaw);
		CurrentVelocity = Math::FInterpTo(CurrentVelocity, Input.X * MovementSpeed, DeltaTime, 5.0);
		FVector DeltaMove = Owner.ActorForwardVector * CurrentVelocity * DeltaTime;

		Movement.AddDelta(DeltaMove);

		CurrentRotationSpeed = Math::FInterpTo(CurrentRotationSpeed, RotationSpeed * Input.Y, DeltaTime, 12.0);

		FRotator Rot = Owner.ActorRotation;
		Rot.Yaw += CurrentRotationSpeed * DeltaTime;
		Movement.SetRotation(Rot);

		// Forklift.FortliftRoot.SetRelativeRotation(FRotator(0,0,0.1*CurrentRotationSpeed*Input.X));

		MoveComp.ApplyMove(Movement);

		float TargetForkSpeed = 0.0;
		if (IsActioning(ActionNames::PrimaryLevelAbility))
		{	
			TargetForkSpeed += ForkSpeed;
			Forklift.bBottom = false;
		}

		if (IsActioning(ActionNames::SecondaryLevelAbility))
		{
			TargetForkSpeed -= ForkSpeed;
			if (ForkliftOffset == 0)
				Forklift.bBottom = true;
		}
		 
		CurrentForkSpeed = Math::FInterpTo(CurrentForkSpeed, TargetForkSpeed, DeltaTime, 7.0);

		ForkliftOffset += CurrentForkSpeed * DeltaTime;
		ForkliftOffset = Math::Clamp(ForkliftOffset, 0, 300.0);

		Forklift.LiftRoot.SetRelativeLocation(FVector(180.0, 0.0, ForkliftOffset));
	}
}