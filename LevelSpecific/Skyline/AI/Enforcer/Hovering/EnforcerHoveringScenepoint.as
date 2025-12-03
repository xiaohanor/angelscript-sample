class AEnforcerHoverScenepoint : AScenepointActorBase
{
	UPROPERTY(DefaultComponent)
	UArrowComponent ArrowComponent;
	default ArrowComponent.SetRelativeLocation(FVector(20.0, 0.0, 0.0));
	default ArrowComponent.ArrowSize = 2.0;
	default ArrowComponent.ArrowColor = FLinearColor::LucBlue;

	UPROPERTY(DefaultComponent, ShowOnActor, BlueprintReadOnly)
	private UScenepointComponent ScenepointComponent;
	default ScenepointComponent.Radius = 500.0;
	default ScenepointComponent.CooldownDuration = 5.0;

	UPROPERTY(DefaultComponent, ShowOnActor, BlueprintReadOnly)
	UScenepointTeamComponent TeamComponent;

	UScenepointComponent GetScenepoint() override
	{
		return ScenepointComponent;
	};

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		UEnforcerHoverScenepointManager ScenepointContainer = Game::GetSingleton(UEnforcerHoverScenepointManager);
		ScenepointContainer.Register(TeamComponent.Team, ScenepointComponent);
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		UEnforcerHoverScenepointManager ScenepointContainer = Game::GetSingleton(UEnforcerHoverScenepointManager);
		ScenepointContainer.Unregister(TeamComponent.Team, ScenepointComponent);
	}
}

