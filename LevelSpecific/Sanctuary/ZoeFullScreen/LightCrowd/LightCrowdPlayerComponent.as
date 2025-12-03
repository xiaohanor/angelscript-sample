enum ELightCrowdState
{
	Uninitialized,
	CrowdNoMio,
	MioBird
}

class ULightCrowdPlayerComponent : UActorComponent
{
    ULightCrowdDataComponent DataComp;
    TArray<ALightCrowdAgent> Agents;

	private ELightCrowdState State_Internal = ELightCrowdState::Uninitialized;

    void Initialize()
    {
		if(State != ELightCrowdState::Uninitialized)
			return;

        DataComp = ULightCrowdDataComponent::Get(Owner);

        for(int i = 0; i < DataComp.Settings.CrowdCount; i++)
        {
            ALightCrowdAgent Agent = SpawnActor(DataComp.Settings.LightCrowdAgentClass, GetRandomSpawnLocation(true));
        }

		SetLightCrowdState(ELightCrowdState::CrowdNoMio);
    }

	UFUNCTION(BlueprintCallable)
	void SetLightCrowdState(ELightCrowdState InState)
	{
		if(State_Internal != ELightCrowdState::Uninitialized && State_Internal == InState)
			return;

		bool bWasInitialized = State_Internal != ELightCrowdState::Uninitialized;

		State_Internal = InState;
		switch (State_Internal)
		{
			case ELightCrowdState::Uninitialized:
				break;

			case ELightCrowdState::CrowdNoMio:
				Game::Mio.BlockCapabilities(LightCrowdBlockedWhileIn::LightCrowdBlockedWhileInFullScreen, this);
				Game::Zoe.BlockCapabilities(LightCrowdBlockedWhileIn::LightCrowdBlockedWhileInFullScreen, this);

				if(bWasInitialized)
				{
					Game::Mio.UnblockCapabilities(LightCrowdBlockedWhileIn::LightCrowdBlockedWhileInMioBird, this);
					Game::Zoe.UnblockCapabilities(LightCrowdBlockedWhileIn::LightCrowdBlockedWhileInMioBird, this);
				}
				break;

			case ELightCrowdState::MioBird:
				Game::Mio.BlockCapabilities(LightCrowdBlockedWhileIn::LightCrowdBlockedWhileInMioBird, this);
				Game::Zoe.BlockCapabilities(LightCrowdBlockedWhileIn::LightCrowdBlockedWhileInMioBird, this);

				if(bWasInitialized)
				{
					Game::Mio.UnblockCapabilities(LightCrowdBlockedWhileIn::LightCrowdBlockedWhileInFullScreen, this);
					Game::Zoe.UnblockCapabilities(LightCrowdBlockedWhileIn::LightCrowdBlockedWhileInFullScreen, this);
				}
				break;
		}
	}

	ELightCrowdState GetState() const property
	{
		return State_Internal;
	}

    FVector GetRandomSpawnLocation(bool bInitial) 
    {
        const FVector2D RandomPoint2D = Math::GetRandomPointOnCircle();
        FVector RandomPoint = FVector(RandomPoint2D.X, RandomPoint2D.Y, 0.0);
        const float Distance = bInitial ? Math::RandRange(DataComp.Settings.ClosestSpawnDistance, DataComp.Settings.FurthestSpawnDistance) : DataComp.Settings.FurthestSpawnDistance;

        FVector PlayerLocation = Game::Zoe.ActorLocation;
        PlayerLocation.Z = 0.0;

        FVector RandomSpawnLocation = PlayerLocation + (FVector(RandomPoint.X * Distance, RandomPoint.Y * Distance, DataComp.Settings.Height));

        if(bInitial)
            return RandomSpawnLocation;

        FVector PlayerVelocity = Game::Zoe.ActorVelocity;
        PlayerVelocity.Z = 0.0;
        
        if(PlayerVelocity.IsNearlyZero())
            return RandomSpawnLocation;

        FVector PlayerVelocityDir = PlayerVelocity.GetSafeNormal();
        if(RandomPoint.DotProduct(PlayerVelocityDir) < 0.0)
            RandomPoint = -RandomPoint; // Flip to be in front of player

        return PlayerLocation + (FVector(RandomPoint.X * Distance, RandomPoint.Y * Distance, DataComp.Settings.Height));
    }

    ULightCrowdSettings GetSettings() const property
    {
        return DataComp.Settings;
    }
}