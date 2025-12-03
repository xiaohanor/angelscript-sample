enum ESketchBookSimpleEnemyState
{
	None,
	Rotate,
	Moving
}

UCLASS(Abstract)
class ASketchbookSimpleEnemy : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent RotationRoot;
		
	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeMovablePlayerTriggerComponent PlayerTriggerComp;

	UPROPERTY(DefaultComponent, Attach = RotationRoot)
	UStaticMeshComponent MeshComp;

	UPROPERTY(DefaultComponent, Attach = RotationRoot)
	UHazeSkeletalMeshComponentBase SkelMesh;

	UPROPERTY()
	UForceFeedbackEffect DeathFF;

	UPROPERTY(DefaultComponent)
	USketchbookArrowResponseComponent ArrowResponseComp;

	UPROPERTY(DefaultComponent)
	USketchbookBowAutoAimComponent ArrowAutoAimComp;

	UPROPERTY(DefaultComponent, Attach = ArrowAutoAimComp)
	UHazeRawVelocityTrackerComponent RawVelocityTrackerComp;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UDamageEffect> DamageEffect;

	UPROPERTY()
	UForceFeedbackEffect KnockdownForceFeedback;

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly)
	USketchbookFontLookupDataAsset FontLookup;

	AHazeActor TargetActor;

	UPROPERTY(EditAnywhere)
	ASketchBook_SimpleEnemyManager EnemyManger;

	float RotationTimer = 1;
	float TimeSinceLastRotation = 0;

	float Wiggle = 10;

	bool bDead = false;
	
	UPROPERTY(EditAnywhere)
	ESketchBookSimpleEnemyState EnemyState;


	/** Time to freeze in the first pose before the animation starts playing */
	UPROPERTY(EditAnywhere)
	float AnimationDelay = 0.3;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetEnemyState(EnemyState);
		PlayerTriggerComp.OnPlayerEnter.AddUFunction(this, n"OnPlayerEnter");
		ArrowResponseComp.OnHitByArrow.AddUFunction(this, n"OnHitByArrow");
		
		USketchbookDrawableComponent::Get(this).OnStartBeingDrawn.AddUFunction(this, n"BP_OnDrawn");

		if(USketchbookMeleeAttackableComponent::Get(this) != nullptr)
			USketchbookMeleeAttackableComponent::Get(this).OnAttacked.AddUFunction(this, n"OnHitMelee");
	}

	UFUNCTION()
	private void OnHitByArrow(FSketchbookArrowHitEventData ArrowHitData, FVector ArrowLocation)
	{
		if(bDead)
			return;

		Game::Zoe.PlayForceFeedback(DeathFF,false,false,this,1);
		Game::Mio.PlayForceFeedback(DeathFF,false,false,this,1);

		USketchbookEnemyEventHandler::Trigger_OnKilledBow(this);
		Kill();
	}

	UFUNCTION()
	private void OnHitMelee(FSketchbookMeleeAttackData AttackData)
	{
		if(bDead)
			return;

		AttackData.AttackingPlayer.PlayForceFeedback(DeathFF,false,false,this,1);

		USketchbookEnemyEventHandler::Trigger_OnKilledMelee(this);
		Kill();
	}

	UFUNCTION()
	void Kill()
	{
		if(bDead)
			return;

		AddActorCollisionBlock(this);
		if(EnemyManger != nullptr)
		{
			EnemyManger.EnemyKilled();
			bDead = true;
		}

		BP_OnKilled();
	}

	UFUNCTION()
	private void OnPlayerEnter(AHazePlayerCharacter Player)
	{
		if(EnemyState == ESketchBookSimpleEnemyState::Rotate || EnemyState == ESketchBookSimpleEnemyState::Moving)
		{
			FVector Impulse = (Player.ActorLocation - GetActorLocation());
			Impulse.Normalize();
			Impulse*=700;
			Impulse.Z*=0;
			Impulse.Z +=500;
			//Player.ResetMovement();
			//Player.AddMovementImpulse(Impulse);
			Player.ApplyKnockdown(Impulse, 1);
			Player.PlayForceFeedback(KnockdownForceFeedback, false, false, this);

			SetAnimTrigger(n"Attack");
		}

		Player.DamagePlayerHealth(0.0, FPlayerDeathDamageParams(), DamageEffect);
	}

	UFUNCTION(BlueprintCallable,BlueprintEvent)
	void SetEnemyState(ESketchBookSimpleEnemyState NewState)
	{
		EnemyState = NewState;
		if(EnemyState == ESketchBookSimpleEnemyState::Rotate)
			StartRotate();

		if(EnemyState == ESketchBookSimpleEnemyState::Moving)
		{
			StartMoving();
		}
	}

	UFUNCTION(BlueprintEvent)
	void BP_OnDrawn(){}

	UFUNCTION(BlueprintEvent)
	void BP_OnKilled(){}

	void StartRotate()
	{
		// RotationRoot.SetRelativeRotation(FRotator(RotationRoot.RelativeRotation.Pitch, RotationRoot.RelativeRotation.Yaw,Wiggle));
	}
		
	void StartMoving()
	{
		// RotationRoot.SetRelativeRotation(FRotator(RotationRoot.RelativeRotation.Pitch, RotationRoot.RelativeRotation.Yaw,Wiggle));
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		//it move to close player
		if (EnemyState == ESketchBookSimpleEnemyState::Moving)
		{
			TargetActor = Game::GetClosestPlayer(ActorLocation);
			FVector TargetActorlocation = TargetActor.ActorLocation;
			TargetActorlocation.Z = ActorLocation.Z;

			ActorLocation = Math::VInterpConstantTo(GetActorLocation(),TargetActorlocation,DeltaSeconds,50);

			if(TargetActor.GetActorLocation().Y < GetActorLocation().Y)
				RotationRoot.SetRelativeRotation(FRotator(RotationRoot.RelativeRotation.Pitch, 90, RotationRoot.RelativeRotation.Roll));
			else
				RotationRoot.SetRelativeRotation(FRotator(RotationRoot.RelativeRotation.Pitch, -90, RotationRoot.RelativeRotation.Roll));
		}

		//it be rotate
		// if (EnemyState == ESketchBookSimpleEnemyState::Moving || EnemyState == ESketchBookSimpleEnemyState::Rotate)
		// 	if(Time::GetGameTimeSince(TimeSinceLastRotation) > RotationTimer)
		// 		{
		// 			Wiggle*=-1;
		// 			RotationRoot.SetRelativeRotation(FRotator(RotationRoot.RelativeRotation.Pitch, RotationRoot.RelativeRotation.Yaw,Wiggle));
		// 			TimeSinceLastRotation = Time::GameTimeSeconds;
		// 		}
	}

	UFUNCTION(BlueprintCallable)
	void ApplyRenderedText(FText Text, UTextRenderComponent TextRender)
	{
		if (FontLookup != nullptr)
			SketchbookLocHelpers::ApplyRenderTextFont(FontLookup, TextRender);
		
		TextRender.SetText(Text);
	}

};
