class AStealthSniperMovingBox : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent MeshComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
 	UBillboardComponent TargetLocation;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent RotationRootComp;

	FVector Target;
	FVector Origin;
	float TargetDistanceSqrd = 0;

	float Speed = 750;
	float TargetSpeed = Speed;
	bool bMoveForward = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Origin = GetActorLocation();
		Target = TargetLocation.GetWorldLocation();
		Speed = 100;
		TargetDistanceSqrd = Origin.DistSquared(Target);
	}

	UFUNCTION()
	void ActivateForward()
	{
		if(IsActorTickEnabled())
		{
			Print("SwapDir");
			UStealthSniperMovingBoxEventHandler::Trigger_ChangeDirection(this);
			Speed = 0;
		}
		else
		{
			Print("StartMoving");
			UStealthSniperMovingBoxEventHandler::Trigger_StartMoving(this);
			Speed = 0;
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
			UStealthSniperMovingBoxEventHandler::Trigger_ChangeDirection(this);
			Speed = 0;
		}
		else
		{
			Print("StartMoving");
			UStealthSniperMovingBoxEventHandler::Trigger_StartMoving(this);
			Speed = 0;
		}
		
		bMoveForward = false;
		ActorTickEnabled = true;
	}

	UFUNCTION(BlueprintPure)
	float GetLocationAlpha()
	{
		return GetActorLocation().DistSquared(Origin) / TargetDistanceSqrd;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		Speed = Math::FInterpTo(Speed, TargetSpeed, DeltaSeconds, 1);

		if (bMoveForward)
		{
			SetActorLocation(Math::VInterpConstantTo(GetActorLocation(), Target, DeltaSeconds, Speed));
			RotationRootComp.AddLocalRotation(FRotator(0,DeltaSeconds*100,0));
		}
		else if(!bMoveForward)
		{
			SetActorLocation(Math::VInterpConstantTo(GetActorLocation(), Origin, DeltaSeconds, Speed));
			RotationRootComp.AddLocalRotation(FRotator(0,DeltaSeconds*-100,0));
		}

		if((GetActorLocation().Distance(Target)) < 5 && bMoveForward)
		{
			ActorTickEnabled = false;
			Print("end");
			UStealthSniperMovingBoxEventHandler::Trigger_StopMoving(this);
		}


		if((GetActorLocation().Distance(Origin)) < 5 && !bMoveForward)
		{
			ActorTickEnabled = false;
			Print("end");
			UStealthSniperMovingBoxEventHandler::Trigger_StopMoving(this);
		}

	}
}

			// SetActorLocation(Math::VInterpTo(GetActorLocation(), Origin,DeltaSeconds, Speed));