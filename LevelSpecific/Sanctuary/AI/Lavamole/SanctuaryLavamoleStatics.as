struct FSanctuaryLavamoleSwitchHoleData
{
	ASanctuaryLavamoleDigPoint PreviousHole = nullptr;
	ASanctuaryLavamoleDigPoint NewHole = nullptr;
	FVector DigLocation;
}

namespace SanctuaryLavamoleStatics
{
	void FindFreeHole(const AAISanctuaryLavamole Mole, ASanctuaryLavamoleDigPoint& OutNewHole, FVector& OutDigLocation)
	{
		FVector NewDigLocation;
		ASanctuaryLavamoleDigPoint NewHole = nullptr;
		auto Team = HazeTeam::GetTeam(SanctuaryLavamoleTags::DigPointTeam);
		if(Team != nullptr)
		{
			TArray<AHazeActor> Members = Team.GetMembers();
			TArray<ASanctuaryLavamoleDigPoint> DigPoints;
			TPerPlayer<ASanctuaryLavamoleDigPoint> ClosestDigPoints;
			ASanctuaryLavamoleDigPoint SafeDigPoint = nullptr;
			for (int iMember = 0; iMember < Members.Num(); ++iMember)
			{
				ASanctuaryLavamoleDigPoint DigPoint = Cast<ASanctuaryLavamoleDigPoint>(Members[iMember]);
				if (DigPoint != nullptr)
				{
					DigPoints.Add(DigPoint);
					if (DigPoint.bSafeDigPoint)
						SafeDigPoint = DigPoint;

					for (AHazePlayerCharacter Player : Game::Players)
					{
						if (ClosestDigPoints[Player] == nullptr)
							ClosestDigPoints[Player] = DigPoint;
						else if (ClosestDigPoints[Player].ActorLocation.Distance(Player.ActorLocation) > DigPoint.ActorLocation.Distance(Player.ActorLocation))
							ClosestDigPoints[Player] = DigPoint;
					}
				}
			}

			int RandomTries = 0;
			bool bFound = false;

			if (Mole.bIsAggressive && SafeDigPoint != nullptr && SafeDigPoint.Occupant == nullptr)
			{
				NewHole = SafeDigPoint;
				bFound = true;
				NewDigLocation = SafeDigPoint.ActorLocation;
			}
			else
			{
				while (RandomTries < 16)
				{
					RandomTries++;
					ASanctuaryLavamoleDigPoint DigPoint = DigPoints[Math::RandRange(0, DigPoints.Num()-1)];
					if (DigPoint != nullptr)
					{
						if (DigPoint.HasOccupant())
							continue;
						if (ClosestDigPoints[Game::Mio] == DigPoint || ClosestDigPoints[Game::Zoe] == DigPoint)
							continue;
						NewHole = DigPoint;
					}
					bFound = true;
					NewDigLocation = DigPoint.ActorLocation;
					break;
				}
			}

			if (!bFound)
			{
				for (auto& Member : Members)
				{
					ASanctuaryLavamoleDigPoint DigPoint = Cast<ASanctuaryLavamoleDigPoint>(Member);
					if (DigPoint != nullptr)
					{
						if (DigPoint.HasOccupant())
							continue;
						NewHole = DigPoint;
					}
					NewDigLocation = Member.ActorLocation;
					break;
				}
			}
		}
		OutNewHole = NewHole;
		OutDigLocation = NewDigLocation;
	}

}