event void FOnVerticalSideCameraGrappleComplete(); 

class ASerpentRunVertcailSideCameraActor : AHazeActor
{
	UPROPERTY()
	FOnVerticalSideCameraGrappleComplete OnVerticalSideCameraGrappleComplete;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeCameraComponent CameraComp;

	UPROPERTY(EditAnywhere)
	AGrapplePoint SerpentGrapplePoint;

	float TimeDilationTarget = 0.1;
	float CurrentDilation = 1.0;

	bool bActivated;
	bool bStartedTransition;

	int PlayersInitiated;

	float ZOffset = 700.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SerpentGrapplePoint.OnPlayerInitiatedGrappleToPointEvent.AddUFunction(this, n"OnPlayerGrappledToSpecialPoint");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		FVector BetweenPoint = (Game::Mio.ActorLocation + Game::Zoe.ActorLocation) / 2;
		FVector CurrentLoc = BetweenPoint;
		CurrentLoc += ActorRightVector * 800.0;
		CurrentLoc += -ActorForwardVector * 900.0;
		ActorLocation = CurrentLoc;

		FVector Direction = (BetweenPoint - ActorLocation).GetSafeNormal();
		CameraComp.WorldRotation = Direction.Rotation();
		CameraComp.WorldLocation = ActorLocation; //Don't know why this is necessary - camera was offset for some reason

		ActorLocation -= FVector::UpVector * ZOffset;

		// Debug::DrawDebugSphere(ActorLocation, 250.0, LineColor = FLinearColor::Red, Thickness = 15.0);
		// Debug::DrawDebugSphere(CameraComp.WorldLocation, 250.0, LineColor = FLinearColor::Green, Thickness = 15.0);
		// Debug::DrawDebugLine(ActorLocation, ActorLocation + Direction * 5000.0, FLinearColor::Blue, 25.0);

		if (bStartedTransition)
			ZOffset = Math::FInterpConstantTo(ZOffset, 0.0, DeltaSeconds, ZOffset / 2);

		if (bActivated)
		{
			CurrentDilation = Math::FInterpConstantTo(CurrentDilation, TimeDilationTarget, DeltaSeconds, 0.8);
			Time::SetWorldTimeDilation(CurrentDilation);
		}
		else
		{
			CurrentDilation = Math::FInterpConstantTo(CurrentDilation, 1.0, DeltaSeconds, 0.8);
			Time::SetWorldTimeDilation(CurrentDilation);
		}
	}

	UFUNCTION()
	void ActivateSideCamera(AHazePlayerCharacter Player, float BlendTime)
	{
		Player.ActivateCamera(CameraComp, BlendTime, this);
		Timer::SetTimer(this, n"DelayActivateSlowMo", 2.0, false);
		bStartedTransition = true;
	}

	UFUNCTION()
	void DeactivateSideCamera(AHazePlayerCharacter Player, float BlendTime)
	{
		Player.DeactivateCamera(CameraComp, BlendTime);
	}

	UFUNCTION()
	void DelayActivateSlowMo()
	{
		bActivated = true;
	}
	
	UFUNCTION()
	private void OnPlayerGrappledToSpecialPoint(AHazePlayerCharacter Player, UGrapplePointBaseComponent GrapplePoint)
	{
		if (PlayersInitiated >= 2)
			return;

		PlayersInitiated++;

		if (PlayersInitiated >= 2)
		{
			bActivated = false;
			OnVerticalSideCameraGrappleComplete.Broadcast();
		}
	}
};