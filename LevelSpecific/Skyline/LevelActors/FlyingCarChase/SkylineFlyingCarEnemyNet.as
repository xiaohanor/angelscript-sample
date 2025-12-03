class ASkylineFlyingCarEnemyNet : AHazeActor
{
	default PrimaryActorTick.bStartWithTickEnabled = false;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UBoxComponent ActivationRange;

	UPROPERTY(DefaultComponent)
	USkylineFlyingCarRifleTargetableComponent RifleTargetableComponent1;

	UPROPERTY(DefaultComponent)
	USkylineFlyingCarRifleTargetableComponent RifleTargetableComponent2;

	UPROPERTY(DefaultComponent)
	USkylineFlyingCarRifleTargetableComponent RifleTargetableComponent3;

	UPROPERTY(DefaultComponent)
	USkylineFlyingCarRifleTargetableComponent RifleTargetableComponent4;

	UPROPERTY(DefaultComponent)
	UBasicAIHealthComponent HealthComponent;

	UPROPERTY(DefaultComponent)
	UBasicAIHealthBarComponent HealthBarComponent;
	default HealthBarComponent.SetPlayerVisibility(EHazeSelectPlayer::None);

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UHazeUserWidget> WarningWidgetClass;

	UPROPERTY(NotEditable, BlueprintHidden, Transient)
	UHazeUserWidget WarningWidget1 = nullptr;

	UPROPERTY(NotEditable, BlueprintHidden, Transient)
	UHazeUserWidget WarningWidget2 = nullptr;

	UPROPERTY(NotEditable, BlueprintHidden, Transient)
	UHazeUserWidget WarningWidget3 = nullptr;

	UPROPERTY(NotEditable, BlueprintHidden, Transient)
	UHazeUserWidget WarningWidget4 = nullptr;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		
		HealthComponent.OnTakeDamage.AddUFunction(this, n"OnTakeDamage");

		ActivationRange.OnComponentBeginOverlap.AddUFunction(this, n"OnActivationRangeBeginOverlap");
		ActivationRange.OnComponentEndOverlap.AddUFunction(this, n"OnActivationRangeEndOverlap");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (WarningWidget1 != nullptr)
		{
			// Check if mine is behind player
			FVector MineToPlayer = (WarningWidget1.Player.ActorLocation - ActorLocation);
			if (WarningWidget1.Player.ActorForwardVector.DotProduct(MineToPlayer.GetSafeNormal()) > 0.2)
			{
				if (MineToPlayer.SizeSquared() > Math::Square(1000))
				{
					RemoveWarningWidget();
					SetActorTickEnabled(false);

					HealthBarComponent.SetHealthBarEnabled(false);
				}
			}
		}
	
	}

	void RemoveWarningWidget()
	{
		if(WarningWidget1 != nullptr)
		{
			Game::Mio.RemoveWidget(WarningWidget1);
			Game::Mio.RemoveWidget(WarningWidget2);
			Game::Mio.RemoveWidget(WarningWidget3);
			Game::Mio.RemoveWidget(WarningWidget4);
			WarningWidget1 = nullptr;
		}
	}

	UFUNCTION()
	private void OnActivationRangeEndOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                                         UPrimitiveComponent OtherComp, int OtherBodyIndex)
	{
	}

	UFUNCTION()
	private void OnActivationRangeBeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                                           UPrimitiveComponent OtherComp, int OtherBodyIndex,
	                                           bool bFromSweep, const FHitResult&in SweepResult)
	{
			if (!OtherActor.IsA(ASkylineFlyingCar))
			return;

		SetActorTickEnabled(true);

		// Eman TODO: Remove widget, test having a targetable one instead
		// if (WarningWidget1 == nullptr)
		// {
		// 	HealthBarComponent.SetPlayerVisibility(EHazeSelectPlayer::Mio);
		// 	WarningWidget1 = Game::Mio.AddWidget(WarningWidgetClass);
		// 	WarningWidget1.AttachWidgetToComponent(AutoAimComponent1);

		// 	WarningWidget2 = Game::Mio.AddWidget(WarningWidgetClass);
		// 	WarningWidget2.AttachWidgetToComponent(AutoAimComponent2);

		// 	WarningWidget3 = Game::Mio.AddWidget(WarningWidgetClass);
		// 	WarningWidget3.AttachWidgetToComponent(AutoAimComponent3);

		// 	WarningWidget4 = Game::Mio.AddWidget(WarningWidgetClass);
		// 	WarningWidget4.AttachWidgetToComponent(AutoAimComponent4);
		// }

		ActivateMaterials();
	}

	UFUNCTION(BlueprintEvent)
	void ActivateMaterials()
	{
	}

	UFUNCTION()
	private void OnTakeDamage(AHazeActor ActorTakingDamage, AHazeActor Attacker, float Damage,
	                          EDamageType DamageType)
	{
		if (HasControl())
		{
			if (HealthComponent.IsDead())
				CrumbExplode();
		}
	}

	UFUNCTION(CrumbFunction)
	private void CrumbExplode() { DeactivateGrid(); }
	UFUNCTION(BlueprintEvent)
	private void DeactivateGrid()
	{
	}
};