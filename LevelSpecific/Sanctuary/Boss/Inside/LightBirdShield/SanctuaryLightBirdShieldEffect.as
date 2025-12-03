class ASanctuaryLightBirdShieldEffect : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	/*
		auto OwningPlayer = Cast<AHazePlayerCharacter>(AttachParentActor);

		TArray<UPrimitiveComponent> Primitives;
		GetComponentsByClass(Primitives);
		for (auto Primitive : Primitives)
			Primitive.SetRenderedForPlayer(OwningPlayer, false);
	*/
	}
};