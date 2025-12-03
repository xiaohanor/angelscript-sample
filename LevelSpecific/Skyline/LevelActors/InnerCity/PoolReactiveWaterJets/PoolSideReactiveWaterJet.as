class APoolSideReactiveWaterJet : AHazeActor
{
	default PrimaryActorTick.bStartWithTickEnabled = false;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent WaterJetFXComponent;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent OverlapTrigger;
	default OverlapTrigger.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Ignore);
	default OverlapTrigger.SetCollisionResponseToChannel(ECollisionChannel::PlayerCharacter, ECollisionResponse::ECR_Overlap);
	default OverlapTrigger.RelativeLocation = FVector(150, 0, OverlapTrigger.BoxExtent.Z);

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent MeshComp;

	UPROPERTY(EditInstanceOnly, Category = "Settings")
	ESkylineWaterJetType JetType;

	UPROPERTY(EditInstanceOnly, Category = "Settings", meta = (EditCondition = "JetType == ESkylineWaterJetType::Duration", EditConditionHides))
	float Duration = 3;

	float TimerCountdown = 0;

	int OverlapCount = 0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		OverlapTrigger.OnComponentBeginOverlap.AddUFunction(this, n"OnPlayerOverlap");
		OverlapTrigger.OnComponentEndOverlap.AddUFunction(this, n"OnPlayerEndOverlap");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(JetType == ESkylineWaterJetType::Duration)
		{
			if(TimerCountdown > 0)
			{
				TimerCountdown -= DeltaSeconds;
			}
			else
			{
				TimerCountdown = 0;
				WaterJetFXComponent.Deactivate();
				SetActorTickEnabled(false);

				FPoolSideJetEventParams Params;
				Params.JetType = JetType;
				UPoolSideWaterJetEventHandler::Trigger_OnJetDeactivated(this, Params);
			}
		}
	}

	UFUNCTION()
	private void OnPlayerOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                             UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep,
	                             const FHitResult&in SweepResult)
	{
		if (JetType == ESkylineWaterJetType::Duration)
		{
			TimerCountdown = Duration;
			WaterJetFXComponent.Activate(true);
			SetActorTickEnabled(true);
		}
		else if (JetType == ESkylineWaterJetType::WhileOverlapping)
		{
			OverlapCount++;

			WaterJetFXComponent.Activate(true);
		}

		// Assumes the player will be hit.
		auto Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player != nullptr)
			OnPlayerHitByWater(Player);

		FPoolSideJetEventParams Params;
		Params.JetType = JetType;
		UPoolSideWaterJetEventHandler::Trigger_OnJetActivated(this, Params);
	}

	// VO EVENT
	UFUNCTION(BlueprintEvent)
	void OnPlayerHitByWater(AHazePlayerCharacter Player) {}

	UFUNCTION()
	private void OnPlayerEndOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                                UPrimitiveComponent OtherComp, int OtherBodyIndex)
	{
		if (JetType == ESkylineWaterJetType::WhileOverlapping)
		{
			OverlapCount--;

			if(OverlapCount <= 0)
			{
				WaterJetFXComponent.Deactivate();

				FPoolSideJetEventParams Params;
				Params.JetType = JetType;
				UPoolSideWaterJetEventHandler::Trigger_OnJetDeactivated(this, Params);
			}
		}
	}
};

enum ESkylineWaterJetType
{
	Duration,
	WhileOverlapping
}