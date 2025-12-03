enum EMoonGuardianCatWakeUpReason
{
	WrongNote,
	StoppedPlaying,
	TwigsBroken,
	CatTaken
}

enum EMoonGuardianSleepState
{
	Awake,
	HalfAsleep,
	Asleep
}
struct FMoonGuardianAnimData
{
	bool bHarpFail;
	bool bFootstepFail;
	bool bRoaring;
}

event void OnMoonGuardianCatAwake();
event void OnMoonGuardianCatSleep();

class AMoonGuardianCat : AHazeActor
{
	OnMoonGuardianCatSleep OnSleep;

	OnMoonGuardianCatAwake OnAwake;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeCharacterSkeletalMeshComponent Mesh;

	UPROPERTY(DefaultComponent, Attach = Mesh, AttachSocket = "LowerLip")
	USceneComponent RoarLocation;
	
	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComp;

	UPROPERTY(EditAnywhere, EditInstanceOnly)
	APlayerTrigger PlayerTrigger;

	UPROPERTY(EditAnywhere, EditInstanceOnly)
	AMoonMarketCat TargetCat;

	UPROPERTY(EditInstanceOnly)
	AMoonGuardianCatZeesManager Manager;

	UPROPERTY(EditInstanceOnly)
	TArray<ARevealablePlatform> ReavablePlatforms;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> CameraShake;

	UPROPERTY()
	UForceFeedbackEffect ForceFeedback;

	UPROPERTY(EditInstanceOnly)
	ASplineActor LandingSpline;

	TPerPlayer<bool> bPlayersInside;
	TArray<AHazePlayerCharacter> PlayersCurrentlyInside;

	const float WakeUpTime = 1.5;
	float CurrentAwakeTime;

	bool bIsSleeping = true;
	bool bDevDisableScream = false;
	
	private int TotalHarps;
	UMoonGuardianHarpPlayingComponent HarpComp;
	private float HarpStopPlayingTime;
	
	UPROPERTY(EditAnywhere)
	float TimeToWakeUp = 0;
	
	EMoonGuardianSleepState SleepState = EMoonGuardianSleepState::Awake;
	FMoonGuardianAnimData AnimData;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		PlayerTrigger.OnPlayerEnter.AddUFunction(this, n"OnPlayerEnter");
		PlayerTrigger.OnPlayerLeave.AddUFunction(this, n"OnPlayerLeave");
		TargetCat.OnMoonCatSoulCaught.AddUFunction(this, n"OnMoonCatSoulCaught");

		TotalHarps = TListedActors<AMoonGuardianHarp>().Array.Num();
		TListedActors<AMoonGuardianHarp>().Single.OnStartedPlaying.AddUFunction(this, n"OnStartedPlaying");
		TListedActors<AMoonGuardianHarp>().Single.OnStoppedPlaying.AddUFunction(this, n"OnStoppedPlaying");
	}


	UFUNCTION()
	private void OnStoppedPlaying()
	{
		WakeUp(EMoonGuardianCatWakeUpReason::StoppedPlaying, nullptr);
		HarpComp = nullptr;
	}

	UFUNCTION()
	private void OnStartedPlaying(UMoonGuardianHarpPlayingComponent Player)
	{
		HarpComp = Player;
	}

	UFUNCTION()
	private void OnMoonCatSoulCaught(AHazePlayerCharacter Player, AMoonMarketCat Cat)
	{
		if (HarpComp != nullptr)
		{
			HarpComp.SetExitDuration(1);
		}
	}

	bool CanWakeUp() const
	{
		if(HarpComp != nullptr)
			return false;

			return Time::GetGameTimeSince(HarpStopPlayingTime) > TimeToWakeUp;
	}

	UFUNCTION()
	void WakeUp(EMoonGuardianCatWakeUpReason Reason, AHazePlayerCharacter PlayerAtFault)
	{
		if(!bIsSleeping)
			return;

		bIsSleeping = false;
		Manager.SetZeeSpawning(false);
		SleepState = EMoonGuardianSleepState::Awake;
		UMoonGuardianCatEffectHandler::Trigger_OnCatWakeUp(this);

		if(Reason == EMoonGuardianCatWakeUpReason::TwigsBroken)
			AnimData.bFootstepFail = true;
		else
			AnimData.bHarpFail = true;
	}

	void IncreaseSleepiness(AHazePlayerCharacter CurrentPlayer)
	{
		if(AnimData.bRoaring)
			return;

		if(SleepState == EMoonGuardianSleepState::Asleep)
			return;

		AnimData.bHarpFail = false;
		AnimData.bFootstepFail = false;

		if(SleepState == EMoonGuardianSleepState::Awake)
		{
			bIsSleeping = true;
			SleepState = EMoonGuardianSleepState::HalfAsleep;
			UMoonGuardianCatEffectHandler::Trigger_OnCatHalfAsleep(this);
		}
		else
		{
			Sleep();
			UMoonGuardianCatEffectHandler::Trigger_OnCatFullAsleep(this);
		}
	}

	UFUNCTION()
	private void Sleep()
	{
		SleepState = EMoonGuardianSleepState::Asleep;
		bIsSleeping = true;
		Manager.SetZeeSpawning(true);
	}

	void Roar()
	{
		float Duration = 1.4;
		UMoonGuardianCatEffectHandler::Trigger_OnCatRoar(this, FOnMoonGuardianCatRoarParams(RoarLocation));

		for (AHazePlayerCharacter Player : PlayersCurrentlyInside)
		{
			Player.PlayWorldCameraShake(CameraShake, this, ActorLocation, 300, 6000);
			Player.PlayForceFeedback(ForceFeedback, false, false, this);
			
			FVector LandingLocation = LandingSpline.Spline.GetClosestSplineWorldLocationToWorldLocation(Player.ActorLocation);
			FPlayerLaunchToParameters Params;
			Params.Duration = Duration;
			Params.LaunchToLocation = LandingLocation;
			Params.Type = EPlayerLaunchToType::LaunchToPoint;
			Player.LaunchPlayerTo(this, Params);
		}
	}

	UFUNCTION()
	private void OnPlayerEnter(AHazePlayerCharacter Player)
	{
		bPlayersInside[Player] = true;
		PlayersCurrentlyInside.AddUnique(Player);

		// if(!bIsSleeping)
		// 	WakeUp(EMoonGuardianCatWakeUpReason::TwigsBroken, Player);
	}

	UFUNCTION()
	private void OnPlayerLeave(AHazePlayerCharacter Player)
	{
		bPlayersInside[Player] = false;
		PlayersCurrentlyInside.Remove(Player);
	}

	bool PlayerInRange()
	{
		return bPlayersInside[0] || bPlayersInside[1];
	}

	UFUNCTION(DevFunction)
	void ToggleScreamEnabled()
	{
		bDevDisableScream = !bDevDisableScream;
	}
};