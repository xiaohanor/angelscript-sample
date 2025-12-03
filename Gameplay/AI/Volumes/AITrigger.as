event void FAITriggerOverlap(AHazeActor Actor);

class AAITrigger : AHazeActor
{
	default SetActorHiddenInGame(true);
	default bRunConstructionScriptOnDrag = true;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY()
	FAITriggerOverlap OnTriggerEnter;

	UPROPERTY()
	FAITriggerOverlap OnTriggerExit;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UEditorBillboardComponent Billboard;
    default Billboard.SpriteName = "S_TriggerBox";
	default Billboard.RelativeScale3D = FVector(2.0);
	default Billboard.RelativeLocation = FVector(0.0, 0.0, 100.0);
#endif

	UPROPERTY(DefaultComponent, ShowOnActor, BlueprintReadOnly)
	UTeamLazyTriggerShapeComponent TriggerComp;
	default TriggerComp.TeamName = AITeams::Default;
	default TriggerComp.Shape.Type = EHazeShapeType::Box;
	default TriggerComp.VisualizeColor = FLinearColor::Green;
	default TriggerComp.bTriggerLocally = false;

	// Team for grouping AI Triggers
	UPROPERTY(BlueprintReadOnly, EditAnywhere, Category = "Trigger Team")
	FName TriggerTeamName;
	default TriggerTeamName = n"AITriggerTeam";

	UPROPERTY(Category = "Precision")
	float FarTickInterval = 0.2;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TriggerComp.OnEnter.AddUFunction(this, n"OnEnter");
		TriggerComp.OnExit.AddUFunction(this, n"OnExit");
		SetActorTickInterval(FarTickInterval);
		JoinTeam(TriggerTeamName);
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		LeaveTeam(TriggerTeamName);
	}

	UFUNCTION()
	private void OnEnter(AHazeActor Actor)
	{
		// TriggerComp is crumbed
		OnTriggerEnter.Broadcast(Actor);
	}

	UFUNCTION()
	private void OnExit(AHazeActor Actor)
	{
		// TriggerComp is crumbed
		OnTriggerExit.Broadcast(Actor);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		TriggerComp.Update(DeltaTime);
		if (TriggerComp.HasMembersNearby())
			SetActorTickInterval(0.0);
		else
			SetActorTickInterval(FarTickInterval);
	}

}
