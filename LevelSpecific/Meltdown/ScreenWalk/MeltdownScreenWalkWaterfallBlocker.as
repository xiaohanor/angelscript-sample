event void FonBlocking();
event void FOnNotBlocking();
class AMeltdownScreenWalkWaterfallBlocker : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UFauxPhysicsAxisRotateComponent Rotate;

	UPROPERTY(DefaultComponent, Attach = Rotate)
	UStaticMeshComponent Blocker;

	UPROPERTY(DefaultComponent)
	UMeltdownScreenWalkResponseComponent StompComp;

	UPROPERTY(EditAnywhere)
	AMeltdownScreenWalkWaterfallBlocker Blocker01;

	UPROPERTY(EditAnywhere)
	AMeltdownScreenWalkWaterfallBlocker Blocker02;

	UPROPERTY(DefaultComponent, Attach = Blocker)
	UBillboardComponent StompFX;

	UPROPERTY(DefaultComponent, Attach = Blocker)
	UBillboardComponent WaterSplashFX;

	UPROPERTY(EditAnywhere)
	AMeltdownScreenWalkWaterFallDouble Waterfall;

	UPROPERTY(EditAnywhere)
	float DelayTime = 0.5;

	UPROPERTY()
	FonBlocking IsBlocking;
	UPROPERTY()
	FOnNotBlocking IsNotBlocking;

	bool bCurrentlyBlocking;

	float Amplitude = 1.0;

	float ShakeSpeed = 30;

	bool bcanStomp;

	bool bApplyForceDown = true;
	bool bApplyForceUp;
	bool bapplyforceBottom;

	FRotator CurrentRotation;
	FRotator InitialRotation;
	FRotator TargetRotation = FRotator(0,0,-90);

	FRotator SlowRotation = FRotator(0,0,-65);

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{

		StompComp.OnStompedTrigger.AddUFunction(this, n"OnStomped");

		Waterfall.Blocked.AddUFunction(this, n"WaterfallBlocked");
		Waterfall.NotBLocked.AddUFunction(this, n"WaterfallNotBlocked");

		Rotate.OnMaxConstraintHit.AddUFunction(this, n"HitConstraint");
		Rotate.OnMinConstraintHit.AddUFunction(this, n"HitBottomConstraint");

		InitialRotation = ActorRotation;
		CurrentRotation = SlowRotation;

		bcanStomp = true;
		
	}


	UFUNCTION()
	private void HitConstraint(float Strength)
	{
		Timer::SetTimer(this, n"Reset", 2.5);
		Timer::SetTimer(this, n"GoDown", 0.1);	
		IsBlocking.Broadcast();
		bCurrentlyBlocking = true;
		Print("HitConstraint" + Strength,2.0);
	}

	UFUNCTION()
	private void GoDown()
	{
		bApplyForceDown = true;
		bApplyForceUp = false;
		bcanStomp = false;
	}

	UFUNCTION()
	private void HitBottomConstraint(float Strength)
	{
		bcanStomp = true;
		bapplyforceBottom = true;
		bApplyForceDown = false;
		IsNotBlocking.Broadcast();
			bCurrentlyBlocking = false;
	}

	UFUNCTION()
	void Reset()
	{
	
		Rotate.ApplyImpulse(GetActorLocation() + ActorUpVector * 200, ActorRightVector * 600);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{

		if(bApplyForceDown)
			Rotate.ApplyForce(GetActorLocation() + ActorUpVector * 200, ActorRightVector * 10);
		else if(bApplyForceUp)	
			Rotate.ApplyForce(GetActorLocation() + ActorUpVector * 200, ActorRightVector * -500);
		else if(bapplyforceBottom)
			Rotate.ApplyForce(GetActorLocation() + ActorUpVector * 200, ActorRightVector * 200);
	}

	UFUNCTION()
	private void OnFallFinished()
	{
			IsNotBlocking.Broadcast();
			bCurrentlyBlocking = false;
	}

	UFUNCTION()
	private void WaterfallNotBlocked()
	{
		UMeltdownScreenWalkWaterfallPlatformEventHandler::Trigger_WaterSplashStop(this, FMeltdownScreenWalkWaterfallPlatformWater(WaterSplashFX));
	}

	UFUNCTION()
	private void WaterfallBlocked()
	{
		UMeltdownScreenWalkWaterfallPlatformEventHandler::Trigger_WaterSplashStart(this, FMeltdownScreenWalkWaterfallPlatformWater(WaterSplashFX));
	}

	UFUNCTION()
	private void OnStomped()
	{
		if(!bcanStomp)	
			return;
		
		bApplyForceUp = true;
		bApplyForceDown = false;
		bapplyforceBottom = false;
		Timer::ClearTimer(this,n"Reset");
		Timer::ClearTimer(this,n"GoDown");
		Rotate.ApplyImpulse(GetActorLocation() + ActorUpVector * 400, ActorRightVector * -500);
		UMeltdownScreenWalkWaterfallPlatformEventHandler::Trigger_StompEffect(this, FMeltdownScreenWalkWaterfallPlatformStomp(StompFX));
		bApplyForceDown = false;
	}
};