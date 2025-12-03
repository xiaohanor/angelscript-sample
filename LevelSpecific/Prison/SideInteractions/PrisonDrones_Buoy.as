UCLASS(Abstract)
class APrisonDrones_Buoy : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UFauxPhysicsConeRotateComponent FauxRotateComp;

	UPROPERTY(DefaultComponent, Attach = FauxRotateComp)
	UStaticMeshComponent MeshComp;

	UPROPERTY(DefaultComponent, Attach = FauxRotateComp)
	UPointLightComponent Light;

	UPROPERTY(DefaultComponent)
	UMovementImpactCallbackComponent ImpactComp;	

	default Light.bVisible = false;
	float TimeSinceLastRotation;
	float RotationTimer = 0.5;


	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ImpactComp.OnAnyImpactByPlayer.AddUFunction(this, n"Impact");
	}

	UFUNCTION()
	private void Impact(AHazePlayerCharacter Player)
	{	
		if(Time::GetGameTimeSince(TimeSinceLastRotation) > RotationTimer)
		{
			if(!Light.bVisible)
				Light.SetVisibility(true);
			else
				Light.SetVisibility(false);

			FVector Impulse = Player.GetActorLocation() - GetActorLocation();
			Impulse.Normalize();
			Impulse *= 5000;

			FauxRotateComp.ApplyImpulse
			(Player.GetActorLocation(), Impulse);
			TimeSinceLastRotation = Time::GameTimeSeconds;
		}
	}
};