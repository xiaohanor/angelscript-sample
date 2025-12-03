UCLASS(Abstract)
class ASkylineFlyingCarShootableDoor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent DoorPivot;

	UPROPERTY(DefaultComponent)
	UBoxComponent ActivationRange;

	UPROPERTY(DefaultComponent, Attach=DoorPivot)
	UStaticMeshComponent DoorMesh;

	UPROPERTY(DefaultComponent, Attach = DoorPivot)
	UAutoAimTargetComponent AutoAimComponent;

	UPROPERTY(DefaultComponent)
	UBasicAIHealthComponent HealthComponent;

	UPROPERTY(DefaultComponent)
	UBasicAIHealthBarComponent HealthBarComponent;
	default HealthBarComponent.SetPlayerVisibility(EHazeSelectPlayer::Mio);

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UHazeUserWidget> WarningWidgetClass;

	UPROPERTY(NotEditable, BlueprintHidden, Transient)
	UHazeUserWidget WarningWidget = nullptr;

	UPROPERTY(EditAnywhere)
	FHazeTimeLike Timelike;

	UPROPERTY(EditAnywhere)
	float DoorMovement;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		
		HealthComponent.OnTakeDamage.AddUFunction(this, n"OnTakeDamage");
	
		Timelike.BindUpdate(this, n"HandleAnimationUpdate");

		ActivationRange.OnComponentBeginOverlap.AddUFunction(this, n"OnActivationRangeBeginOverlap");
		ActivationRange.OnComponentEndOverlap.AddUFunction(this, n"OnActivationRangeEndOverlap");
	}

	UFUNCTION()
	private void HandleAnimationUpdate(float CurrentValue)
	{
		DoorPivot.RelativeLocation = FVector(DoorMovement * CurrentValue, 0.0, 0.0);
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

		HealthBarComponent.SetPlayerVisibility(EHazeSelectPlayer::Mio);	
		Timelike.Play();
		WarningWidget = Game::Mio.AddWidget(WarningWidgetClass);
		WarningWidget.AttachWidgetToComponent(AutoAimComponent);
	}

	UFUNCTION()
	private void OnTakeDamage(AHazeActor ActorTakingDamage, AHazeActor Attacker, float Damage,
	                          EDamageType DamageType)
	{
		if (HealthComponent.IsDead())
		{
			RemoveWarningWidget();
			Timelike.Stop();
		}
	}

	void RemoveWarningWidget()
	{
		if(WarningWidget != nullptr)
		{
			Game::Mio.RemoveWidget(WarningWidget);
			WarningWidget = nullptr;
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		
			if (WarningWidget != nullptr)
		{
			// Check if door is behind player
			FVector DoorToPlayer = (WarningWidget.Player.ActorLocation - ActorLocation);
			if (WarningWidget.Player.ActorForwardVector.DotProduct(DoorToPlayer.GetSafeNormal()) > 0.2)
			{
				if (DoorToPlayer.SizeSquared() > Math::Square(1000))
				{
					RemoveWarningWidget();
					SetActorTickEnabled(false);

					HealthBarComponent.SetHealthBarEnabled(false);
				}
			}
		}
	
	}
};
