event void FOnBattlefieldSlowMoDebrisCompleted();

class ABattlefieldSlowmoDebrisLaunch : AHazeActor
{
	UPROPERTY()
	FOnBattlefieldSlowMoDebrisCompleted OnBattlefieldSlowMoDebrisCompleted;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent EyeMeshComp;
	default EyeMeshComp.SetCollisionEnabled(ECollisionEnabled::NoCollision);

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent EyeDestructionSystem;
	default EyeDestructionSystem.bAutoActivate = false;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UFauxPhysicsAxisRotateComponent DebrisDoorRoot;

	UPROPERTY(DefaultComponent, Attach = DebrisDoorRoot)
	UFauxPhysicsForceComponent ForceComp;
	default ForceComp.Force = FVector(0.0);

	UPROPERTY(EditAnywhere)
	AGrappleLaunchPoint GrappleLaunch;

	UPROPERTY(EditAnywhere)
	ADeathVolume DeathVolume;

	UPROPERTY(EditAnywhere)
	APlayerTrigger GameOverFalseTrigger;

	UPROPERTY(EditAnywhere)
	ACapabilityBlockVolume BlockVolume;

	UPROPERTY(EditAnywhere, Category = "Setup")
	AAlienCruiser AlienCruiser;

	UPROPERTY(EditDefaultsOnly)
	UPlayerHealthSettings HealthSettings;

	UPROPERTY()
	UMovementGravitySettings GravitySettings;

	FVector Velocity;
	FVector Gravity = FVector(0, 0, 6000.0);
	float Force = 4000.0;
	float RotationAmount = 150.0;
	bool bApplyingForce;

	FVector ResetLocation;

	TPerPlayer<bool> bPlayersGrappled;
	TPerPlayer<bool> PlayerBlockedCapabilities;

	bool bGrappleSequenceStarted;
	bool bFinishGrappleSequence;
	bool bHaveFailed;
	bool bMoveToPosition;
	bool bMoveToKill;

	float FailTime = 2.0;

	float TimeDilationInterpSpeed = 0.5;
	float CurrentTimeDilation = 0.4;
	float TargetTimeDilationSlow = 0.15;

	bool bCanSlowMo;

	FRotator GrappleWorldRotation;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		GrappleLaunch.OnPlayerInitiatedGrappleToPointEvent.AddUFunction(this, n"OnPlayerInitiatedGrappleToPointEvent");
		GameOverFalseTrigger.OnPlayerEnter.AddUFunction(this, n"GameOverPlayerEnter");
		ResetLocation = ActorLocation;
		AttachToComponent(AlienCruiser.SkelMesh, n"Spinner", EAttachmentRule::SnapToTarget, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, false);
		FVector Forward = AlienCruiser.SkelMesh.GetBoneTransform(n"Spinner").Rotation.ForwardVector;
		ActorLocation += Forward * 1200.0;

		GrappleWorldRotation = GrappleLaunch.GrappleLaunchPoint.WorldRotation;
		GrappleLaunch.GrappleLaunchPoint.SetAbsolute(false, true, false);
		GrappleLaunch.GrappleLaunchPoint.WorldRotation = GrappleWorldRotation; 
	}

	UFUNCTION()
	private void OnPlayerInitiatedGrappleToPointEvent(AHazePlayerCharacter Player,
											  UGrapplePointBaseComponent GrapplePoint)
	{
		bPlayersGrappled[Player] = true;

		if (bPlayersGrappled[Player.OtherPlayer])
		{
			GrappleLaunch.DetachFromActor(EDetachmentRule::KeepWorld);
			
			ForceComp.Force = FVector(15000.0, 0, 0);
			bMoveToKill = false;
			Player.ClearSettingsByInstigator(this);
			Player.OtherPlayer.ClearSettingsByInstigator(this);
			EyeDestructionSystem.Activate();
			DeathVolume.AddActorDisable(this);

			Velocity = MeshRoot.ForwardVector * Force;
			bApplyingForce = true;
			bFinishGrappleSequence = true;

			FinishSequence(false);
		}
	}

	UFUNCTION()
	private void GameOverPlayerEnter(AHazePlayerCharacter Player)
	{
		for (AHazePlayerCharacter CurrentPlayer : Game::Players)
			CurrentPlayer.ClearSettingsByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (bApplyingForce)
		{
			Velocity -= Gravity * DeltaSeconds;
			MeshRoot.WorldLocation += Velocity * DeltaSeconds;
			MeshRoot.RelativeRotation += FRotator(RotationAmount, 0, 0) * DeltaSeconds;
		}

		if (bCanSlowMo)
		{
			if (UPlayerHealthComponent::Get(Game::Mio).bIsDead && UPlayerHealthComponent::Get(Game::Zoe).bIsDead)
				CurrentTimeDilation = Math::FInterpConstantTo(CurrentTimeDilation, 1.0, DeltaSeconds, 2.0);
			else if (bFinishGrappleSequence)
				CurrentTimeDilation = Math::FInterpConstantTo(CurrentTimeDilation, 1.0, DeltaSeconds, TimeDilationInterpSpeed * 2.0);
			else
				CurrentTimeDilation = Math::FInterpConstantTo(CurrentTimeDilation, TargetTimeDilationSlow, DeltaSeconds, TimeDilationInterpSpeed * 2.5);

			Time::SetWorldTimeDilation(CurrentTimeDilation);
		}

		if (bGrappleSequenceStarted)
		{
			if (Time::GameTimeSeconds > FailTime && !bFinishGrappleSequence)
			{
				bHaveFailed = true;
				GrappleLaunch.AddActorDisable(this);
				bFinishGrappleSequence = true;
				FinishSequence(true);
			}
		}
	}

	UFUNCTION()
	void ActivateGrappleSequence()
	{
		bCanSlowMo = true;
		bGrappleSequenceStarted = true;

		Time::SetWorldTimeDilation(CurrentTimeDilation);
		FailTime = Time::GameTimeSeconds + (FailTime * CurrentTimeDilation);

		FHazePointOfInterestFocusTargetInfo POITarget;
		POITarget.SetFocusToActor(GrappleLaunch);
		FApplyPointOfInterestSettings POISettings;

		for (AHazePlayerCharacter Player : Game::Players)
		{
			Player.BlockCapabilities(CapabilityTags::StickInput, this);
			Player.BlockCapabilities(n"HoverboardTricks", this);
			Player.ApplyPointOfInterest(this, POITarget, POISettings);
			Player.ApplySettings(GravitySettings, this, EHazeSettingsPriority::Script);
			Player.ApplySettings(HealthSettings, this, EHazeSettingsPriority::Override);
			PlayerBlockedCapabilities[Player] = true;
		}
	}

	void FinishSequence(bool bFailed)
	{
		for (AHazePlayerCharacter Player : Game::Players)
		{
			if (PlayerBlockedCapabilities[Player])
			{
				Player.UnblockCapabilities(CapabilityTags::StickInput, this);
				Player.UnblockCapabilities(n"HoverboardTricks", this);
			}

			Player.ClearPointOfInterestByInstigator(this);
			PlayerBlockedCapabilities[Player] = false;
			Player.ClearSettingsWithAsset(GravitySettings, this);
		}

		BlockVolume.AddActorDisable(this);
		GrappleLaunch.GrappleLaunchPoint.Disable(this);
		OnBattlefieldSlowMoDebrisCompleted.Broadcast();
	}
};