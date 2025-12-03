class ASanctuaryCentipedeCombatDoor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UFauxPhysicsTranslateComponent TranslateComp;

	UPROPERTY(DefaultComponent, Attach = TranslateComp)
	UFauxPhysicsForceComponent ForceComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ForceComp.AddDisabler(this);
	}

	UFUNCTION()
	void Open()
	{
		ForceComp.RemoveDisabler(this);
	}

	UFUNCTION()
	void StartOpened()
	{
		TranslateComp.SetRelativeLocation(TranslateComp.RelativeLocation + FVector::UpVector * TranslateComp.MinX);
	}
};