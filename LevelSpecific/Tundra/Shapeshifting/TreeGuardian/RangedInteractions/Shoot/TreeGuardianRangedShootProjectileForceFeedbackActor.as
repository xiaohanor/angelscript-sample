class ATreeGuardianRangedShootProjectileForceFeedbackActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UBillboardComponent Root;

	default PrimaryActorTick.bStartWithTickEnabled = false;

	UFUNCTION()
	void EnableSphereProjectileForceFeedback(bool bEnabled)
	{
		SetActorTickEnabled(bEnabled);
	}

	//Doing stuff in BP so that variables can be exposed to cinematics
};