UCLASS(Abstract)
class AIslandPortalManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = Root)
	UEditorBillboardComponent Billboard;
	default Billboard.SetSpriteName("S_Player");
#endif

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedActorComp;

	UPROPERTY(DefaultComponent)
	UHazeRequestCapabilityOnPlayerComponent RequestComp;
	default RequestComp.PlayerCapabilityClasses.Add(UIslandPortalPlayerSuckInCapability);

	TArray<AIslandPortal> Portals;
	TPerPlayer<UIslandPortalTravelerComponent> PlayerTravelerComps;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		for(auto Player : Game::Players)
		{
			PlayerTravelerComps[Player] = UIslandPortalTravelerComponent::GetOrCreate(Player);
			PlayerTravelerComps[Player].TravelerType = IslandRedBlueWeapon::IsPlayerRed(Player) ? EIslandTravelerType::Red : EIslandTravelerType::Blue;
		}
	}

	AIslandPortal GetClosestPortal(FVector Point)
	{
		AIslandPortal ClosestPortal;
		float ClosestSqrDist = MAX_flt;
		for(int i = 0; i < Portals.Num(); i++)
		{
			float SqrDist = Point.DistSquared(Portals[i].ActorLocation);
			if(SqrDist < ClosestSqrDist)
			{
				ClosestSqrDist = SqrDist;
				ClosestPortal = Portals[i];
			}
		}

		return ClosestPortal;
	}
}