class ASkylineBikeTowerPrefab : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;
	default Root.Mobility = EComponentMobility::Static;

	UPROPERTY(EditAnywhere)
	bool bSlopesAsFlatGround = false;

	UPROPERTY()
	TArray<UPrimitiveComponent> Primitives;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		for (auto Primitive : Primitives)
		{
			if (!IsValid(Primitive))
				continue;

			if (bSlopesAsFlatGround)
				Primitive.AddTag(ComponentTags::GravityBikeFlatGround);
			else
				Primitive.RemoveTag(ComponentTags::GravityBikeFlatGround);
		}
	}
};