UCLASS(Abstract)
class APrisonDroneFakeLadder : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UFauxPhysicsAxisRotateComponent AxisRotateComp;

	UPROPERTY(DefaultComponent)
	UMovementImpactCallbackComponent ImpactComp;

	float hitTimer;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ImpactComp.OnAnyImpactByPlayer.AddUFunction(this,n"OnPlayerImpact");
	}

	UFUNCTION()
	private void OnPlayerImpact(AHazePlayerCharacter Player)
	{
		FVector Force = Player.ActorForwardVector;
		Force *= 50;


		if(Time::GameTimeSeconds > hitTimer)
		{
			AxisRotateComp.ApplyImpulse(Player.GetActorLocation(), Force);
			hitTimer = Time::GameTimeSeconds + 0.5;
		}


	}
};
