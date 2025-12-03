class ATundraBossAttackRestrictionZone : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USphereComponent SphereComp;
	default SphereComp.CollisionEnabled = ECollisionEnabled::NoCollision;
	default SphereComp.GenerateOverlapEvents = false;

	bool PlayerCurrentlyInRestrictedZone(AHazePlayerCharacter Player, float Buffer)
	{
		if(GetHorizontalDistanceTo(Player) < SphereComp.SphereRadius + Buffer)
			return true;
		else
			return false;
	}

	// Returns a Zero Vector if the player isn't inside a restricted zone
	FVector GetSpawnLocationWithRestriction(AHazePlayerCharacter Player, float Buffer)
	{
		FVector NewLoc;

		if(GetHorizontalDistanceTo(Player) < SphereComp.SphereRadius + Buffer)
		{
			FVector PlayerLoc = Player.ActorLocation;
			FVector Dir = (PlayerLoc - SphereComp.WorldLocation).GetSafeNormal2D();
			float Dist = GetHorizontalDistanceTo(Player);
			NewLoc = PlayerLoc + Dir * (SphereComp.SphereRadius - Dist + Buffer);
			
			return NewLoc;
		}
		else
		{
			return FVector::ZeroVector;
		}
	}
};