namespace SketchbookBoss
{
	event void OnBossFightStartedEvent();
	event void OnBossSelectedEvent(ESketchbookBossChoice BossType);
	event void OnBossFightChoicesPresented();
	event void OnBossPhaseSlainEvent(ESketchbookBossChoice BossType);

	UFUNCTION(BlueprintPure)
	ASketchbookBossFightManager GetSketchbookBossFightManager()
	{
		return TListedActors<ASketchbookBossFightManager>().Single;
	}
}

UCLASS(Abstract)
class ASketchbookBossFightManager : AHazeActor
{
	UPROPERTY(BlueprintReadOnly)
	SketchbookBoss::OnBossFightStartedEvent OnBossFightStarted;

	UPROPERTY(BlueprintReadOnly)
	SketchbookBoss::OnBossPhaseSlainEvent OnBossPhaseSlain;

	UPROPERTY(BlueprintReadOnly)
	SketchbookBoss::OnBossFightChoicesPresented OnChoicesPresented;

	UPROPERTY(BlueprintReadOnly)
	SketchbookBoss::OnBossSelectedEvent OnBossSelected;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComp;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"SketchbookBossArenaMoveCameraCapability");

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UBossHealthBarWidget> HealthBarWidgetClass;
	UBossHealthBarWidget HealthBar;

	UPROPERTY(EditInstanceOnly)
	AHazeCameraActor BossCamera;

	bool bUpdateCamera = false;

	FVector CameraDefaultLocation;
	FVector TargetCameraLocation;

	ASketchbookBoss CurrentBoss;

	float CurrentHealth = SketchbookBoss::Settings::MaxHealth;

	TArray<ESketchbookBossChoice> BossesSlain;
	float ArenaFloorZ;

	TSubclassOf<ASketchbookBoss> SelectedBoss;
	ASketchbookSentence SelectedBossText;

	int ChoicesDrawn = 0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ArenaFloorZ = ActorLocation.Z - 350;
		
		if(BossCamera != nullptr)
			TargetCameraLocation = CameraDefaultLocation = BossCamera.ActorLocation;

		HealthBar = Game::GetZoe().AddWidget(HealthBarWidgetClass);
		HealthBar.RecentDamageLerpDelay = 0;
		HealthBar.RecentDamageLerpSpeed = 10;
		SetHealthbarVisibility(false);

		SketchbookBoss::UnkillableBoss.MakeVisible();
	}

	void SetNewCameraTargetLocation(FVector NewLocation)
	{
		TargetCameraLocation = NewLocation;
		bUpdateCamera = true;
	}

	void ChoiceFinishedDrawing()
	{
		ChoicesDrawn++;
		if(ChoicesDrawn == 3 - BossesSlain.Num())
		{
			OnChoicesPresented.Broadcast();
			ChoicesDrawn = 0;
		}
	}

	UFUNCTION(BlueprintCallable, DevFunction)
	void StartBossChoice()
	{
		SetHealthbarVisibility(true);
		CurrentBoss = SpawnActor(SelectedBoss, ActorLocation, ActorRotation);
		CurrentBoss.MakeNetworked(this, BossesSlain.Num());
		CurrentBoss.DrawableComp.StartBeingDrawn();
		CurrentBoss.BossNumber = BossesSlain.Num();
		CurrentBoss.BossText = SelectedBossText;
		HealthBar.InitBossHealthBar(CurrentBoss.HealthBarDesc, CurrentHealth);
	}

	UFUNCTION()
	void SelectBossChoice(TSubclassOf<ASketchbookBoss> BossClass, ASketchbookSentence BossText)
	{
		SelectedBoss = BossClass;
		SelectedBossText = BossText;
		OnBossSelected.Broadcast(BossClass.DefaultObject.BossType);
	}
	
	void SetHealthbarVisibility(bool bVisible)
	{
		if(bVisible)
			HealthBar.SetVisibility(ESlateVisibility::Visible);
		else
			HealthBar.SetVisibility(ESlateVisibility::Hidden);
	}

	UFUNCTION(DevFunction)
	void EndPhase()
	{
		if(BossesSlain.Contains(CurrentBoss.BossType))
			return;

		if(BossesSlain.IsEmpty())
		{
			RemoveBoss();
		}
		else
		{
			USketchbookBossEffectEventHandler::Trigger_OnBossKilled(CurrentBoss);
			CurrentBoss.bIsKilled = true;
		}
	}

	UFUNCTION()
	void RemoveBoss()
	{
		USketchbookBossEffectEventHandler::Trigger_OnBossPhaseOneRemoved(CurrentBoss);
		OnBossPhaseSlain.Broadcast(CurrentBoss.BossType);
		BossesSlain.Add(CurrentBoss.BossType);
		CurrentBoss.DestroyActor();
		CurrentBoss = nullptr;
		CurrentHealth = 50;
		HealthBar.SnapHealthTo(CurrentHealth);
		SetHealthbarVisibility(false);
	}

	UFUNCTION(CrumbFunction)
	void CrumbTakeDamage()
	{
		if(SketchbookBoss::UnkillableBoss.IsEnabled())
			return;

		if(CurrentBoss == nullptr)
			return;

		if(CurrentBoss.bIsKilled)
			return;

		CurrentHealth -= SketchbookBoss::Settings::DamagePerArrow;
		HealthBar.SetHealthAsDamage(CurrentHealth);
		const int BossChoices = 2;

		USketchbookBossEffectEventHandler::Trigger_TakeDamageEvent(this);
		const float HealthThreshold = SketchbookBoss::Settings::MaxHealth - ((BossesSlain.Num()+1) * (SketchbookBoss::Settings::MaxHealth / BossChoices));

		if(CurrentHealth <= HealthThreshold)
			EndPhase();
		else
		{
			if (CurrentBoss != nullptr)
				CurrentBoss.Mesh.SetAnimTrigger(n"TakeDamage");		
		}
	}
}