UCLASS(Abstract)
class APrisonDrones_Shark : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeMovablePlayerTriggerComponent OverlapComp;
	default OverlapComp.TriggeredByPlayers = EHazeSelectPlayer::Mio;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeSkeletalMeshComponentBase SkelMesh;

	UPROPERTY(EditDefaultsOnly)
	FHazePlaySlotAnimationParams AnimParams;

	UPROPERTY(DefaultComponent, Attach = SkelMesh, AttachSocket = Head)
	UDeathVolumeComponent DeathVolumeComp;

	UPROPERTY(VisibleInstanceOnly)
	bool bIsAttacking;

	TPerPlayer<bool> bWantsToAttack;

	FVector FirstLocation;
	float AttackTimer;
	UNiagaraComponent ForeshadowNiagaraComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorControlSide(Game::Mio);

		OverlapComp.OnPlayerEnter.AddUFunction(this, n"OnPlayerEnter");
		OverlapComp.OnPlayerLeave.AddUFunction(this, n"OnPlayerLeave");
		DeathVolumeComp.OnPlayerEnter.AddUFunction(this, n"OnPlayerKill");

		FirstLocation = ActorLocation;

		ForeshadowNiagaraComp = BP_GetForeshadowNiagaraComponent();

		SkelMesh.AddComponentVisualsAndCollisionAndTickBlockers(this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(bIsAttacking)
		{
			FVector MioLocation = Game::Mio.ActorLocation;
			MioLocation.Z = ActorLocation.Z;
			SetActorLocation(MioLocation);
		}
		else if (WantsToAttack())
		{
			AttackTimer -= DeltaSeconds;

			if (HasControl() && AttackTimer <= 0)
				Crumb_Attack();
		}

		const bool bShouldForeshadow = ShouldForeshadow();
		if(ForeshadowNiagaraComp.IsActive() != bShouldForeshadow)
		{
			if(bShouldForeshadow)
				ForeshadowNiagaraComp.Activate(false);
			else
				ForeshadowNiagaraComp.Deactivate();
		}
	}

	UFUNCTION(BlueprintEvent)
	UNiagaraComponent BP_GetForeshadowNiagaraComponent() const { return nullptr; }

	UFUNCTION()
	private void OnPlayerKill(AHazePlayerCharacter Player)
	{
		UPrisonDronesSharkEventHandler::Trigger_SharkBiteEvent(this);
		Online::UnlockAchievement(n"SharkDeath");
	}

	UFUNCTION()
	private void OnPlayerEnter(AHazePlayerCharacter Player)
	{
		if(!WantsToAttack())
			AttackTimer = 0.3;
		
		bWantsToAttack[Player] = true;
	}

	UFUNCTION()
	private void OnPlayerLeave(AHazePlayerCharacter Player)
	{
		bWantsToAttack[Player] = false;
	}

	bool WantsToAttack() const
	{
		return bWantsToAttack[0] || bWantsToAttack[1];
	}

	UFUNCTION(CrumbFunction)
	private void Crumb_Attack()
	{
		if(bIsAttacking)
			return;

		bIsAttacking = true;
		bWantsToAttack[0] = false;
		bWantsToAttack[1] = false;

		SkelMesh.RemoveComponentVisualsAndCollisionAndTickBlockers(this);

		SkelMesh.ResetAllAnimation();
		SkelMesh.PlaySlotAnimation(FHazeAnimationDelegate(),
								   FHazeAnimationDelegate(this, n"OnAttackFinished"),
								   AnimParams);

		UPrisonDronesSharkEventHandler::Trigger_SharkStartEvent(this);
	}

	UFUNCTION()
	private void OnAttackFinished()
	{
		bIsAttacking = false;
		bWantsToAttack[0] = false;
		bWantsToAttack[1] = false;

		SetActorLocation(FirstLocation);

		SkelMesh.AddComponentVisualsAndCollisionAndTickBlockers(this);
	}

	bool ShouldForeshadow() const
	{
		if(WantsToAttack())
			return false;

		if(bIsAttacking)
			return false;

		return true;
	}
};
