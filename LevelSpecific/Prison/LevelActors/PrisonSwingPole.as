UCLASS(Abstract)
class APrisonSwingPole : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UFauxPhysicsAxisRotateComponent RotateComp;

	UPROPERTY(EditAnywhere, Category = "Settings")
	APoleClimbActor LinkedPoleActor;

	//Multiplier to the horizontal velocity registered when enter began
	UPROPERTY(EditAnywhere, Category = "Settings")
	float HorizontalVelocityMultiplier = 3;

	//Multiplier to the vertical velocity registered on enter, transfered to the impulse
	UPROPERTY(EditAnywhere, Category = "Settings")
	float VerticalVelocityMultiplier = 0.3;

	//Impulse strenght for jump off
	UPROPERTY(EditAnywhere, Category = "Settings")
	float JumpOffImpulse = 5000;

	//Impulse strength for turnarounds
	UPROPERTY(EditAnywhere, Category = "Settings")
	float TurnaroundImpulse = 500;

	//Impulse strength for Cancel Exit
	UPROPERTY(EditAnywhere, Category = "Settings")
	float CancelImpulse = 750;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if(LinkedPoleActor != nullptr)
		{
			//This event fires slightly early (start of enter when approaching pole)
			LinkedPoleActor.OnStartPoleClimb.AddUFunction(this, n"OnEnterFinished");

			//This event fires at the point of contact when finishing enter (BUT IT FEELS DELAYED).
			// LinkedPoleActor.OnEnterFinished.AddUFunction(this, n"OnEnterFinished");

			LinkedPoleActor.OnJumpOff.AddUFunction(this, n"OnPoleJumpOff");

			LinkedPoleActor.OnPoleTurnaround.AddUFunction(this, n"OnTurnaround");
			
			LinkedPoleActor.OnCancel.AddUFunction(this, n"OnPoleCancelExit");
		}
	}

	UFUNCTION()
	private void OnPoleCancelExit(AHazePlayerCharacter Player, APoleClimbActor PoleClimbActor,
	                              FVector JumpOutDirection)
	{
		FauxPhysics::ApplyFauxForceToActorAt(this, Player.ActorLocation, -JumpOutDirection.GetSafeNormal() * CancelImpulse);
	}

	UFUNCTION()
	private void OnTurnaround(AHazePlayerCharacter Player, APoleClimbActor PoleClimbActor,
	                          FVector JumpOutDirection)
	{
		FauxPhysics::ApplyFauxForceToActorAt(this, Player.ActorLocation, JumpOutDirection.GetSafeNormal() * TurnaroundImpulse);
	}

	UFUNCTION()
	private void OnPoleJumpOff(AHazePlayerCharacter Player, APoleClimbActor PoleClimbActor, FVector ExitDirection)
	{
		FauxPhysics::ApplyFauxForceToActorAt(this, Player.ActorLocation, -ExitDirection.GetSafeNormal() * JumpOffImpulse);
	}

	UFUNCTION()
	private void OnEnterFinished(AHazePlayerCharacter Player, APoleClimbActor PoleClimbActor)
	{
		UPlayerPoleClimbComponent PoleClimbComp = UPlayerPoleClimbComponent::Get(Player);
		FVector TargetLocation = PoleClimbComp.Data.ActivePole.ActorLocation + (PoleClimbComp.Data.ActivePole.ActorUpVector * PoleClimbComp.Data.CurrentHeight);

		FVector ImpulseDirection = (TargetLocation - Player.ActorLocation).GetSafeNormal();

		ImpulseDirection = ImpulseDirection.GetClampedToMaxSize(500);

		FauxPhysics::ApplyFauxForceToActorAt(this, Player.ActorLocation, ImpulseDirection * ((PoleClimbComp.Data.VelocityOnEnter.DotProduct(ImpulseDirection) * HorizontalVelocityMultiplier)
												+ (PoleClimbComp.Data.VelocityOnEnter.ConstrainToDirection(Player.MovementWorldUp).Size() * VerticalVelocityMultiplier)));
		
	}
};
