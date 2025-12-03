event void FOnStormSiegeMagicBarrierDeactivated();

UCLASS(Abstract)
class AStormSiegeMagicBarrier : AHazeActor
{
	UPROPERTY()
	FOnStormSiegeMagicBarrierDeactivated OnStormSiegeMagicBarrierDeactivated;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent BlockingVolume;
	default BlockingVolume.SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);
	default BlockingVolume.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Block);

	TArray<UStaticMeshComponent> MeshComps;

	UPROPERTY(EditAnywhere)
	TArray<AHazeActor> Targets;

	UPROPERTY(EditAnywhere)
	bool bTutorialMagicBarrier = false;
	bool bTutorialStarted;

	UPROPERTY(EditAnywhere)
	bool bEnemyKillableMagicBarrier = false;

	UPROPERTY(EditAnywhere, Meta = (EditCondition = "bTutorialMagicBarrier || bEnemyKillableMagicBarrier", EditConditionHides))
	float SequenceTime = 4.5;

	UPROPERTY(EditAnywhere, Meta = (EditCondition = "bTutorialMagicBarrier || bEnemyKillableMagicBarrier", EditConditionHides))
	AStaticCameraActor Camera;

	UPROPERTY(EditAnywhere, Meta = (EditCondition = "bTutorialMagicBarrier || bEnemyKillableMagicBarrier", EditConditionHides))
	TArray<AStormSiegeMagicBarrierGemBrazier> Braziers;

	UPROPERTY(EditAnywhere, Meta = (EditCondition = "bTutorialMagicBarrier || bEnemyKillableMagicBarrier", EditConditionHides))
	ARespawnPoint ReturnPoint;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> CameraShake;
	
	int MaxCount;
	int Count;

	bool bDeactivated;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		GetComponentsByClass(MeshComps);

		for (AHazeActor Target : Targets)
		{
			if (Target == nullptr)
				continue;

			UStormSiegeMagicBarrierResponseComponent Response = UStormSiegeMagicBarrierResponseComponent::Get(Target);

			if (Response != nullptr)
			{
				Response.OnStormSiegeMagicBarrierTargetTriggered.AddUFunction(this, n"OnStormSiegeMagicBarrierTargetTriggered");
				MaxCount++;
			}
		}
	}

	UFUNCTION()
	void ForceClearMagicBarrier()
	{
		Count = Targets.Num() - 1;
		OnStormSiegeMagicBarrierTargetTriggered();		
	}


	UFUNCTION()
	private void OnStormSiegeMagicBarrierTargetTriggered()
	{
		if (bDeactivated)
			return;

		Count++;

		if (!bTutorialStarted && bTutorialMagicBarrier)
		{
			bTutorialStarted = true;

			Timer::SetTimer(this, n"StartSequnce", 0.75);
			// StartSequnce();
			Timer::SetTimer(this, n"CompleteSequence", SequenceTime);
			Timer::SetTimer(Braziers[Count - 1], n"DeactivateGemBrazier", SequenceTime - 1.5);

			return;
		}

		if (Braziers.Num() > 0)
			Braziers[Count - 1].DeactivateGemBrazier();

		if (Count >= MaxCount)
		{
			if (bEnemyKillableMagicBarrier)
			{
				Timer::SetTimer(this, n"StartSequnce", 0.75);
				Timer::SetTimer(this, n"CompleteSequence", SequenceTime);
				Timer::SetTimer(this, n"DeactivateBarrier", SequenceTime - 1.5);
			}
			else
			{
				DeactivateBarrier();
			}
		}
	}

	UFUNCTION()
	void StartSequnce()
	{
		// UPlayerAdultDragonComponent::Get(Game::Mio).BlockCapabilities(n"AdultDragon", this);
		// UPlayerAdultDragonComponent::Get(Game::Zoe).BlockCapabilities(n"AdultDragon", this);
		Game::Mio.BlockCapabilities(n"AdultDragon", this); 
		Game::Zoe.BlockCapabilities(n"AdultDragon", this); 

		Game::Zoe.ApplyViewSizeOverride(this, EHazeViewPointSize::Fullscreen, EHazeViewPointBlendSpeed::Normal, EHazeViewPointPriority::Cutscene);
		Game::Zoe.StopAllCameraShakes();
		Game::Zoe.ActivateCamera(Camera, 3.0, this, EHazeCameraPriority::Cutscene);
	}

	UFUNCTION()
	void CompleteSequence()
	{
		// Timer::SetTimer(this, n"ReturnDragonControls", 0.5);
		for (AHazePlayerCharacter Player : Game::Players)
		{
			FTransform Transform = ReturnPoint.GetPositionForPlayer(Player);
			Player.TeleportActor(Transform.Location, Transform.Rotator(), this, bIncludeCamera = true);
		}

		Game::Zoe.ApplyViewSizeOverride(this, EHazeViewPointSize::Normal, EHazeViewPointBlendSpeed::Normal, EHazeViewPointPriority::Cutscene);

		Game::Mio.UnblockCapabilities(n"AdultDragon", this); 
		Game::Zoe.UnblockCapabilities(n"AdultDragon", this); 
		// UPlayerAdultDragonComponent::Get(Game::Mio).AdultDragon.UnblockCapabilities(n"AdultDragon", this);
		// UPlayerAdultDragonComponent::Get(Game::Zoe).AdultDragon.UnblockCapabilities(n"AdultDragon", this);
		Game::Zoe.DeactivateCamera(Camera, 3.5);
		Game::Zoe.DeactivateCamera(Camera, 3.5);
	}

	UFUNCTION()
	void DeactivateBarrier()
	{
		bDeactivated = true;

		for (UStaticMeshComponent Comp : MeshComps)
		{
			Comp.SetHiddenInGame(true);
		}

		BlockingVolume.SetCollisionEnabled(ECollisionEnabled::NoCollision);

		for (AHazePlayerCharacter Player : Game::Players)
		{
			Player.PlayWorldCameraShake(CameraShake, this, ActorLocation, 10000.0, 40000.0);
		}

		OnStormSiegeMagicBarrierDeactivated.Broadcast();
	}
}