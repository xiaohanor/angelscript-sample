class UTundraRiverBoulderFocusGetter : UHazeCameraWeightedFocusTargetCustomGetter
{
	USceneComponent GetFocusComponent() const override
	{
		return nullptr;
	}

	FVector GetFocusLocation() const override
	{
		float SqrDistance = TundraRiverBoulder::GetTundraRiverBoulder().GetActorLocation().DistSquared(Game::GetMio().GetActorLocation());
		if(TundraRiverBoulder::GetTundraRiverBoulder().GetActorLocation().DistSquared(Game::GetZoe().GetActorLocation()) > SqrDistance)
		{
			return Game::GetZoe().GetActorLocation();
		}
		else
		{
			return Game::GetMio().GetActorLocation();
		}
	}
};