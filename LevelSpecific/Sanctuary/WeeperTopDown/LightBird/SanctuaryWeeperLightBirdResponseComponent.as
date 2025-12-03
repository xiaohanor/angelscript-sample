event void FSanctuaryWeeperLightBirdIlluminateSignature(ASanctuaryWeeperLightBird LightBird);

class USanctuaryWeeperLightBirdResponseComponent : UActorComponent
{
	default PrimaryComponentTick.bStartWithTickEnabled = false;

	UPROPERTY(Category = "Response")
	FSanctuaryWeeperLightBirdIlluminateSignature OnIlluminated;
	UPROPERTY(Category = "Response")
	FSanctuaryWeeperLightBirdIlluminateSignature OnUnilluminated;
	
	TArray<ASanctuaryWeeperLightBird> Illuminators;

	UFUNCTION(NotBlueprintCallable)
	void Illuminate(ASanctuaryWeeperLightBird LightBird)
	{
		if (LightBird != nullptr)
			Illuminators.AddUnique(LightBird);
		
		OnIlluminated.Broadcast(LightBird);
	}

	UFUNCTION(NotBlueprintCallable)
	void Unilluminate(ASanctuaryWeeperLightBird LightBird)
	{
		if (LightBird != nullptr)
			Illuminators.Remove(LightBird);
		
		OnUnilluminated.Broadcast(LightBird);
	}

	UFUNCTION(BlueprintPure)
	bool IsIlluminated() const
	{
		return Illuminators.Num() != 0;
	}
}