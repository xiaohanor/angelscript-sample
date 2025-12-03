class USkylineHideForPlayerComponent : UActorComponent
{
	UPROPERTY(EditAnywhere)
	EHazeSelectPlayer HideForPlayer;

	//If true hide stuff with tag "Hideable"
	UPROPERTY(EditAnywhere)
	bool bHideSpecific;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TArray<UPrimitiveComponent> Primitives;

		Owner.GetComponentsByClass(Primitives);
		for (auto Primitive : Primitives)
		{
			for (auto Player : Game::GetPlayersSelectedBy(HideForPlayer))
			{
				if(bHideSpecific)
				{
					if(Primitive.HasTag(n"Hideable"))
						Primitive.SetRenderedForPlayer(Player, false);
				}else
					Primitive.SetRenderedForPlayer(Player, false);
				
				
			}
								
		}
	}
};