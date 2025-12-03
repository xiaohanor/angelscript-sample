class AEvergreenShootingPlant : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent RotationRoot;

	UPROPERTY(DefaultComponent, Attach = RotationRoot)
	USceneComponent FX_SplashLocation;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeSkeletalMeshComponentBase RootMesh;

	UPROPERTY(DefaultComponent, Attach = RootMesh, AttachSocket = Flower_Socket)
	UHazeSkeletalMeshComponentBase FlowerMesh;

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedRotatorComponent SyncedCurrentRotation;

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedFloatComponent SyncedRotationRate;

	UPROPERTY(EditAnywhere)
	AEvergreenLifeManager Manager;

	UPROPERTY(EditAnywhere)
	TSubclassOf<UDeathEffect> EatDeathEffect;

	UPROPERTY()
	UForceFeedbackEffect CaughtFF;

	UPROPERTY()
	UForceFeedbackEffect EatenFF;

	float TargetPitch = 0.0;
	FHazeAcceleratedRotator AcceleratedRotator;
	float CurrentRotationRate;
	AEvergreenPoleCrawler CaughtCrawler;
	AHazePlayerCharacter CaughtPlayer;
	bool bHasCaughtAnything = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorControlSide(Game::Zoe);
		Manager.LifeComp.OnInteractStartDuringLifeGive.AddUFunction(this, n"StartedShooting");
		AcceleratedRotator.SnapTo(RotationRoot.RelativeRotation);
	}

	UFUNCTION(BlueprintEvent)
	void StartedShooting() {}

	UFUNCTION()
	void OnShoot()
	{
		UEvergreenShootingPlantEffectHandler::Trigger_OnShoot(this);
		bHasCaughtAnything = false;
	}

	UFUNCTION()
	void OnPullInTongue()
	{
		if(!HasControl())
			return;

		if(CaughtCrawler != nullptr)
			CrumbSquishCrawler();

		if(CaughtPlayer != nullptr)
			CrumbSquishPlayer();
	}

	UFUNCTION()
	void OnOverlap(USphereComponent OverlapSphere, AActor Actor)
	{
		if(!HasControl())
			return;

		if(bHasCaughtAnything)
			return;

		auto Crawler = Cast<AEvergreenPoleCrawler>(Actor);
		if(Crawler != nullptr)
		{
			CrumbCatchPoleCrawler(OverlapSphere, Crawler);
			bHasCaughtAnything = true;
			return;
		}

		auto Player = Cast<AHazePlayerCharacter>(Actor);
		if(Player != nullptr)
		{
			CrumbCatchPlayer(OverlapSphere, Player);
			bHasCaughtAnything = true;
			Game::GetMio().PlayForceFeedback(CaughtFF, this);
		}
	}

	UFUNCTION(CrumbFunction)
	private void CrumbSquishPlayer()
	{
		CaughtPlayer.KillPlayer(DeathEffect = EatDeathEffect);
		Game::GetMio().PlayForceFeedback(EatenFF, this);
		UEvergreenShootingPlantEffectHandler::Trigger_OnSquishPlayer(this);
		CaughtPlayer.DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);
		CaughtPlayer.UnblockCapabilities(CapabilityTags::Movement, this);
		auto SyncedPos = UHazeCrumbSyncedActorPositionComponent::Get(CaughtPlayer);
		SyncedPos.TransitionSync(this);
		CaughtPlayer = nullptr;
	}

	UFUNCTION(CrumbFunction)
	private void CrumbSquishCrawler()
	{
		CaughtCrawler.DestroyCrawler();
		UEvergreenShootingPlantEffectHandler::Trigger_OnSquishPoleCrawler(this);
		CaughtCrawler = nullptr;
	}

	UFUNCTION(CrumbFunction)
	private void CrumbCatchPoleCrawler(UPrimitiveComponent AttachToComp, AEvergreenPoleCrawler Crawler)
	{
		Crawler.AttachToComponent(AttachToComp, NAME_None, EAttachmentRule::KeepWorld);
		Crawler.bHasBeenCaught = true;
		CaughtCrawler = Crawler;

		FEvergreenShootingPlantPoleCrawlerEffectParams Params;
		Params.PoleCrawler = Crawler;
		UEvergreenShootingPlantEffectHandler::Trigger_OnCaughtPoleCrawler(this, Params);
	}

	UFUNCTION(CrumbFunction)
	private void CrumbCatchPlayer(UPrimitiveComponent AttachToComp, AHazePlayerCharacter Player)
	{
		Player.AttachToComponent(AttachToComp, NAME_None, EAttachmentRule::KeepWorld);
		Player.BlockCapabilities(CapabilityTags::Movement, this);
		CaughtPlayer = Player;

		FEvergreenShootingPlantPlayerEffectParams Params;
		Params.Player = Player;
		UEvergreenShootingPlantEffectHandler::Trigger_OnCaughtPlayer(this, Params);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if(HasControl())
		{
			float HorizontalInput = Manager.LifeComp.RawHorizontalInput;
		
			float RotationRate = 0.0;
			if (Math::Abs(HorizontalInput) > 0.2)
			{
				float PreviousTargetPitch = TargetPitch;
				TargetPitch += HorizontalInput * 50.0 * DeltaTime;
				TargetPitch = Math::Clamp(TargetPitch, -30.0, 20.0);
				RotationRate = (TargetPitch - PreviousTargetPitch) / DeltaTime;
			}

			FRotator TargetRotation = FRotator(TargetPitch, RotationRoot.RelativeRotation.Yaw, RotationRoot.RelativeRotation.Roll);
			FRotator NewRotation = AcceleratedRotator.AccelerateTo(TargetRotation, 1.0, DeltaTime);
			SyncedCurrentRotation.Value = NewRotation;
			SyncedRotationRate.Value = Math::Abs(RotationRate) / 50.0;
		}

		float RotationRate = SyncedRotationRate.Value;
		if(Math::IsNearlyZero(RotationRate) != Math::IsNearlyZero(CurrentRotationRate))
		{
			if(Math::IsNearlyZero(RotationRate))
			{
				UEvergreenShootingPlantEffectHandler::Trigger_OnStopMoving(this);
			}
			else
			{
				UEvergreenShootingPlantEffectHandler::Trigger_OnStartMoving(this);
			}
		}

		CurrentRotationRate = RotationRate;
		RotationRoot.SetRelativeRotation(SyncedCurrentRotation.Value);
	}

	FRotator AnimationGetRotation()
	{
		return SyncedCurrentRotation.Value;
	}

	// Returns value between 0-1 which represents the current rotation speed
	UFUNCTION(BlueprintPure)
	float AudioGetCurrentRotationRate() const
	{
		return CurrentRotationRate;
	}
}