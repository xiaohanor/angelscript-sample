event void FOnFireWorksImpact(FMoonMarketFireworkImpactData Data);

struct FMoonMarketFireworkImpactData
{
	AFireworksRocket Rocket;
	FVector ImpactPoint;
	AHazePlayerCharacter InstigatingPlayer;
}

class UFireworksResponseComponent : UActorComponent
{
	UPROPERTY()
	FOnFireWorksImpact OnFireWorksImpact;

	void ActivateFireworksResponse(AFireworksRocket Rocket, FVector ImpactPoint, AHazePlayerCharacter InstigatingPlayer)
	{
		FMoonMarketFireworkImpactData Data;
		Data.Rocket = Rocket;
		Data.ImpactPoint = ImpactPoint;
		Data.InstigatingPlayer = InstigatingPlayer;
		OnFireWorksImpact.Broadcast(Data);
	}
};