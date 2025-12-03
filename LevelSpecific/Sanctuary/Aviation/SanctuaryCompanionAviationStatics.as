namespace SanctuaryCompanionAviationStatics
{

	ESanctuaryArenaSide GetArenaSideForLocation(ASanctuaryBossArenaManager ArenaManager, AHazePlayerCharacter AffectedPlayer, FVector Location)
	{
		if (ArenaManager == nullptr)
			return ESanctuaryArenaSide::Right;
		float RightQuad = 0.0;
		FVector ToLocation = Location - ArenaManager.ActorLocation;
		if (AffectedPlayer.IsZoe())
			RightQuad = ArenaManager.ActorRotation.ForwardVector.DotProduct(ToLocation);
		else
			RightQuad = ArenaManager.ActorRotation.RightVector.DotProduct(ToLocation);
		return RightQuad > 0.0 ? ESanctuaryArenaSide::Right : ESanctuaryArenaSide::Left;
	}

	bool IsOnArenaZoeQuad(ASanctuaryBossArenaManager ArenaManager, FVector Location)
	{
		FVector ToLocation = Location - ArenaManager.ActorLocation;
		ToLocation.Z = 0.0;
		ToLocation = ToLocation.GetSafeNormal();
		float DotXAxis = Math::Abs(ArenaManager.ActorRotation.ForwardVector.DotProduct(ToLocation));
		float DotYAxis = Math::Abs(ArenaManager.ActorRotation.RightVector.DotProduct(ToLocation));
		return DotXAxis > DotYAxis;
	}

}