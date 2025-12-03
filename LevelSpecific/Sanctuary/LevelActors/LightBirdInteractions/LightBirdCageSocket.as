class ALightBirdCageSocket : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	ULightBirdResponseComponent LightBirdResponseComponent;

	UPROPERTY(EditAnywhere)
	float SocketMagnetRadius = 500.0;

	AActor SocketedActor;

	ULightBirdResponseComponent SocketdedLightBirdResponseComponent;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
//		PrintToScreen("SocketedActor: " + SocketedActor, 0.0, FLinearColor::Green);
/*
		for (auto SocketableActor : SocketableActors)
		{
			float Distance = GetDistanceTo(SocketableActor);
			if (Distance <= SocketMagnetRadius)
			{
				if (SocketedActor != SocketableActor)
					Socket(SocketableActor);
			}
			else
			{
				if (SocketedActor == SocketableActor)
					Unsocket();
			}
		}
*/
	}

	void Socket(AActor Actor)
	{
		SocketdedLightBirdResponseComponent = ULightBirdResponseComponent::Get(Actor);	

		if (SocketdedLightBirdResponseComponent == nullptr)
			return;

		if (SocketdedLightBirdResponseComponent.IsIlluminated())
			LightBirdResponseComponent.OnIlluminated.Broadcast();

		SocketdedLightBirdResponseComponent.OnIlluminated.AddUFunction(this, n"OnIlluminated");
		SocketdedLightBirdResponseComponent.OnUnilluminated.AddUFunction(this, n"OnUnilluminated");
	
		SocketedActor = Actor;
	}

	void Unsocket()
	{
		if (SocketedActor == nullptr)
			return;

		if (SocketdedLightBirdResponseComponent.IsIlluminated())
			LightBirdResponseComponent.OnUnilluminated.Broadcast();
	
		SocketdedLightBirdResponseComponent.OnIlluminated.Unbind(this, n"OnIlluminated");
		SocketdedLightBirdResponseComponent.OnUnilluminated.Unbind(this, n"OnUnilluminated");
	
		SocketedActor = nullptr;
	}

	UFUNCTION()
	private void OnIlluminated()
	{
		LightBirdResponseComponent.OnIlluminated.Broadcast();
	}

	UFUNCTION()
	private void OnUnilluminated()
	{
		LightBirdResponseComponent.OnUnilluminated.Broadcast();
	}
}