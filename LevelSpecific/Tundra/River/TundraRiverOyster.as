class ATundraRiverOyster : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent Collision;
	default Collision.CollisionProfileName = n"TriggerOnlyPlayer";

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeCameraComponent CameraWhileTrapped;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent Scene_Shake;

	UPROPERTY(DefaultComponent, Attach = Scene_Shake)
	USceneComponent Scene_Angle;

	UPROPERTY(DefaultComponent, Attach = Scene_Angle)
	UStaticMeshComponent SM_Clam_Top;

	UPROPERTY(DefaultComponent, Attach = Scene_Angle)
	UHazeDecalComponent YellowDecal;

	UPROPERTY(DefaultComponent, Attach = Scene_Angle)
	UBoxComponent PlayerOntopCheck;
	default PlayerOntopCheck.CollisionProfileName = n"TriggerOnlyPlayer";

	UPROPERTY(DefaultComponent, Attach = Scene_Shake)
	UArrowComponent LaunchDirection;

	UPROPERTY(DefaultComponent, Attach = Scene_Shake)
	UStaticMeshComponent SM_Clam_Bottom;

	UPROPERTY()
	FHazeTimeLike CloseAnimation;	
	default CloseAnimation.Duration = 0.8;
	default CloseAnimation.Curve.AddDefaultKey(0.0, 0.0);
	default CloseAnimation.Curve.AddDefaultKey(0.1, 0.02);
	default CloseAnimation.Curve.AddDefaultKey(0.5, 0.07);
	default CloseAnimation.Curve.AddDefaultKey(0.8, 1.0);

	UPROPERTY()
	FHazeTimeLike SlowOpenAnimation;	
	default SlowOpenAnimation.Duration = 3;
	default SlowOpenAnimation.Curve.AddDefaultKey(0.0, 0.0);
	default SlowOpenAnimation.Curve.AddDefaultKey(3.0, 1.0);

	UPROPERTY()
	FHazeTimeLike QuickOpenAnimation;	
	default QuickOpenAnimation.Duration = 0.2;
	default QuickOpenAnimation.Curve.AddDefaultKey(0.0, 0.0);
	default QuickOpenAnimation.Curve.AddDefaultKey(0.2, 1.0);
	default QuickOpenAnimation.Curve.AddDefaultKey(0.16, 1.0);

	float TempStartAnimationAngle;

	UPROPERTY(EditInstanceOnly)
	float DefaultAngle = 56;

	UPROPERTY(EditInstanceOnly)
	float LaunchImpulse = 2000;

	float CurrentAngle;
	float DelayBeforeReenablingCollision;

	TArray<AHazePlayerCharacter> PlayersInsideOyster;
	TArray<AHazePlayerCharacter> PlayersOnTopOfOyster;
	bool bOysterIsClosed = false;

	UFUNCTION(CallInEditor)
	void InitAngle()
	{
		CurrentAngle = DefaultAngle;
		UpdateAngle();
	}

	UFUNCTION()
	void UpdateAngle()
	{
		Scene_Angle.SetRelativeRotation(FRotator(0,0,-CurrentAngle));
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		InitAngle();
		Collision.OnComponentBeginOverlap.AddUFunction(this, n"OnPlayerInsideOyster");
		Collision.OnComponentEndOverlap.AddUFunction(this, n"OnPlayerNotInsideOyster");
		PlayerOntopCheck.OnComponentBeginOverlap.AddUFunction(this, n"OnPlayerOntopOyster");
		PlayerOntopCheck.OnComponentEndOverlap.AddUFunction(this, n"OnPlayerNotOntopOyster");
		CloseAnimation.BindUpdate(this, n"TL_ClosingOyster");
		CloseAnimation.BindFinished(this, n"TL_CloseAnimationFinished");
		SlowOpenAnimation.BindUpdate(this, n"TL_SlowOpenOyster");
		SlowOpenAnimation.BindFinished(this, n"TL_SlowOpenAnimationFinished");
		QuickOpenAnimation.BindUpdate(this, n"TL_QuickOpenOyster");
		QuickOpenAnimation.BindFinished(this, n"TL_QuickOpenOysterFinished");
		LaunchDirection.DetachFromComponent(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, true);
	}

	UFUNCTION()
	private void TL_SlowOpenAnimationFinished()
	{
		UTundraRiverOyster_EffectHandler::Trigger_OnFullyOpen(this);
	}

	UFUNCTION()
	private void TL_CloseAnimationFinished()
	{
		UTundraRiverOyster_EffectHandler::Trigger_OnFullyClosed(this);
	}

	UFUNCTION()
	void OnPlayerInsideOyster(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComponent, int OtherBodyIndex, bool bFromSweep, const FHitResult&in HitResult)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if(Player == nullptr)
			return;

		PlayersInsideOyster.AddUnique(Player);
		//TryToCloseOyster();
	}

	UFUNCTION()
	void OnPlayerNotInsideOyster(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComponent, int OtherBodyIndex)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if(Player == nullptr)
			return;

		Player.DeactivateCameraByInstigator(this, 0.5);
		PlayersInsideOyster.Remove(Player);
		if(PlayersInsideOyster.Num() <= 0)
			TryToSlowOpenOyster();
	}

	UFUNCTION()
	void OnPlayerOntopOyster(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComponent, int OtherBodyIndex, bool bFromSweep, const FHitResult&in HitResult)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if(Player == nullptr)
			return;

		PlayersOnTopOfOyster.AddUnique(Player);
	}

	UFUNCTION()
	void OnPlayerNotOntopOyster(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComponent, int OtherBodyIndex)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if(Player == nullptr)
			return;

		PlayersOnTopOfOyster.Remove(Player);
	}

	UFUNCTION(BlueprintCallable)
	void ApplyOysterImpulse(AHazePlayerCharacter Player, FVector Direction, float Impulse)
	{
		float LocalImpulse;

		if(UTundraPlayerShapeshiftingComponent::Get(Player).ActiveShapeType == ETundraShapeshiftActiveShape::Small)
		{
			if(Player.IsZoe())
			{
				LocalImpulse = Impulse;
			}
			else
			{
				LocalImpulse = Impulse * 0.5;
			}
		}
		else if(UTundraPlayerShapeshiftingComponent::Get(Player).ActiveShapeType == ETundraShapeshiftActiveShape::Player)
		{
			LocalImpulse = Impulse * 0.5;
		}
		else
		{
			LocalImpulse = Impulse * 0.25;
		}

		UHazeMovementComponent::Get(Player).AddPendingImpulse(Direction*LocalImpulse);
	}

	UFUNCTION()
	void TryToCloseOyster()
	{
		if(bOysterIsClosed)
			return;

		UTundraRiverOyster_EffectHandler::Trigger_Close(this);
		QuickOpenAnimation.Stop();
		SlowOpenAnimation.Stop();
		TempStartAnimationAngle = CurrentAngle;
		bOysterIsClosed = true;
		for(auto Player : PlayersInsideOyster)
		{
			Player.ActivateCamera(CameraWhileTrapped, 0.5, this, EHazeCameraPriority::High);
		}
		CloseAnimation.PlayFromStart();
	}

	UFUNCTION()
	void TL_ClosingOyster(float CurveValue)
	{
		CurrentAngle = Math::Lerp(TempStartAnimationAngle, 0, CurveValue);
		UpdateAngle();
	}

	UFUNCTION()
	void TryToSlowOpenOyster()
	{
		if(!bOysterIsClosed)
			return;

		UTundraRiverOyster_EffectHandler::Trigger_SlowOpen(this);
		CloseAnimation.Stop();
		QuickOpenAnimation.Stop();
		bOysterIsClosed = false;
		TempStartAnimationAngle = CurrentAngle;
		for(auto Player : PlayersInsideOyster)
		{
			Player.DeactivateCameraByInstigator(this, 0.5);
		}
		SlowOpenAnimation.PlayFromStart();
	}

	UFUNCTION()
	void TL_SlowOpenOyster(float CurveValue)
	{
		CurrentAngle = Math::Lerp(TempStartAnimationAngle, DefaultAngle, CurveValue);
		UpdateAngle();
	}

	UFUNCTION()
	void ForceOpen()
	{
		if(!bOysterIsClosed)
			return;

		UTundraRiverOyster_EffectHandler::Trigger_QuickOpen(this);
		CloseAnimation.Stop();
		SlowOpenAnimation.Stop();
		bOysterIsClosed = false;
		TempStartAnimationAngle = CurrentAngle;
		SM_Clam_Top.SetCollisionEnabled(ECollisionEnabled::NoCollision);

		for(auto Player : PlayersInsideOyster)
		{
			Player.DeactivateCameraByInstigator(this, 0.5);
		}

		for(auto Player : PlayersOnTopOfOyster)
		{
			if(PlayersInsideOyster.Contains(Player))
				return;
			Player.TeleportActor(LaunchDirection.GetWorldLocation(), Player.GetActorRotation(), this, false);
			ApplyOysterImpulse(Player, LaunchDirection.GetForwardVector(), LaunchImpulse);
		}

		QuickOpenAnimation.PlayFromStart();
	}

	UFUNCTION()
	void TL_QuickOpenOyster(float CurveValue)
	{
		CurrentAngle = Math::Lerp(TempStartAnimationAngle, DefaultAngle, CurveValue);
		UpdateAngle();
	}

	UFUNCTION()
	void TL_QuickOpenOysterFinished()
	{
		DelayBeforeReenablingCollision = 1.0;
		UTundraRiverOyster_EffectHandler::Trigger_OnFullyOpen(this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(DelayBeforeReenablingCollision > 0)
		{
			DelayBeforeReenablingCollision -= DeltaSeconds;
			if(DelayBeforeReenablingCollision <= 0)
			{
				SM_Clam_Top.SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);
			}
		}

		bool bHasForceOpened = false;
		for(auto Player : PlayersInsideOyster)
		{
			UTundraPlayerShapeshiftingComponent ShiftComp = UTundraPlayerShapeshiftingComponent::Get(Player);
			if(ShiftComp == nullptr)
				return;

			if(ShiftComp.IsBigShape())
			{
				ForceOpen();
				bHasForceOpened = true;
			}
		}

		if(!bHasForceOpened && PlayersInsideOyster.Num() > 0)
		{
			TryToCloseOyster();
		}
	}
}