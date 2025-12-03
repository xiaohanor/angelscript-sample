event void FIslandFloorMineSignature();

class AIslandFloorMine : AHazeActor
{

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = "Root")
	USceneComponent BaseComp;

	UPROPERTY(DefaultComponent)
	USphereComponent Collision;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent DestinationComp;
	
	UPROPERTY()
	UNiagaraSystem Effect;

	UPROPERTY()
	float Damage = 0.6;

	UPROPERTY(EditInstanceOnly)
	APlayerTrigger TriggerRef;

	bool bIsActivated;
	float TravelDuration = 1.0;

	FHazeTimeLike MoveAnimation;	
	default MoveAnimation.Duration = 3.0;
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

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartingTransform = Root.GetWorldTransform();
		StartingPosition = StartingTransform.GetLocation();
		StartingRotation = StartingTransform.GetRotation();

		EndingTransform = DestinationComp.GetWorldTransform();
		EndingPosition = EndingTransform.GetLocation();
		EndingRotation = EndingTransform.GetRotation();

		MoveAnimation.BindUpdate(this, n"OnUpdate");
		MoveAnimation.BindFinished(this, n"OnFinished");
		MoveAnimation.SetPlayRate(1.0 / TravelDuration);

		Collision.OnComponentBeginOverlap.AddUFunction(this, n"OnOverlap");
		Collision.OnComponentEndOverlap.AddUFunction(this, n"OnEndOverlap");

		if(TriggerRef != nullptr)
			TriggerRef.OnPlayerEnter.AddUFunction(this, n"OnPlayerEnter");

	}

	UFUNCTION()
	private void OnOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                       UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep,
	                       const FHitResult&in SweepResult)
	{	
		auto Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;

		if (Player == Game::GetPlayer(EHazePlayer::Mio)) 
			bMioOn = true;

		if (Player == Game::GetPlayer(EHazePlayer::Zoe)) 
			bZoeOn = true;

	}

	UFUNCTION()
	void OnPlayerEnter(AHazePlayerCharacter Player)
	{
		if (MoveAnimation.IsPlaying())
			return;

		Activate();
	}

	UFUNCTION()
	private void OnEndOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                       UPrimitiveComponent OtherComp, int OtherBodyIndex)
	{	

		auto Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;

		if (Player == Game::GetPlayer(EHazePlayer::Mio)) 
			bMioOn = false;

		if (Player == Game::GetPlayer(EHazePlayer::Zoe)) 
			bZoeOn = false;

	}

	UFUNCTION()
	void OnUpdate(float Alpha)
	{
		BaseComp.SetRelativeScale3D(Math::Lerp(FVector(0.01,0.01,0.01),FVector(2,2,2), Alpha));
		// SetActorRelativeRotation(FQuat::SlerpFullPath(StartingRotation, EndingRotation, Alpha));

	}

	UFUNCTION()
	void OnFinished()
	{
		bool bShouldActivate;

		if (bMioOn )
			Game::GetPlayer(EHazePlayer::Mio).DamagePlayerHealth(Damage);
		if (bZoeOn)
			Game::GetPlayer(EHazePlayer::Zoe).DamagePlayerHealth(Damage);

		Niagara::SpawnOneShotNiagaraSystemAtLocation(Effect, GetActorLocation());
		
		OnUpdate(0.0);
		
		if (bMioOn && !Game::GetPlayer(EHazePlayer::Mio).IsPlayerDead())
			Activate();
		if(bZoeOn && !Game::GetPlayer(EHazePlayer::Zoe).IsPlayerDead())
			Activate(); 

	}

	UFUNCTION()
	void Activate()
	{
		bIsActivated = true;
		if (!MoveAnimation.IsPlaying())
			MoveAnimation.PlayFromStart();
	}

	UFUNCTION()
	void Deactivate()
	{
		bIsActivated = false;
		MoveAnimation.Stop();
	}

}

UCLASS(Abstract)
class UIslandFloorMineEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartMoving() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnReachedDestination() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartMovingMusicRef() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnReachedDestinationMusicRef() {}
}