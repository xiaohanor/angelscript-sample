event void FSummitEggChaseProjectileSignature();

class ASummitEggChaseProjectile : AHazeActor
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
	UNiagaraSystem ShootEffect;

	UPROPERTY()
	UNiagaraSystem Effect;

	UPROPERTY()
	float Damage = 1;

	UPROPERTY(EditInstanceOnly)
	APlayerTrigger TriggerRef;

	UPROPERTY(EditInstanceOnly)
	ASummitEggStoneBeast StoneBeastRef;

	bool bIsActivated;
	float TravelDuration = 1.0;

	FHazeTimeLike MoveAnimation;	
	default MoveAnimation.Duration = 2.5;
	default MoveAnimation.UseLinearCurveZeroToOne();

	FTransform StartingTransform;
	FQuat StartingRotation;
	FVector StartingPosition;
	FTransform EndingTransform;
	FQuat EndingRotation;
	FVector EndingPosition;

	bool bGoingForward;
	bool bMioOn;
	bool bZoeOn;

	UPROPERTY(EditAnywhere)
	bool bCanHurPlayer = true;

	UPROPERTY(EditAnywhere)
	bool bDisableOverlap;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartingTransform = Root.GetWorldTransform();
		StartingPosition = StartingTransform.GetLocation();
		StartingRotation = StartingTransform.GetRotation();

		EndingTransform = Root.GetWorldTransform();
		EndingPosition = EndingTransform.GetLocation();
		EndingRotation = EndingTransform.GetRotation();

		MoveAnimation.BindUpdate(this, n"OnUpdate");
		MoveAnimation.BindFinished(this, n"OnFinished");
		MoveAnimation.SetPlayRate(1.0 / TravelDuration);

		if(TriggerRef != nullptr)
			TriggerRef.OnPlayerEnter.AddUFunction(this, n"OnPlayerEnter");

		if (TriggerRef == nullptr)
		{
			Collision.OnComponentBeginOverlap.AddUFunction(this, n"OnOverlap");
			Collision.OnComponentEndOverlap.AddUFunction(this, n"OnEndOverlap");
		}
		
	}

	UFUNCTION()
	private void OnOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                       UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep,
	                       const FHitResult&in SweepResult)
	{	
		if (bDisableOverlap)
			return;
		
		auto Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;

		if (Player == Game::GetPlayer(EHazePlayer::Mio)) 
			bMioOn = true;

		if (Player == Game::GetPlayer(EHazePlayer::Zoe)) 
			bZoeOn = true;

		if (MoveAnimation.IsPlaying())
			return;

		CrumbActivate();

	}

	UFUNCTION()
	void OnPlayerEnter(AHazePlayerCharacter Player)
	{
		if (MoveAnimation.IsPlaying())
			return;

		CrumbActivate();
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
		BaseComp.SetRelativeScale3D(Math::Lerp(FVector(0.01,0.01,0.01),FVector(1,1,1), Alpha));
		SetActorLocation(Math::Lerp(StartingPosition, EndingPosition, Alpha));
		// Root.SetWorldLocation(Math::Lerp(StartLocation, EndLocation, Alpha));
		// Root.AddLocalRotation(FRotator(1,1, 1));
		// SetActorRelativeRotation(FQuat::SlerpFullPath(StartingRotation, EndingRotation, Alpha));

	}

	UFUNCTION()
	void OnFinished()
	{
		bool bShouldActivate;

		if (bMioOn && bCanHurPlayer)
			Game::GetPlayer(EHazePlayer::Mio).DamagePlayerHealth(Damage);
		if (bZoeOn && bCanHurPlayer)
			Game::GetPlayer(EHazePlayer::Zoe).DamagePlayerHealth(Damage);

		Niagara::SpawnOneShotNiagaraSystemAtLocation(Effect, GetActorLocation());
		
		OnUpdate(0.0);
		
		if (!HasControl())
			return;

		if (bMioOn && !Game::GetPlayer(EHazePlayer::Mio).IsPlayerDead())
			CrumbActivate();
		if(bZoeOn && !Game::GetPlayer(EHazePlayer::Zoe).IsPlayerDead())
			CrumbActivate(); 

	}

	UFUNCTION()
	void Activate()
	{
		if (HasControl())
			CrumbActivate();
	}

	UFUNCTION(CrumbFunction)
	void CrumbActivate()
	{
		if (StoneBeastRef != nullptr)
		{
			StartingPosition = StoneBeastRef.MuzzleComp.GetWorldLocation();
			//StoneBeastRef.TriggerShoot();
		}

		if (ShootEffect != nullptr)
			Niagara::SpawnOneShotNiagaraSystemAtLocation(ShootEffect, StartingPosition);

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
class USummitEggChaseProjectileEffectHandler : UHazeEffectEventHandler
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