class AStealthSniperGate : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent MeshComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
 	UBillboardComponent TargetLocation;

	UPROPERTY(EditAnywhere)
	float Delay = 2.5;

	UPROPERTY(EditAnywhere)
	float MovementSpeed = 400;

	FVector Target;
	FVector Origin;

	float Speed = MovementSpeed;
	bool bMoveForward = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Origin = GetActorLocation();
		Target = TargetLocation.GetWorldLocation();
		Speed = MovementSpeed;
	}

	UFUNCTION()
	void ActivateForward()
	{
		if(!bMoveForward)
		{
			bMoveForward = true;
			ActorTickEnabled = true;
			UStealthSniperGateEventHandler::Trigger_StartMoving(this);
		}
	}

	UFUNCTION()
	void ReverseBackwards()
	{
		// Don't reverse it if it's already grounded, causes audio loops to be miss triggered.
		if((GetActorLocation().Distance(Origin)) < 5)
			return;
		
		// It's already reversing, don't trigger effect event again.
		if (!bMoveForward && IsActorTickEnabled())
			return;

		bMoveForward = false;
		ActorTickEnabled = true;
		UStealthSniperGateEventHandler::Trigger_StartReverseMoving(this);
	}

	UFUNCTION()
	private void UpdateTarget()
	{
		ReverseBackwards();
		Speed = 200;
	}
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		Speed = Math::FInterpTo(Speed, 1200, DeltaSeconds, 1);
		// Print(""+Speed);

		if (bMoveForward)
			SetActorLocation(Math::VInterpConstantTo(GetActorLocation(), Target,DeltaSeconds, Speed));
		else if(!bMoveForward)
			SetActorLocation(Math::VInterpConstantTo(GetActorLocation(), Origin,DeltaSeconds, Speed));

		if(bMoveForward && (GetActorLocation().Distance(Target)) < 5)
		{
			ActorTickEnabled = false;
			Timer::SetTimer(this, n"UpdateTarget", Delay, false);
			UStealthSniperGateEventHandler::Trigger_StopMoving(this);
		}
		else if(!bMoveForward && (GetActorLocation().Distance(Origin)) < 5)
		{
			ActorTickEnabled = false;
			UStealthSniperGateEventHandler::Trigger_StopReverseMoving(this);

		}
	}
}