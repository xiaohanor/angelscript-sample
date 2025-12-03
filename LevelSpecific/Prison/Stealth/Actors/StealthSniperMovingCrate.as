class AStealthSniperMovingCrate : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent MagneticSurfaceMeshComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UDroneMagneticZoneComponent MagneticZoneComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UMagnetDroneAutoAimComponent AutoAimComp;

	UPROPERTY(DefaultComponent)
	UDroneMagneticSurfaceComponent MagneticSurfaceComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
 	UBillboardComponent TargetLocation;

	FVector Target;
	FVector Origin;

	float Speed = 750;
	float TargetSpeed = Speed;
	bool bMoveForward = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Origin = GetActorLocation();
		Target = TargetLocation.GetWorldLocation();
		
	}

	UFUNCTION()
	void ActivateForward()
	{
		if(IsActorTickEnabled())
		{
			Print("SwapDir");
			UStealthSniperMovingCrateEventHandler::Trigger_ChangeDirection(this);
			Speed = 1;
		}
		else
		{
			Print("StartMoving");
			UStealthSniperMovingCrateEventHandler::Trigger_StartMoving(this);
			Speed = 1;
		}

		bMoveForward = true;
		ActorTickEnabled = true;
	}

	UFUNCTION()
	void ReverseBackwards()
	{
		if(IsActorTickEnabled())
		{
			Print("SwapDir");
			UStealthSniperMovingCrateEventHandler::Trigger_ChangeDirection(this);
			Speed = 1;
		}
		else
		{
			Print("StartMoving");
			UStealthSniperMovingCrateEventHandler::Trigger_StartMoving(this);
			Speed = 1;
		}
		
		bMoveForward = false;
		ActorTickEnabled = true;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		Speed = Math::FInterpTo(Speed, TargetSpeed, DeltaSeconds, 5);

		if (bMoveForward)
			SetActorLocation(Math::VInterpConstantTo(GetActorLocation(), Target,DeltaSeconds, Speed));
		else if(!bMoveForward)
			SetActorLocation(Math::VInterpConstantTo(GetActorLocation(), Origin,DeltaSeconds, Speed));

		if((GetActorLocation().Distance(Target)) < 5 && bMoveForward)
		{
			ActorTickEnabled = false;
			Print("end");
			UStealthSniperMovingCrateEventHandler::Trigger_StopMoving(this);
		}


		if((GetActorLocation().Distance(Origin)) < 5 && !bMoveForward)
		{
			ActorTickEnabled = false;
			Print("end");
			UStealthSniperMovingCrateEventHandler::Trigger_StopMoving(this);
		}

	}
}

			// SetActorLocation(Math::VInterpTo(GetActorLocation(), Origin,DeltaSeconds, Speed));