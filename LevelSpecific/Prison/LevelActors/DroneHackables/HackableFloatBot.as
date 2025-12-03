class AHackableFloatBot : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UFauxPhysicsFreeRotateComponent AxisComp;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"HackableFloatBotCapability");

	UPROPERTY(DefaultComponent)
	UHazeMovementComponent MoveComp;

	UPROPERTY(DefaultComponent)
	USwarmDroneHijackTargetableComponent HijackTargetableComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UHazeCameraComponent CameraComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		CapabilityInput::LinkActorToPlayerInput(this, Drone::GetSwarmDronePlayer());
	}


	UFUNCTION(BlueprintEvent)
	void Charge()
	{

	}
		
	UFUNCTION(BlueprintEvent)
	void Launch()
	{

	}

};


class UHackableFloatBotCapability: UHazeCapability
{
	default CapabilityTags.Add(n"Example");
	
	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 5;

	AHazePlayerCharacter Player;

	UHazeMovementComponent PlayerMoveComp;
	UHazeMovementComponent MoveComp;
	USweepingMovementData Movement;

	AHackableFloatBot FloatBot;

	FVector Velocity = FVector::ZeroVector;
	float MoveSpeed = 1000.0;


	float Speed;

	float CurrentVelocity = 0.0;
	float CurrentVelocityY = 0;


	float CurrentRotationSpeed = 0.0;

	float MovementSpeed = 1000.0;

	float RotationSpeed = 100.0;

	FVector DefaultLoc;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Player = Drone::GetSwarmDronePlayer();
		FloatBot = Cast<AHackableFloatBot>(Owner);
		MoveComp = UHazeMovementComponent::Get(Owner);
		PlayerMoveComp = UHazeMovementComponent::Get(Player);
		Movement = MoveComp.SetupSweepingMovementData();

		DefaultLoc = Owner.ActorLocation;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{		
		if (MoveComp.HasMovedThisFrame())
			return false;

		if (!FloatBot.HijackTargetableComp.IsHijacked())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;

		if (!FloatBot.HijackTargetableComp.IsHijacked())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.ActivateCamera(FloatBot.CameraComp,1, this);
		PlayerMoveComp.FollowComponentMovement(FloatBot.RootComp, this, EMovementFollowComponentType::ResolveCollision);
		Velocity = FVector::ZeroVector;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.DeactivateCamera(FloatBot.CameraComp, 1);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (!MoveComp.PrepareMove(Movement))
			return;

		FVector2D Input;

		if(IsActioning(ActionNames::PrimaryLevelAbility))
			FloatBot.Launch();

		Input = GetAttributeVector2D(AttributeVectorNames::MovementRaw);
		CurrentVelocity = Math::FInterpTo(CurrentVelocity, Input.X * MovementSpeed, DeltaTime, 5.0);
		FVector DeltaMove = Owner.ActorForwardVector * CurrentVelocity * DeltaTime;

		// if (IsActioning(ActionNames::SecondaryLevelAbility))
		// {
		// 	Input = FVector2D(1,0);
		// }
		// else
		// 	Input = FVector2D(0,0);


		// CurrentVelocityY = Math::FInterpTo(CurrentVelocityY, Input.Y * MovementSpeed, DeltaTime, 5.0);
		// DeltaMove = DeltaMove + Owner.ActorRightVector * CurrentVelocityY * DeltaTime;

		Movement.AddDelta(DeltaMove);

		FVector2D InputR = GetAttributeVector2D(AttributeVectorNames::RightStickRaw);

		CurrentRotationSpeed = Math::FInterpTo(CurrentRotationSpeed, RotationSpeed * Input.Y , DeltaTime, 12.0);

		FRotator Rot = Owner.ActorRotation;
		Rot.Yaw += CurrentRotationSpeed * DeltaTime;
		Movement.SetRotation(Rot);

		FloatBot.AxisComp.ApplyImpulse(FloatBot.GetActorLocation()+FVector(0,0,150), (Owner.ActorForwardVector*DeltaTime*-250*Input.X) + (Owner.ActorRightVector*DeltaTime*250*Input.Y));

		// Forklift.FortliftRoot.SetRelativeRotation(FRotator(0,0,0.1*CurrentRotationSpeed*Input.X));

		MoveComp.ApplyMove(Movement);
	}
}