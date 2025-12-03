struct FDentistCupSortParams
{
	AHazePlayerCharacter TargetedPlayer;
	bool bIsLeftGrabber = true;
}

struct FDentistCupPlayerParams
{
	AHazePlayerCharacter Player;
}

class UDentistBossCupSortingComponent : UActorComponent
{
	access ReadOnly = private, * (readonly);
	access : ReadOnly TArray<EDentistBossToolCupSortType> CupSorting; 
	private int NextIndex = 0;
	private bool bIsFlipped = false;

	private UHazeActionQueueComponent CupActionQueueComp;
	private ADentistBoss Dentist;
	private UDentistBossSettings Settings;
	private UDentistBossTargetComponent TargetComp;

	private FDentistBossHeadlightSettings LookAtStartSettings;
	private FVector LookAtStartLocation;
	private bool bDashToOpenCupTutorialShown = false;

	TPerPlayer<bool> NetworkSortingComplete;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Dentist = Cast<ADentistBoss>(Owner);
		CupActionQueueComp = UHazeActionQueueComponent::Create(Dentist, n"CupActionQueueComp");
		Settings = UDentistBossSettings::GetSettings(Dentist);
		TargetComp = UDentistBossTargetComponent::GetOrCreate(Dentist);

		if (HasControl())
		{
			TArray<EDentistBossToolCupSortType> SortedCups;
			
			bool bFlippy = GetRandomBool();
			SortedCups.Add(EDentistBossToolCupSortType::Left);
			SortedCups.Add(EDentistBossToolCupSortType::Right);
			SortedCups.Add(EDentistBossToolCupSortType::Sides);
			SortedCups.Add(GetRandomSortType()); 
			SortedCups.Add(GetRandomSortType()); 
			SortedCups.Add(EDentistBossToolCupSortType::Left);
			SortedCups.Add(EDentistBossToolCupSortType::Right);
			SortedCups.Add(EDentistBossToolCupSortType::Sides);
			SortedCups.Add(GetRandomSortType()); 
			SortedCups.Add(EDentistBossToolCupSortType::Left);
			SortedCups.Add(EDentistBossToolCupSortType::Sides);
			SortedCups.Add(GetRandomSortType()); 
			SortedCups.Add(EDentistBossToolCupSortType::Left);
			SortedCups.Add(EDentistBossToolCupSortType::Right);
			SortedCups.Add(GetRandomSortType()); 
			SortedCups.Add(EDentistBossToolCupSortType::Right);
			SortedCups.Add(EDentistBossToolCupSortType::Right);
			SortedCups.Add(EDentistBossToolCupSortType::Sides);
			SortedCups.Add(GetRandomSortType()); 
			SortedCups.Add(EDentistBossToolCupSortType::Right);
			SortedCups.Add(EDentistBossToolCupSortType::Right);
			SortedCups.Add(EDentistBossToolCupSortType::Left);
			SortedCups.Add(GetRandomSortType()); 
			SortedCups.Add(EDentistBossToolCupSortType::Right);

			CrumbSetSorting(SortedCups, bFlippy);
		}
	}

	private bool GetRandomBool() const
	{
		int Rand = Math::RandRange(0, 1);
		return Rand == 0 ? true : false; 
	}

	private EDentistBossToolCupSortType GetRandomSortType() const
	{
		int Rand = Math::RandRange(0, 2);
		if(Rand == 0)
			return EDentistBossToolCupSortType::Left;
		else if(Rand == 1)
			return EDentistBossToolCupSortType::Right;
		else
			return EDentistBossToolCupSortType::Sides;
	}

	UFUNCTION(CrumbFunction)
	private void CrumbSetSorting(TArray<EDentistBossToolCupSortType> SortedCups, bool bFlip)
	{
		CupSorting = SortedCups;
		bIsFlipped = bFlip;
	}

	void DoTheLocalCupSorting(FDentistCupSortParams AttackParams)
	{
		AHazePlayerCharacter TargetPlayer = AttackParams.TargetedPlayer;
	
		if(!DentistBossDevToggles::NoCupSorting.IsEnabled())
		{
			CupActionQueueComp.Idle(0.5);
			
			float SortDuration = 0.9;

			AddCupSorting(SortDuration);
			AddCupSorting(SortDuration);
			AddCupSorting(SortDuration);
			AddCupSorting(SortDuration);

			SortDuration = 0.7;

			AddCupSorting(SortDuration);
			AddCupSorting(SortDuration);
			AddCupSorting(SortDuration);
			AddCupSorting(SortDuration);

			CupActionQueueComp.Idle(0.75);

			SortDuration = 0.3;

			AddCupSorting(SortDuration);
			AddCupSorting(SortDuration);
			AddCupSorting(SortDuration);
			AddCupSorting(SortDuration);

			AddCupSorting(SortDuration);
			AddCupSorting(SortDuration);
			AddCupSorting(SortDuration);
			AddCupSorting(SortDuration);

			AddCupSorting(SortDuration);
			AddCupSorting(SortDuration);
			AddCupSorting(SortDuration);
			AddCupSorting(SortDuration);

			AddCupSorting(SortDuration);
			AddCupSorting(SortDuration);
			AddCupSorting(SortDuration);
			AddCupSorting(SortDuration);
		}

		if(!bDashToOpenCupTutorialShown)
		{
			CupActionQueueComp.Capability(UDentistBossCupShowDashTutorialCapability);
			bDashToOpenCupTutorialShown = true;
		}

		CupActionQueueComp.Event(this, n"SetLookAtPlayer", MakePlayerParams(TargetPlayer.OtherPlayer));
		CupActionQueueComp.Event(this, n"SetStartLookAt");
		CupActionQueueComp.Duration(Settings.LookDuration, this, n"LookAtPlayer");

		CupActionQueueComp.Event(this, n"LocalCupSortingComplete");
	}

	private FDentistCupPlayerParams MakePlayerParams(AHazePlayerCharacter SomePlayer) const
	{
		FDentistCupPlayerParams Params;
		Params.Player = SomePlayer;
		return Params;
	}

	UFUNCTION()
	private void LocalCupSortingComplete()
	{
		if (!Network::IsGameNetworked())
		{
			NetworkSortingComplete[Game::Mio] = true;
			NetworkSortingComplete[Game::Zoe] = true;
		}
		else
		{
			AHazePlayerCharacter MyPlayer = Game::Mio.HasControl() ? Game::Mio : Game::Zoe;
			CrumbSortingDoneForPlayer(MyPlayer);
		}
	}
	
	UFUNCTION(CrumbFunction)
	private void CrumbSortingDoneForPlayer(AHazePlayerCharacter PlayingPlayer)
	{
		NetworkSortingComplete[PlayingPlayer] = true;
	}

	UFUNCTION()
	private void AddCupSorting(float SortDuration)
	{
		EDentistBossToolCupSortType Sorting = CupSorting[NextIndex];
		NextIndex++;
		SortSequence(Sorting, SortDuration);
	}

	private void SortSequence(EDentistBossToolCupSortType SortType, float Duration)
	{
		FDentistBossCupSortSequenceActivationParams Params;
		Params.Duration = Duration;

		if(SortType == EDentistBossToolCupSortType::Left)
		{
			if(bIsFlipped)
				Params.SortType = EDentistBossToolCupSortType::Right;
			else
				Params.SortType = EDentistBossToolCupSortType::Left;
		}
		else if(SortType == EDentistBossToolCupSortType::Right)
		{
			if(bIsFlipped)
				Params.SortType = EDentistBossToolCupSortType::Left;
			else
				Params.SortType = EDentistBossToolCupSortType::Right;
		}
		else if(SortType == EDentistBossToolCupSortType::Sides)
			Params.SortType = EDentistBossToolCupSortType::Sides;

		CupActionQueueComp.Capability(UDentistBossCupCupSortSequenceCapability, Params);
	}


	UFUNCTION()
	private void SetLookAtPlayer(FDentistCupPlayerParams TargetPlayer)
	{
		TargetComp.Target.Clear(Dentist);
		if(TargetPlayer.Player != nullptr)
			TargetComp.Target.Apply(TargetPlayer.Player, Dentist, EInstigatePriority::Normal);
	}

	UFUNCTION()
	private void SetStartLookAt()
	{
		LookAtStartLocation = TargetComp.LookTargetLocation; 
		LookAtStartSettings = Dentist.CurrentSpotlightSettings;
		TargetComp.bOverrideLooking = true;
	}

	UFUNCTION()
	private void LookAtPlayer(float Alpha)
	{
		if(Alpha >= 1 - KINDA_SMALL_NUMBER)
		{
			TargetComp.LookAtTarget(TargetComp.Target.Get().ActorCenterLocation);
			return;
		}
		
		if(Dentist.CurrentSpotlightSettings.LightColor != Settings.HasTargetSpotlightSettings.LightColor)
			Dentist.CurrentSpotlightSettings.LerpSettings(LookAtStartSettings, Settings.HasTargetSpotlightSettings, Alpha);

		FVector NewTargetLocation = Math::Lerp(LookAtStartLocation, TargetComp.Target.Get().ActorCenterLocation, Alpha);
		TargetComp.LookAtTarget(NewTargetLocation);
	}
};