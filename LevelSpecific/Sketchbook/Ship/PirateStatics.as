namespace Pirate
{
	APirateShip GetShip()
	{
		return TListedActors<APirateShip>().Single;
	}

	float GetWaterPlaneHeight()
	{
		return 100;
	}

	FVector GetLocationOnWaterPlane(FVector Location)
	{
		return FVector(Location.X, Location.Y, GetWaterPlaneHeight());
	}

	FVector GetRandomLocationAroundPlayerShip(float Radius)
	{
		auto Ship = GetShip();
		const FVector ShipLocation = Pirate::GetLocationOnWaterPlane(Ship.ActorLocation);
		return ShipLocation + (Math::GetRandomPointInCircle_XY() * Radius);
	}

	bool IsActorPartOfShip(AActor Actor)
	{
		auto Ship = GetShip();
		if(Actor == Ship)
			return true;

		if(Actor.AttachmentRootActor == Ship)
			return true;

		return false;
	}
}

UFUNCTION(BlueprintPure)
APirateShip PirateGetShip()
{
	return Pirate::GetShip();
}