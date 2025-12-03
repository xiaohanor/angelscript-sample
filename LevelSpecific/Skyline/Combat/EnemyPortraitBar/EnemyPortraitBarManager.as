class AEnemyPortraitBarManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UBillboardComponent BillboardComp;

	UPROPERTY(EditAnywhere)
	TSubclassOf<UEnemyPortraitBarWidget> PortraitBarClass;
	UEnemyPortraitBarWidget PortraitBarWidget;

	UPROPERTY(EditAnywhere)
	FName PortraitBarTitle = n"Team Portriat Bar";

	UPROPERTY(EditAnywhere)
	TArray<ABasicAICharacter> EnemyCharacters;

	UPROPERTY(EditAnywhere)
	TArray<AHazeActorSingleSpawner> SingleSpawners;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
//		PortraitBarWidget = Widget::AddFullscreenWidget(PortraitBarClass);
		PortraitBarWidget = Cast<UEnemyPortraitBarWidget>(Widget::CreateUserWidget(Game::Mio, PortraitBarClass));

		PortraitBarWidget.Title.Text = FText::FromName(PortraitBarTitle);

		for (auto EnemyCharacter : EnemyCharacters)
		{
			auto PortraitComp = UEnemyPortraitComponent::Get(EnemyCharacter);
			if (PortraitComp != nullptr)
				PortraitBarWidget.AddPortrait(PortraitComp);
		}

		for (auto SingleSpawner : SingleSpawners)
		{
			SingleSpawner.OnPostSpawn.AddUFunction(this, n"HandleSpawn");
/*
			auto PortraitComp = UEnemyPortraitComponent::Get(SingleSpawner);
			PortraitBarWidget.AddPortraitFromSpawner(PortraitComp);
/*
			// Get the portrait of what we will spawn
			if (!SingleSpawner.SpawnPatternSingle.SpawnClass.IsValid())
				continue;

			auto HazeActor = Cast<AActor>(SingleSpawner.SpawnPatternSingle.SpawnClass.Get().DefaultObject);
			if (HazeActor != nullptr)
			{
			//	PrintToScreen("Name: " + HazeActor, 10.0, FLinearColor::Green);

				auto PortraitComp = UEnemyPortraitComponent::Get(HazeActor);
				if (PortraitComp != nullptr)
					PrintToScreen("Name: " + PortraitComp.PortraitName, 10.0, FLinearColor::Green);
				else
					PrintToScreen("No PortraitComp", 10.0, FLinearColor::Green);
			//	PortraitBarWidget.AddPortrait(PortraitComp);
			}
*/
		}
	}

	UFUNCTION()
	private void HandleSpawn(AHazeActor SpawnedActor)
	{
		auto PortraitComp = UEnemyPortraitComponent::Get(SpawnedActor);
		if (PortraitComp != nullptr)
			PortraitBarWidget.AddPortrait(PortraitComp);
	}

	UFUNCTION()
	void ShowPortraitBar()
	{
		if (PortraitBarWidget != nullptr)
			Widget::AddExistingFullscreenWidget(PortraitBarWidget, EHazeWidgetLayer::PlayerHUD);
	}

	UFUNCTION()
	void RemovePortraitBar()
	{
		if (PortraitBarWidget != nullptr)
			Widget::RemoveFullscreenWidget(PortraitBarWidget);
	}
};