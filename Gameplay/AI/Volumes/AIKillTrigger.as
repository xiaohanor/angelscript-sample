struct FActorKillDelay
{
	FActorKillDelay(AHazeActor _Actor)
	{
		Actor = _Actor;
		Timestamp = Time::GameTimeSeconds;
	}

	AHazeActor Actor;
	
	float Timestamp;
}


class AAIKillTrigger : AHazeActor
{
	default SetActorHiddenInGame(true);
	default bRunConstructionScriptOnDrag = true;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UEditorBillboardComponent Billboard;
    default Billboard.SpriteName = "S_TriggerBox";
	default Billboard.RelativeScale3D = FVector(2.0);
	default Billboard.RelativeLocation = FVector(0.0, 0.0, 100.0);
#endif

	UPROPERTY(DefaultComponent, ShowOnActor)
	UTeamLazyTriggerShapeComponent TriggerComp;
	default TriggerComp.TeamName = AITeams::Default;
	default TriggerComp.Shape.Type = EHazeShapeType::Box;
	default TriggerComp.VisualizeColor = FLinearColor::Green;
	default TriggerComp.VisualizeNotSelectedColor = FLinearColor::Red;

	UPROPERTY(AdvancedDisplay, Category = "Precision")
	float FarTickInterval = 0.2;

	// AI entering the trigger will be killed after this time delay.
	UPROPERTY(EditAnywhere, Category = "Settings")
	float KillDelay = 0.0;

	private TArray<FActorKillDelay> ActorsPendingKill;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TriggerComp.OnEnter.AddUFunction(this, n"OnEnter");
		SetActorTickInterval(FarTickInterval);
	}

	UFUNCTION()
	private void OnEnter(AHazeActor Actor)
	{
		UBasicAIHealthComponent HealthComp = UBasicAIHealthComponent::Get(Actor);
		if (HealthComp == nullptr)
			return;
		if (KillDelay > 0) // Kill later
			ActorsPendingKill.Add(FActorKillDelay(Actor));
		else // Kill now
			KillActor(Actor);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		TriggerComp.Update(DeltaTime);
		if (TriggerComp.HasMembersNearby() || ActorsPendingKill.Num() > 0)
			SetActorTickInterval(0.0);
		else
			SetActorTickInterval(FarTickInterval);

		// If we have a kill delay time set, check the pending list:
		for (int I = ActorsPendingKill.Num() - 1; I >= 0; I--)
		{
			if (ActorsPendingKill[I].Timestamp + KillDelay < Time::GameTimeSeconds)
			{
				KillActor(ActorsPendingKill[I].Actor);
				ActorsPendingKill.RemoveAtSwap(I);
			}
		}			
	}

	private void KillActor(AHazeActor Actor)
	{
		UBasicAIHealthComponent HealthComp = UBasicAIHealthComponent::Get(Actor);
		if (HealthComp == nullptr)
			return;
		if (HealthComp.IsDead())
			return;
		HealthComp.TakeDamage(HealthComp.MaxHealth, EDamageType::Default, this);
	}
}
