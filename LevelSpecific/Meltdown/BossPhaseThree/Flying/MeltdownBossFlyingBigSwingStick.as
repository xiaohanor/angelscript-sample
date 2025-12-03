event void FonSwingComplete();

class AMeltdownBossFlyingBigSwingStick : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent WalkingStick;

	UPROPERTY(DefaultComponent, Attach = WalkingStick)
	UHazeCapsuleCollisionComponent Collision;

	FHazeTimeLike SwingAnim;
	default SwingAnim.Duration = 3.0;
	default SwingAnim.UseSmoothCurveZeroToOne();

	FHazeTimeLike HeightLike;
	default HeightLike.Duration = 1.0;
	default HeightLike.UseSmoothCurveZeroToOne();

	FRotator LeftSwing = FRotator(0.0,-65.0,0.0);
	FRotator RightSwing =  FRotator(0.0,65.0,0.0);

	AHazePlayerCharacter TargetPlayer;

	UPROPERTY()
	FonSwingComplete SwingComplete;

	float TargetHeight;


	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AddActorDisable(this);

		TargetPlayer = Game::Mio;

		TargetHeight = TargetPlayer.ActorLocation.Z;

		SwingAnim.BindFinished(this, n"SwingDone");
		SwingAnim.BindUpdate(this, n"SwingUpdate");

		HeightLike.BindFinished(this, n"HeightAdjusted");
		HeightLike.BindUpdate(this, n"AdjustHeight");

		Collision.OnComponentBeginOverlap.AddUFunction(this, n"DamageOverlap");
	}

	UFUNCTION()
	private void AdjustHeight(float CurrentValue)
	{

	}

	UFUNCTION()
	private void HeightAdjusted()
	{
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
	}

	UFUNCTION()
	void StartSwing()
	{
		SwingAnim.PlayFromStart();
		SetActorTickEnabled(false);
	}

	UFUNCTION()
	void StartBackSwing()
	{
		SwingAnim.ReverseFromEnd();
		SetActorTickEnabled(false);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		TargetHeight = TargetPlayer.ActorLocation.Z;

		WalkingStick.SetRelativeLocation(FVector(-4000,0,TargetHeight));
	}

	UFUNCTION()
	private void SwingUpdate(float CurrentValue)
	{
		MeshRoot.SetRelativeRotation(Math::LerpShortestPath(LeftSwing, RightSwing, CurrentValue));
	}

	UFUNCTION()
	private void SwingDone()
	{
		if(SwingAnim.IsReversed())
		{
			SwingComplete.Broadcast();
			AddActorDisable(this);
			return;
		}

		TargetPlayer = Game::Zoe;
		SetActorTickEnabled(true);
		Timer::SetTimer(this, n"StartBackSwing", 2.0);
	}

};