class USkylineInnerReceptionistFindInterestPointCapability : UHazeCapability
{
	default TickGroup = EHazeTickGroup::Gameplay;

	ASkylineInnerReceptionistBot Receptionist;
	AHazePlayerCharacter Mio;
	AHazePlayerCharacter Zoe;

	float RandomInterestCooldown = 0.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Receptionist = Cast<ASkylineInnerReceptionistBot>(Owner);
		Mio = Game::Mio;
		Zoe = Game::Zoe;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!HasControl())
			return false;
		if (Receptionist.AnnoyedVolume == nullptr)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Follow player ?
		AHazePlayerCharacter FollowPlayer = nullptr;
		bool bPrioMio = Receptionist.State == ESkylineInnerReceptionistBotState::ExterminateMode || Receptionist.State == ESkylineInnerReceptionistBotState::Smug;
		bool bFollowMio = bPrioMio || Receptionist.InAnnoyedRange[Mio] || Receptionist.InRange[Mio];
		bool bFollowZoe = Receptionist.bZoeGrabbedCup || Receptionist.InAnnoyedRange[Zoe] || Receptionist.InRange[Zoe];
		if (bFollowMio && !Receptionist.PlayersOnTop[Mio])
			FollowPlayer = Mio;
		if (!bPrioMio && bFollowZoe && !Receptionist.PlayersOnTop[Zoe])
		{
			if (FollowPlayer == nullptr)
				FollowPlayer = Zoe;
			else if (Receptionist.ActorLocation.Distance(FollowPlayer.ActorLocation) > Receptionist.ActorLocation.Distance(Zoe.ActorLocation))
				FollowPlayer = Zoe;
		}

		RandomInterestCooldown -= DeltaTime;
		Receptionist.SetLookAtPlayer(FollowPlayer);

		if (FollowPlayer != nullptr)
		{
			FVector TowardsPlayer = FollowPlayer.ActorLocation - Receptionist.ActorLocation;
			TowardsPlayer.Z = 0.0;

			FVector TowardsPlayerFromCenter = (FollowPlayer.ActorLocation - Receptionist.AnnoyedVolume.ActorLocation).GetClampedToSize(0.0, Receptionist.AnnoyedVolume.Area.SphereRadius * 0.9);
			FVector DesiredLocation = TowardsPlayerFromCenter + Receptionist.AnnoyedVolume.ActorLocation;
			Receptionist.InterestPoint = FTransform(FRotator::MakeFromXZ(TowardsPlayer.GetSafeNormal(), FVector::UpVector).Quaternion(), DesiredLocation);
		}
		else if (RandomInterestCooldown < 0.0)
		{
			// random point plz
			RandomInterestCooldown = Math::RandRange(8.0, 15.0);
			
			float RandomScreenChance = Math::RandRange(0.0, 1.0);
			if (RandomScreenChance < 0.7)
				Receptionist.InterestPoint = Receptionist.OGInterestPoint;
			else
				RandomInterestLocation();
		}
	}

	private void RandomInterestLocation()
	{
		FVector RandomDirection = FQuat(FVector::UpVector, Math::DegreesToRadians(Math::RandRange(0.0, 360.0))).ForwardVector;
		FVector DesiredLocation = Receptionist.AnnoyedVolume.ActorLocation + RandomDirection * Receptionist.AnnoyedVolume.Area.SphereRadius;
		Receptionist.InterestPoint = FTransform(FRotator::MakeFromXZ(RandomDirection, FVector::UpVector).Quaternion(), DesiredLocation);
	}
};