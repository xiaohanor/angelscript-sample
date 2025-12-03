class ASkylineEnforcerBoundsVolume : AVolume
{
	UPROPERTY(EditAnywhere)
	TArray<AScenepointActor> LandingScenepoints;

	private int Index = 0;

	AScenepointActor GetNextLandingScenepoint()
	{
		if(LandingScenepoints.Num() == 0)
			return nullptr;

		AScenepointActor Point = LandingScenepoints[Index];
		if(LandingScenepoints.Num() > Index + 1)
			Index++;
		else
			Index = 0;
		return Point;
	}
}