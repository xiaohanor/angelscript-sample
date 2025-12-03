class UIslandWalkerStompComponent : USceneComponent
{
	float Radius = 170.0;
	FVector PrevLoc;
	FVector Velocity = FVector::ZeroVector;
	uint LastUpdateFrame = 0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		PrevLoc = WorldLocation;
	}

	void UpdateStomp(float DeltaTime)
	{
		uint CurFrame = Time::FrameNumber;
		if (LastUpdateFrame == CurFrame)
			return;
		if (LastUpdateFrame > CurFrame + 1)
			PrevLoc = WorldLocation; // Not updated in a while, counts as motionless
		LastUpdateFrame = CurFrame;

		if (DeltaTime < SMALL_NUMBER)
			return;

		Velocity = (WorldLocation - PrevLoc) / DeltaTime;
		PrevLoc = WorldLocation;	
	}

	void StompPlayers()
	{
		for (AHazePlayerCharacter Player : Game::Players)
		{
			if (IsHitByStomp(Player))
			{
				Player.DealTypedDamage(Owner, 1.0, EDamageEffectType::ObjectLarge, EDeathEffectType::ObjectLarge);
				break;
			}
			if (IsPushedByStomp(Player))
			{
				FKnockdown Knockdown;
				Knockdown.Move = (Velocity * 2.0).GetClampedToSize2D(600.0, 1000.0);
				Knockdown.Move.Z = 100.0;
				Knockdown.Duration = 1.2;
				Player.ApplyKnockdown(Knockdown);
				break;
			}
		}
	}

	bool IsHitByStomp(AHazePlayerCharacter Player) const
	{
		// Are we stomping down hard enough?
		if (Velocity.Z < 400.0)
			return false; 

		// Is player underneath foot?
		FVector PlayerLoc = Player.ActorLocation;
		if (!PlayerLoc.IsWithinDist2D(WorldLocation, Radius))
			return false;
		if (PlayerLoc.Z > WorldLocation.Z)
			return false;
		if (PlayerLoc.Z + 200.0 < WorldLocation.Z)
			return false;

		if (Player.IsPlayerDead())
			return false;

		return true;
	}

	bool IsPushedByStomp(AHazePlayerCharacter Player) const
	{
		// Are we moving fast enough?
		if (Velocity.SizeSquared2D() < Math::Square(400.0))
			return false; 

		// Is player being hit by foot?
		FVector PlayerLoc = Player.ActorLocation;
		if (!PlayerLoc.IsWithinDist2D(WorldLocation, Radius + 20.0))
			return false; // Player is too far away
		if (PlayerLoc.Z > WorldLocation.Z + 200.0)
			return false; // Player is above
		if (PlayerLoc.Z + 200.0 < WorldLocation.Z)
			return false; // Player is below
		if (Velocity.DotProduct(PlayerLoc - WorldLocation) < 0.0)
			return false; // Moving áway from player

		if (Player.IsPlayerDead())
			return false;

		return true;
	}	

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnVisualizeInEditor() const
	{
		Debug::DrawDebugCircle(WorldLocation, Radius, 12, FLinearColor::Red, 6.0);	
	}
#endif
};