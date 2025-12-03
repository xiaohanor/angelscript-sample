UCLASS(Abstract)
class APrisonDrones_LifeRing : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UFauxPhysicsTranslateComponent FauxTranslateComp;

	UPROPERTY(DefaultComponent, Attach = FauxTranslateComp)
	UFauxPhysicsFreeRotateComponent FauxRotateComp;

	UPROPERTY(DefaultComponent)
	UMovementImpactCallbackComponent ImpactComp;	

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ImpactComp.OnAnyImpactByPlayer.AddUFunction(this, n"Impact");
	}

	UFUNCTION()
	private void Impact(AHazePlayerCharacter Player)
	{
		
		FVector Impulse = GetActorLocation() - Player.GetActorLocation();
		Impulse.Normalize();
		Impulse *= 500;

		if(Player.IsMio())
			FauxTranslateComp.ApplyImpulse(Player.GetActorLocation(),Impulse);
			FauxRotateComp.ApplyImpulse(Player.GetActorLocation(),Impulse);
	}
};
