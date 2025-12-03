event void FonWalkerSwingComplete();

class AMeltdownBossFlyingBigSwingWalker : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UHazeSkeletalMeshComponentBase WalkerHead;

	UPROPERTY(DefaultComponent, Attach = WalkerHead)
	UHazeCapsuleCollisionComponent Collision;

	FHazeTimeLike SwingAnim;
	default SwingAnim.Duration = 3.0;
	default SwingAnim.UseSmoothCurveZeroToOne();

	FHazeTimeLike HeightLike;
	default HeightLike.Duration = 1.0;
	default HeightLike.UseSmoothCurveZeroToOne();

	FRotator LeftSwing = FRotator(0.0,-45.0,0.0);
	FRotator RightSwing =  FRotator(0.0,45.0,0.0);

	AHazePlayerCharacter TargetPlayer;

	UPROPERTY(EditAnywhere)
	AMeltdownBoss Rader;

	UPROPERTY()
	FonWalkerSwingComplete SwingComplete;

	float TargetHeight;

	bool bTrackPlayerVertical = false;
	bool bTrackPlayerHorizontal = false;
	FHazeAcceleratedRotator AccRotation;


	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AddActorDisable(this);
		SwingAnim.BindFinished(this, n"SwingDone");
		SwingAnim.BindUpdate(this, n"SwingUpdate");


		Collision.OnComponentBeginOverlap.AddUFunction(this, n"DamageOverlap");
	}

	UFUNCTION()
	private void DamageOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                           UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep,
	                           const FHitResult&in SweepResult)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);

		if(Player == nullptr)
			return;

		Player.DamagePlayerHealth(0.5);
	}

	UFUNCTION(BlueprintCallable)
	void Launch()
	{
		RemoveActorDisable(this);
		Timer::SetTimer(this, n"StartSwing", 2.0);
		ChargeFX();

		TargetPlayer = Game::Mio;
		Rader.SetLookTarget(TargetPlayer);

		ActorRotation = FRotator::MakeFromXZ(TargetPlayer.ActorLocation - ActorLocation, FVector::UpVector);
		AccRotation.SnapTo(ActorRotation);

		WalkerHead.SetRelativeRotation(LeftSwing);
		bTrackPlayerVertical = true;
		bTrackPlayerHorizontal = true;
	}

	UFUNCTION(BlueprintEvent)
	void ChargeFX()
	{	
	}

	UFUNCTION(BlueprintEvent)
	void StartFire()
	{
	}

	UFUNCTION(BlueprintEvent)
	void StopFire()
	{
	}

	UFUNCTION()
	void StartSwing()
	{
		SwingAnim.PlayFromStart();
		StartFire();

		bTrackPlayerHorizontal = false;
		bTrackPlayerVertical = false;
	}

	UFUNCTION()
	void StartBackSwing()
	{
		SwingAnim.ReverseFromEnd();
		StartFire();

		bTrackPlayerHorizontal = false;
		bTrackPlayerVertical = false;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		FRotator TargetRotation = FRotator::MakeFromXZ(TargetPlayer.ActorLocation - ActorLocation, FVector::UpVector);
		if (!bTrackPlayerHorizontal)
			TargetRotation.Yaw = ActorRotation.Yaw;
		if (!bTrackPlayerVertical)
			TargetRotation.Pitch = ActorRotation.Pitch;

		AccRotation.AccelerateTo(TargetRotation, 1.0, DeltaSeconds);
		SetActorRotation(AccRotation.Value);
	}

	UFUNCTION()
	private void SwingUpdate(float CurrentValue)
	{
		WalkerHead.SetRelativeRotation(Math::LerpShortestPath(LeftSwing, RightSwing, CurrentValue));
	}

	UFUNCTION()
	private void SwingDone()
	{
		if(SwingAnim.IsReversed())
		{
			StopFire();
			SwingComplete.Broadcast();
			AddActorDisable(this);
			return;
		}

		TargetPlayer = Game::Zoe;
		Rader.SetLookTarget(TargetPlayer);
		bTrackPlayerHorizontal = true;
		bTrackPlayerVertical = true;

		Timer::SetTimer(this, n"StartBackSwing", 2.0);
		StopFire();
		ChargeFX();
	}
};