class AStealthSniperMovingRotatingCrate : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent MeshComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent RotatingMeshComp;

	UPROPERTY(DefaultComponent,Attach = RootComp)
	USceneComponent RotationRoot;

	UPROPERTY()
	UForceFeedbackEffect FFCrateReachEnd;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> CamShake;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent MagneticSurfaceMeshComp;

	UPROPERTY(DefaultComponent)
	UDroneMagneticSurfaceComponent MagneticSurfaceComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
 	UBillboardComponent TargetLocation;

	FVector Target;
	FVector Origin;

	float Speed = 750;
	float TargetSpeed = Speed;

	bool bMoveForward = false;
	bool bMoving;

	float RotateSpeed = 100;
	float TargetRotateSpeed = RotateSpeed;

	bool bRotating = false;

	FRotator NextRotation;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Origin = GetActorLocation();
		Target = TargetLocation.GetWorldLocation();
		RotateSpeed = 0;
	}

	UFUNCTION()
	void ActivateForward()
	{
		if(bMoving)
		{
			Print("SwapDir");
			UStealthSniperMovingRotatingCrateEventHandler::Trigger_ChangeDirection(this);
			Speed = 1;
			bMoving = true;
		}
		else if(!bMoving)
		{
			Print("StartMoving");
			UStealthSniperMovingRotatingCrateEventHandler::Trigger_StartMoving(this);
			Speed = 1;
			bMoving = true;
		}

		bMoveForward = true;
		ActorTickEnabled = true;
	}

	UFUNCTION()
	void ActivateRotate()
	{
		if(!bRotating)
		{
			UStealthSniperMovingRotatingCrateEventHandler::Trigger_StartRotation(this);
			Print("StartRotation");
		}
		else
		{
			UStealthSniperMovingRotatingCrateEventHandler::Trigger_ResetRotation(this);
			Print("ResertRotation");
		}


		bRotating = true;
		NextRotation = NextRotation + FRotator(0,90,0);
	}

	UFUNCTION()
	void ReverseBackwards()
	{
		if(bMoving)
		{
			Print("SwapDir");
			UStealthSniperMovingRotatingCrateEventHandler::Trigger_ChangeDirection(this);
			Speed = 1;
			bMoving = true;
		}
		else if (!bMoving)
		{
			Print("StartMoving");
			UStealthSniperMovingRotatingCrateEventHandler::Trigger_StartMoving(this);
			Speed = 1;
			bMoving = true;
		}
		
		bMoveForward = false;
		ActorTickEnabled = true;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (bMoving)
		{
			Speed = Math::FInterpTo(Speed, TargetSpeed, DeltaSeconds, 10);
			if (bMoveForward)
			{
				SetActorLocation(Math::VInterpConstantTo(GetActorLocation(), Target,DeltaSeconds, Speed));
				RotationRoot.AddLocalRotation(FRotator(0,0,DeltaSeconds*(Math::IntegerDivisionTrunc(-750,2))));
			}
			else if(!bMoveForward)
			{
				SetActorLocation(Math::VInterpConstantTo(GetActorLocation(), Origin,DeltaSeconds, Speed));
				RotationRoot.AddLocalRotation(FRotator(0,0,DeltaSeconds*Math::IntegerDivisionTrunc(750,2)));
			}

			if((GetActorLocation().Distance(Target)) < KINDA_SMALL_NUMBER && bMoveForward)
			{
				Print("end");
				UStealthSniperMovingRotatingCrateEventHandler::Trigger_StopMoving(this);
				bMoving = false;
				ForceFeedback::PlayWorldForceFeedback(FFCrateReachEnd,RotatingMeshComp.WorldLocation,false,this,500,300,1,1,EHazeSelectPlayer::Zoe);
				ForceFeedback::PlayWorldForceFeedback(FFCrateReachEnd,RotationRoot.WorldLocation,false,this,500,300,1,1,EHazeSelectPlayer::Zoe);
				Game::Zoe.PlayWorldCameraShake(CamShake,this,RotatingMeshComp.WorldLocation,500,300,1,1,false,EHazeWorldCameraShakeSamplePosition::Player);
				Game::Zoe.PlayWorldCameraShake(CamShake,this,RotationRoot.WorldLocation,500,300,1,1,false,EHazeWorldCameraShakeSamplePosition::Player);
			}

			if((GetActorLocation().Distance(Origin)) < KINDA_SMALL_NUMBER && !bMoveForward)
			{
				Print("end");
				UStealthSniperMovingRotatingCrateEventHandler::Trigger_StopMoving(this);
				bMoving = false;
				ForceFeedback::PlayWorldForceFeedback(FFCrateReachEnd,RotatingMeshComp.WorldLocation,false,this,500,300,1,1,EHazeSelectPlayer::Zoe);
				ForceFeedback::PlayWorldForceFeedback(FFCrateReachEnd,RotationRoot.WorldLocation,false,this,500,300,1,1,EHazeSelectPlayer::Zoe);
				Game::Zoe.PlayWorldCameraShake(CamShake,this,RotatingMeshComp.WorldLocation,500,300,1,1,false,EHazeWorldCameraShakeSamplePosition::Player);
				Game::Zoe.PlayWorldCameraShake(CamShake,this,RotationRoot.WorldLocation,500,300,1,1,false,EHazeWorldCameraShakeSamplePosition::Player);
			}
		}

		if(bRotating)
		{
			RotateSpeed = Math::FInterpTo(RotateSpeed, TargetRotateSpeed, DeltaSeconds, 1);
			RotatingMeshComp.SetRelativeRotation(Math::RInterpConstantTo(RotatingMeshComp.RelativeRotation,NextRotation,DeltaSeconds,RotateSpeed));
			if (RotatingMeshComp.RelativeRotation.Equals(NextRotation,KINDA_SMALL_NUMBER))
			{
				bRotating = false;
				RotateSpeed = 0;
				RotatingMeshComp.SetRelativeRotation(NextRotation);
				UStealthSniperMovingRotatingCrateEventHandler::Trigger_StopRotation(this);
				Print("StopRotation");
				ForceFeedback::PlayWorldForceFeedback(FFCrateReachEnd,RotatingMeshComp.WorldLocation,false,this,500,300,1,0.2,EHazeSelectPlayer::Zoe);
		 	}
				ForceFeedback::PlayDirectionalWorldForceFeedbackForFrame(RotatingMeshComp.WorldLocation,0.3,500,300,1,EHazeSelectPlayer::Zoe,false);
		}



	}
}