class USanctuaryWeeperLightBirdUserComponent : UActorComponent
{
	access WeeperLightBirdInternal = private, USanctuaryWeeperLightBirdTransformCapability;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Light Bird")
	TSubclassOf<ASanctuaryWeeperLightBird> LightBirdClass;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Light Bird")
	bool bStartTransformed = true;

	AHazePlayerCharacter Player;
	ASanctuaryWeeperLightBird LightBird;
	TArray<FInstigator> TransformInstigators;
		
	access: WeeperLightBirdInternal
	bool bIsPlayerTransformed;

	const FName StartTransformedName = n"StartTransformed";

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
	}

	UFUNCTION(BlueprintCallable)
	void ClearStartTransform()
	{
		RevertTransform(StartTransformedName);
	}

	UFUNCTION(BlueprintCallable)
	void Transform(FInstigator Instigator)
	{
		TransformInstigators.AddUnique(Instigator);
	}
	
	UFUNCTION(BlueprintCallable)
	void RevertTransform(FInstigator Instigator)
	{
		TransformInstigators.Remove(Instigator);
	}

	UFUNCTION(BlueprintPure)
	bool ShouldTransform() const
	{
		return (TransformInstigators.Num() != 0);
	}
	
	UFUNCTION(BlueprintPure)
	bool IsTransformed() const
	{
		return bIsPlayerTransformed;
	}
}