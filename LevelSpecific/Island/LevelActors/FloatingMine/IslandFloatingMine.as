class AIslandFloatingMine : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent BobRoot;

	UPROPERTY(DefaultComponent, Attach = BobRoot)
	UStaticMeshComponent Mesh;
	default Mesh.CollisionEnabled = ECollisionEnabled::NoCollision;

	UPROPERTY(DefaultComponent, Attach = BobRoot)
	USceneComponent BluePanelAttachLocation;

	UPROPERTY(DefaultComponent, Attach = BobRoot)
	USceneComponent RedPanelAttachLocation;

	UPROPERTY(DefaultComponent, Attach = BobRoot)
	USceneComponent SinglePanelAttachLocation;

	UPROPERTY(DefaultComponent, Attach = BobRoot)
	USphereComponent SphereCollision; 
	default SphereCollision.SphereRadius = 320.0;
	default SphereCollision.SetCollisionProfileName(n"BlockAllDynamic");

	UPROPERTY(DefaultComponent)
	UHazeMovementComponent MoveComp;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 20000.0;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"IslandFloatingMineCompoundCapability");

#if EDITOR
	UPROPERTY(DefaultComponent)
	UIslandFloatingMineDummyComponent DummyComp;
#endif
	UPROPERTY(EditAnywhere, Category = "Setup")
	bool bIsDoubleInteract = true;

	UPROPERTY(EditAnywhere, Category = "Setup", Meta = (EditCondition = !bIsDoubleInteract, EditConditionHides))
	EHazePlayer SinglePanelPlayer;

	UPROPERTY(EditAnywhere, Category = "Setup")
	UNiagaraSystem ExplosionEffect;

	UPROPERTY(EditAnywhere, Category = "Setup")
	UNiagaraSystem TargetLaserEffect;

	UPROPERTY(EditInstanceOnly, Category = "Setup")
	TArray<AActor> PatrolLocations;

	UPROPERTY(EditAnywhere, Category = "Setup")
	UMaterialInstance BluePanelSphereMaterial;

	UPROPERTY(EditAnywhere, Category = "Setup")
	UMaterialInstance RedPanelSphereMaterial;

	UPROPERTY(EditAnywhere, Category = "Setup")
	UMaterialInstance BothPanelSphereMaterial;

	UPROPERTY(EditAnywhere, Category = "Setup")
	TSubclassOf<AIslandOverloadShootablePanel> PanelClass;

	UPROPERTY(EditAnywhere, Category = "Patrol")
	bool bPingPongPatrol = true;

	UPROPERTY(EditAnywhere, Category = "Patrol")
	float PatrolRotationSpeed = 0.75;

	UPROPERTY(EditAnywhere, Category = "Patrol")
	float PatrolMaxSpeed = 300.0;

	UPROPERTY(EditAnywhere, Category = "Patrol")
	float PatrolAcceleration = 5.0;

	UPROPERTY(EditAnywhere, Category = "Distances")
	float DistanceToFindPlayer = 2000.0;

	UPROPERTY(EditAnywhere, Category = "Distances")
	float LosePlayerAdditionalDistance = 500.0;

	UPROPERTY(EditAnywhere, Category = "Distances")
	float ExplosionTriggerRadius = 500.0;

	UPROPERTY(EditAnywhere, Category = "Distances")
	float ExplosionRadius = 1000.0;

	UPROPERTY(EditAnywhere, Category = "Fall")
	float FallDuration = 2.0;

	UPROPERTY(EditAnywhere, Category = "Player Follow")
	float PlayerFollowRotationSpeed = 1.0;

	UPROPERTY(EditAnywhere, Category = "Player Follow")
	float PlayerFollowMaxSpeed = 500.0;

	UPROPERTY(EditAnywhere, Category = "Player Follow")
	float PlayerFollowAcceleration = 5.0;

	UPROPERTY(EditAnywhere, Category = "Bob")
	float BobMagnitude = 100.0;

	UPROPERTY(EditAnywhere, Category = "Bob")
	float BobFrequency = 0.75;

	UPROPERTY(BlueprintHidden, NotVisible)
	AIslandOverloadShootablePanel BluePanel;
	UPROPERTY(BlueprintHidden, NotVisible)
	AIslandOverloadShootablePanel RedPanel;

	bool bIsFalling = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}

	UFUNCTION(CallInEditor, Category = "Setup")
	void UpdateShootablePanels()
	{
		if(RedPanel != nullptr)
			RedPanel.DestroyActor();
		if(BluePanel != nullptr)
			BluePanel.DestroyActor();

		if(bIsDoubleInteract)
		{
			auto BlueSpawningActor = SpawnActor(PanelClass, BluePanelAttachLocation.WorldLocation, BluePanelAttachLocation.WorldRotation, bDeferredSpawn = true);
			BluePanel = Cast<AIslandOverloadShootablePanel>(BlueSpawningActor);
			BluePanel.UsableByPlayer = EHazePlayer::Zoe;
			BluePanel.AttachToComponent(BluePanelAttachLocation, n"NAME_None", EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, EAttachmentRule::KeepWorld, true);
			FinishSpawningActor(BlueSpawningActor);

			auto RedSpawningActor = SpawnActor(PanelClass, RedPanelAttachLocation.WorldLocation, RedPanelAttachLocation.WorldRotation, bDeferredSpawn = true);
			RedPanel = Cast<AIslandOverloadShootablePanel>(RedSpawningActor);
			RedPanel.UsableByPlayer = EHazePlayer::Mio;
			RedPanel.AttachToComponent(RedPanelAttachLocation, n"NAME_None", EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, EAttachmentRule::KeepWorld, true);
			FinishSpawningActor(RedSpawningActor);
		}
		else
		{
			auto SingleSpawningActor = SpawnActor(PanelClass, SinglePanelAttachLocation.WorldLocation, SinglePanelAttachLocation.WorldRotation, bDeferredSpawn = true);
			if(SinglePanelPlayer == EHazePlayer::Mio)
			{
				RedPanel = Cast<AIslandOverloadShootablePanel>(SingleSpawningActor);
				RedPanel.AttachToComponent(SinglePanelAttachLocation, n"NAME_None", EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, EAttachmentRule::KeepWorld, true);
				RedPanel.UsableByPlayer = SinglePanelPlayer;
			}
			else
			{
				BluePanel = Cast<AIslandOverloadShootablePanel>(SingleSpawningActor);
				BluePanel.AttachToComponent(SinglePanelAttachLocation, n"NAME_None", EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, EAttachmentRule::KeepWorld, true);
				BluePanel.UsableByPlayer = SinglePanelPlayer;
			}
			FinishSpawningActor(SingleSpawningActor);
		}
	}

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if(bIsDoubleInteract)
		{
			if(RedPanel != nullptr)
				RedPanel.AttachToComponent(RedPanelAttachLocation, n"NAME_None", EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, EAttachmentRule::KeepWorld, true);
			if(BluePanel != nullptr)
				BluePanel.AttachToComponent(BluePanelAttachLocation, n"NAME_None", EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, EAttachmentRule::KeepWorld, true);
			
			Mesh.SetMaterial(0, BothPanelSphereMaterial);
		}
		else
		{
			if(RedPanel != nullptr)
				RedPanel.AttachToComponent(SinglePanelAttachLocation, n"NAME_None", EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, EAttachmentRule::KeepWorld, true);
			if(BluePanel != nullptr)
				BluePanel.AttachToComponent(SinglePanelAttachLocation, n"NAME_None", EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, EAttachmentRule::KeepWorld, true);
		
			if(SinglePanelPlayer == EHazePlayer::Mio)
			{
				Mesh.SetMaterial(0, RedPanelSphereMaterial);
				if(BluePanel != nullptr
				&& RedPanel == nullptr)
				{
					BluePanel.UsableByPlayer = SinglePanelPlayer;
					RedPanel = BluePanel;
					BluePanel = nullptr;
					#if EDITOR
					RedPanel.RerunConstructionScripts();
					#endif
				}
			}
			else
			{
				Mesh.SetMaterial(0, BluePanelSphereMaterial);
				if(RedPanel != nullptr
				&& BluePanel == nullptr)
				{
					RedPanel.UsableByPlayer = SinglePanelPlayer;
					BluePanel = RedPanel;
					RedPanel = nullptr;
					#if EDITOR
					BluePanel.RerunConstructionScripts();
					#endif
				}
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(bIsFalling)
			return;

		Bob();
	}

	void Bob()
	{
		float BobHeight = Math::Sin(Time::GameTimeSeconds * BobFrequency) * BobMagnitude;
		BobRoot.RelativeLocation = FVector(0, 0, BobHeight);
	}

	void Explode()
	{
		Niagara::SpawnOneShotNiagaraSystemAtLocation(ExplosionEffect, ActorLocation, FRotator::ZeroRotator);
		for(auto Player : Game::Players)
		{
			float DistToPlayerSqrd = Player.ActorCenterLocation.DistSquared(BobRoot.WorldLocation);
			if(DistToPlayerSqrd <= Math::Square(ExplosionRadius))
				Player.KillPlayer();
		}

		AddActorDisable(this);
		if(RedPanel != nullptr)
			RedPanel.AddActorDisable(this);
		if(BluePanel != nullptr)
			BluePanel.AddActorDisable(this);
	}
};

#if EDITOR
class UIslandFloatingMineDummyComponent : UActorComponent {};
class UIslandFloatingMineVisualizerComponent : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UIslandFloatingMineDummyComponent;
	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		auto Comp = Cast<UIslandFloatingMineDummyComponent>(Component);
		if(Comp == nullptr)
			return;

		auto Mine = Cast<AIslandFloatingMine>(Comp.Owner);
		if(Mine == nullptr)
			return;
		
		SetRenderForeground(false);

		FVector Origin = Mine.BobRoot.WorldLocation;
		DrawWireSphere(Origin, Mine.DistanceToFindPlayer, FLinearColor::LucBlue, 5, 12, false);
		DrawWorldString("Player Find Distance", Origin
			+ Mine.ActorUpVector * Mine.DistanceToFindPlayer, FLinearColor::LucBlue, 2, 4000);

		DrawWireSphere(Origin, Mine.DistanceToFindPlayer + Mine.LosePlayerAdditionalDistance, FLinearColor::Green, 5, 12, false);
		DrawWorldString("Lose Player Distance", Origin 
			+ Mine.ActorUpVector * (Mine.DistanceToFindPlayer + Mine.LosePlayerAdditionalDistance), FLinearColor::Green, 2, 4000);

		DrawWireSphere(Origin, Mine.ExplosionTriggerRadius, FLinearColor::White, 5, 12, false);
		DrawWorldString("Explosion Trigger Distance", Origin 
			+ Mine.ActorUpVector * Mine.ExplosionTriggerRadius, FLinearColor::White, 1.5, 2000);

		DrawWireSphere(Origin, Mine.ExplosionRadius, FLinearColor::Red, 5, 12, false);
		DrawWorldString("Explosion Radius", Origin 
			+ Mine.ActorUpVector * Mine.ExplosionRadius, FLinearColor::Red, 1.5, 2000);
		
		FVector BlueAttachLocation = Mine.BluePanelAttachLocation.WorldLocation + Mine.BluePanelAttachLocation.UpVector * 100;
		DrawWireCylinder(BlueAttachLocation, FRotator::MakeFromZ(Mine.BluePanelAttachLocation.ForwardVector), FLinearColor::Blue, 100, 20, 8, 5, false);
		DrawWorldString("Blue Panel Attach", BlueAttachLocation + Mine.BluePanelAttachLocation.RightVector * 50, FLinearColor::Blue, 1.5, 1000.0);
		
		FVector RedAttachLocation = Mine.RedPanelAttachLocation.WorldLocation + Mine.RedPanelAttachLocation.UpVector * 100;
		DrawWireCylinder(RedAttachLocation, FRotator::MakeFromZ(Mine.RedPanelAttachLocation.ForwardVector), FLinearColor::Red, 100, 20, 8, 5, false);
		DrawWorldString("Red Panel Attach", RedAttachLocation + Mine.RedPanelAttachLocation.RightVector * 50, FLinearColor::Red, 1.5, 1000.0);

		FVector SingleAttachLocation = Mine.SinglePanelAttachLocation.WorldLocation + Mine.SinglePanelAttachLocation.UpVector * 100;
		DrawWireCylinder(SingleAttachLocation, FRotator::MakeFromZ(Mine.SinglePanelAttachLocation.ForwardVector), FLinearColor::Purple, 100, 20, 8, 5, false);
		DrawWorldString("Single Panel Attach", SingleAttachLocation + Mine.SinglePanelAttachLocation.RightVector * 50, FLinearColor::Purple, 1.5, 1000.0);

		FVector PatrolOrigin = Mine.BobRoot.WorldLocation;
		FVector PatrolDestination = Mine.PatrolLocations[0].ActorLocation;
		DrawArrow(PatrolOrigin, PatrolDestination, FLinearColor::Green, 50, 10, false);

		for(int i = 0 ; i < Mine.PatrolLocations.Num() - 1 ; i++)
		{
			PatrolOrigin = Mine.PatrolLocations[i].ActorLocation;
			PatrolDestination = Mine.PatrolLocations[i + 1].ActorLocation;
			DrawArrow(PatrolOrigin, PatrolDestination, FLinearColor::Green, 50, 10, false);
		}
		if(!Mine.bPingPongPatrol)
		{
			PatrolOrigin = Mine.PatrolLocations[Mine.PatrolLocations.Num() - 1].ActorLocation;
			PatrolDestination = Mine.PatrolLocations[0].ActorLocation;
			DrawArrow(PatrolOrigin, PatrolDestination, FLinearColor::Green, 50, 10, false);
		}

		Mine.Bob();
	}
}
#endif