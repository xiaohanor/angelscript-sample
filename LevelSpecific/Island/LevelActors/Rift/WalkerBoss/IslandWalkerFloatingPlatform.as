event void FIslandWalkerFloatingPlatformSignature();

class AIslandWalkerFloatingPlatform : AHazeActor
{

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = "Root")
	USceneComponent BaseComp;

	UPROPERTY(DefaultComponent, Attach = "BaseComp")
	UBoxComponent Collision;

	UPROPERTY(DefaultComponent)
	UBoxComponent DamageCollision;

	UPROPERTY(DefaultComponent)
	UBoxComponent DeathCollision;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent DestinationComp;

	UPROPERTY(DefaultComponent, Attach = DestinationComp)
	UIslandWalkerSwimmingObstacleComponent ObstacleAvoidanceComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent StartPosComp;
	
	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent FirstPosComp;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 10000.0;

	UPROPERTY()
	UNiagaraSystem Effect;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect ForceFeedback;

	UPROPERTY(EditInstanceOnly)
	APlayerTrigger TriggerRef;

	UPROPERTY(EditDefaultsOnly, Category = "DeathEffect")
	TSubclassOf<UDeathEffect> DeathEffect;

	UPROPERTY(EditDefaultsOnly, Category = "DeathEffect")
	TSubclassOf<UDamageEffect> DamageEffect;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect LandForceFeedback;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UCameraShakeBase> LandCameraShake;

	bool bIsActivated;
	float TravelDuration = 1.0;
	bool bTouchedSurface;

	FHazeTimeLike MoveAnimation;	
	default MoveAnimation.Duration = 2.5;
	default MoveAnimation.UseSmoothCurveZeroToOne();

	FTransform StartingTransform;
	FQuat StartingRotation;
	FVector StartingPosition;
	FTransform EndingTransform;
	FQuat EndingRotation;
	FVector EndingPosition;

	bool bGoingForward;
	bool bMioOn;
	bool bZoeOn;
	bool bFirstTime;

	FTransform InitialTransform;
	FQuat InitialRotation;
	FVector InitialPosition;
	FTransform FirstTransform;
	FQuat FirstRotation;
	FVector FirstPosition;

	FHazeTimeLike InitialAnimation;	
	default InitialAnimation.Duration = 2;
	default InitialAnimation.UseSmoothCurveZeroToOne();

	FHazeTimeLike FirstAnimation;	
	default FirstAnimation.Duration = 3;
	default FirstAnimation.UseSmoothCurveZeroToOne();

	UPROPERTY(EditAnywhere)
	bool bAnimateIn = true;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorHiddenInGame(true);
		InitialTransform = StartPosComp.GetWorldTransform();
		InitialPosition = InitialTransform.GetLocation();
		InitialRotation = InitialTransform.GetRotation();

		FirstTransform = FirstPosComp.GetWorldTransform();
		FirstPosition = FirstTransform.GetLocation();
		FirstRotation = FirstTransform.GetRotation();

		StartingTransform = BaseComp.GetWorldTransform();
		StartingPosition = StartingTransform.GetLocation();
		StartingRotation = StartingTransform.GetRotation();

		EndingTransform = DestinationComp.GetWorldTransform();
		EndingPosition = EndingTransform.GetLocation();
		EndingRotation = EndingTransform.GetRotation();

		MoveAnimation.BindUpdate(this, n"OnUpdate");
		MoveAnimation.BindFinished(this, n"OnFinished");
		MoveAnimation.SetPlayRate(1.0 / TravelDuration);

		InitialAnimation.BindUpdate(this, n"OnInitialUpdate");
		InitialAnimation.BindFinished(this, n"OnInitialFinished");

		FirstAnimation.BindUpdate(this, n"OnFirstUpdate");
		FirstAnimation.BindFinished(this, n"OnFirstFinished");

		Collision.OnComponentBeginOverlap.AddUFunction(this, n"OnOverlap");
		Collision.OnComponentEndOverlap.AddUFunction(this, n"OnEndOverlap");

		DamageCollision.OnComponentBeginOverlap.AddUFunction(this, n"OnDamageOverlap");
		DeathCollision.OnComponentBeginOverlap.AddUFunction(this, n"OnDeathOverlap");

		// SetActorLocationAndRotation(InitialTransform.Location, InitialTransform.GetRotation(), true);
		BaseComp.SetWorldLocationAndRotation(InitialPosition, InitialRotation);
		if(TriggerRef != nullptr)
			TriggerRef.OnPlayerEnter.AddUFunction(this, n"OnPlayerEnter");

	}

	UFUNCTION()
	void InitializePlatform()
	{
		SetActorHiddenInGame(false);
		InitialAnimation.PlayFromStart();
		bIsActivated = true;
		BP_EnableForceFeedBack();
	}

	UFUNCTION()
	private void OnOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                       UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep,
	                       const FHitResult&in SweepResult)
	{	
		if (!bIsActivated)
			return;

		

		auto Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;

		if (Player == Game::GetPlayer(EHazePlayer::Mio)) 
		{
			bMioOn = true;
			if (Player.IsPlayerDead())
				bMioOn = false;

			
			if(bMioOn && ForceFeedback != nullptr)
				Player.PlayForceFeedback(ForceFeedback, false, false, this);
		}
			

		if (Player == Game::GetPlayer(EHazePlayer::Zoe)) 
		{
			bZoeOn = true;
			if (Player.IsPlayerDead())
				bZoeOn = false;
			if(bZoeOn && ForceFeedback != nullptr)
				Player.PlayForceFeedback(ForceFeedback, false, false, this);
		}

		if (FirstAnimation.Value < 1.0)
		{
			Timer::SetTimer(this, n"ReEnableCollision", 2.0);
			return;
		}

		if (MoveAnimation.Value == 1)
			return;

		if (!bFirstTime)
		{
			bFirstTime = true;
			// StartingTransform = BaseComp.GetWorldTransform();
			// StartingPosition = StartingTransform.GetLocation();
			// StartingRotation = StartingTransform.GetRotation();

			// EndingTransform = DestinationComp.GetWorldTransform();
			// EndingPosition = EndingTransform.GetLocation();
			// EndingRotation = EndingTransform.GetRotation();
		}

		
			

		if (bMioOn && bZoeOn)
		{
			MoveAnimation.SetPlayRate(1.3);
			MoveAnimation.Play(); 
			return;
		}

		if (bMioOn || bZoeOn)
		{
			MoveAnimation.SetPlayRate(1);
			MoveAnimation.Play(); 
		}
			

	}

	UFUNCTION()
	void ReEnableCollision()
	{
		Collision.SetCollisionEnabled(ECollisionEnabled::NoCollision);
		Collision.SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);
	}

	UFUNCTION()
	void OnPlayerEnter(AHazePlayerCharacter Player)
	{
		if (MoveAnimation.IsPlaying())
			return;

	}

	UFUNCTION()
	private void OnEndOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                       UPrimitiveComponent OtherComp, int OtherBodyIndex)
	{	
		if (!bIsActivated)
			return;

		auto Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;

		if (Player == Game::GetPlayer(EHazePlayer::Mio)) 
			bMioOn = false;

		if (Player == Game::GetPlayer(EHazePlayer::Zoe)) 
			bZoeOn = false;

		if (bMioOn || bZoeOn)
			MoveAnimation.SetPlayRate(1);
		

		if (!bMioOn && !bZoeOn)
		{
			MoveAnimation.SetPlayRate(0.4);
			MoveAnimation.Reverse();
		}

	}

	UFUNCTION()
	private void OnDamageOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                       UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep,
	                       const FHitResult&in SweepResult)
	{
		if (!bIsActivated)
			return;

		auto Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;

		if (Player == Game::GetPlayer(EHazePlayer::Mio)) 
			Game::GetPlayer(EHazePlayer::Mio).DamagePlayerHealth(0.1, FPlayerDeathDamageParams(ActorUpVector, 5.0), DamageEffect, DeathEffect);
			

		if (Player == Game::GetPlayer(EHazePlayer::Zoe)) 
			Game::GetPlayer(EHazePlayer::Zoe).DamagePlayerHealth(0.1, FPlayerDeathDamageParams(ActorUpVector, 5.0), DamageEffect, DeathEffect);
				
	}

	UFUNCTION()
	private void OnDeathOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                       UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep,
	                       const FHitResult&in SweepResult)
	{
		if (!bIsActivated)
			return;

		auto Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;

		if (Player == Game::GetPlayer(EHazePlayer::Mio)) 
			Game::GetPlayer(EHazePlayer::Mio).KillPlayer(FPlayerDeathDamageParams(ActorUpVector, 5.0), DeathEffect);

		if (Player == Game::GetPlayer(EHazePlayer::Zoe)) 
			Game::GetPlayer(EHazePlayer::Zoe).KillPlayer(FPlayerDeathDamageParams(ActorUpVector, 5.0), DeathEffect);

		if (Game::GetPlayer(EHazePlayer::Mio).IsPlayerDead()) 
		{
			bMioOn = false;
		}

		if (Game::GetPlayer(EHazePlayer::Zoe).IsPlayerDead()) 
		{
			bZoeOn = false;
		}

		if (!bMioOn && !bZoeOn)
		{
			MoveAnimation.SetPlayRate(0.8);
			MoveAnimation.Reverse();
		}
				
	}

	UFUNCTION()
	void OnInitialUpdate(float Alpha)
	{
		BaseComp.SetWorldLocationAndRotation(Math::Lerp(InitialPosition, FirstPosition, Alpha), FQuat::SlerpFullPath(InitialRotation, FirstRotation, Alpha));

		if(bTouchedSurface || Alpha < 0.925)
			return;

		ForceFeedback::PlayWorldForceFeedback(LandForceFeedback, ActorLocation, false, this, 1500, 1500);
		for(AHazePlayerCharacter Player : Game::Players)
			Player.PlayWorldCameraShake(LandCameraShake, this, ActorLocation, 1500, 3000);
		bTouchedSurface = true;
	}

	UFUNCTION()
	void OnInitialFinished()
	{
		FirstAnimation.PlayFromStart();
	}

	UFUNCTION()
	void OnFirstUpdate(float Alpha)
	{
		BaseComp.SetWorldLocationAndRotation(Math::Lerp(FirstPosition, StartingPosition, Alpha), FQuat::SlerpFullPath(FirstRotation, StartingRotation, Alpha));
	}

	UFUNCTION()
	void OnFirstFinished()
	{

	}

	UFUNCTION()
	void OnUpdate(float Alpha)
	{
		BaseComp.SetWorldLocationAndRotation(Math::Lerp(StartingPosition, EndingPosition, Alpha), FQuat::SlerpFullPath(StartingRotation, EndingRotation, Alpha));
	}

	UFUNCTION()
	void OnFinished()
	{
		
	}

	UFUNCTION(BlueprintEvent)
	void BP_EnableForceFeedBack(){}


}

UCLASS(Abstract)
class UIslandWalkerFloatingPlatformEffectHandler : UHazeEffectEventHandler
{
	//UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	//void OnLand() {}

	//UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	//void OnJump() {}
	
	//UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	//void OnStartMoving() {}

	//UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	//void OnReachedDestination() {}

	//UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	//void OnStartMovingMusicRef() {}

	//UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	//void OnReachedDestinationMusicRef() {}
}