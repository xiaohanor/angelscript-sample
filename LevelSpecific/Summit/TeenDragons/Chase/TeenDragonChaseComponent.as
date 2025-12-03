class UTeenDragonChaseComponent : UActorComponent
{
	bool bIsInChase = false;

	ASplineActor ChaseSpline = nullptr;

	private AHazePlayerCharacter Player;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
	}

	UFUNCTION(CrumbFunction, NotBlueprintCallable)
	void CrumbActivateChase(ASplineActor NewChaseSpline)
	{
		ChaseSpline = NewChaseSpline;
		bIsInChase = true;
	}

	UFUNCTION(CrumbFunction, NotBlueprintCallable)
	void CrumbDeactivateChase()
	{
		ChaseSpline = nullptr;
		bIsInChase = false;
	}
};