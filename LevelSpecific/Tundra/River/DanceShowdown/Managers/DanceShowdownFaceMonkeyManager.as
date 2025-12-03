event void OnBothMonkeysRemoved(float Time);

class UDanceShowdownFaceMonkeyManager : UActorComponent
{
	OnBothMonkeysRemoved OnBothMonkeysRemovedEvent;
	
	UPROPERTY()
	FDanceShowdownNoParamsEvent OnMonkeyHitPlayer;

	UPROPERTY(EditInstanceOnly)
	ADanceShowdownThrowableMonkey LeftMonkey;

	UPROPERTY(EditInstanceOnly)
	ADanceShowdownThrowableMonkey RightMonkey;

	UPROPERTY(EditInstanceOnly)
	TArray<AHazeActor> LeftPillars;

	UPROPERTY(EditInstanceOnly)
	TArray<AHazeActor> RightPillars;

	bool bMovePillars = false;
	float TargetPillarLocationZ;
	FHazeAcceleratedFloat PillarCurrentLocationZ;
	float PillarHeight = 300;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		OnBothMonkeysRemovedEvent.AddUFunction(this, n"RespawnMonkeysAfterDelay");
	}

	UFUNCTION()
	private void RespawnMonkeysAfterDelay(float Time)
	{
		if(LeftMonkey.State != EThrowableMonkeyState::OnPillar)
			Timer::SetTimer(this, n"RespawnLeftMonkey", 1);

		if(RightMonkey.State != EThrowableMonkeyState::OnPillar)
			Timer::SetTimer(this, n"RespawnRightMonkey", 1);
	}

	UFUNCTION()
	private void RespawnBothMonkeys()
	{
		RespawnLeftMonkey();
		RespawnRightMonkey();
	}

	UFUNCTION()
	void RespawnLeftMonkey()
	{

		auto Pillar = LeftPillars[DanceShowdown::GetManager().RhythmManager.GetCurrentStage()];
		
		LeftMonkey.State = EThrowableMonkeyState::MovingToPillar;
		LeftMonkey.CurrentPillar = Pillar;
		LeftMonkey.AttachToActor(Pillar);
	}

	UFUNCTION()
	void RespawnRightMonkey()
	{
		auto Pillar = RightPillars[DanceShowdown::GetManager().RhythmManager.GetCurrentStage()];

		RightMonkey.State = EThrowableMonkeyState::MovingToPillar;
		RightMonkey.CurrentPillar = Pillar;
		RightMonkey.AttachToActor(Pillar);
	}

	UFUNCTION()
	void RaisePillars()
	{
		bMovePillars = true;
		PillarCurrentLocationZ.SnapTo(LeftPillars[DanceShowdown::GetManager().RhythmManager.GetCurrentStage()].ActorLocation.Z);
		TargetPillarLocationZ = PillarCurrentLocationZ.Value + PillarHeight;
		LeftMonkey.SetActorHiddenInGame(true);
		RightMonkey.SetActorHiddenInGame(true);
	}

	ADanceShowdownThrowableMonkey GetMonkeyForPlayer(AHazePlayerCharacter Player)
	{
		if(Player.IsMio())
			return LeftMonkey;

		return RightMonkey;
	}

	void RemoveMonkey(UDanceShowdownPlayerComponent DanceComp, float Time)
	{	
		if(UDanceShowdownPlayerComponent::Get(DanceComp.Player.OtherPlayer).MonkeyOnFace == nullptr)
		{
			OnBothMonkeysRemovedEvent.Broadcast(Time);
			DanceShowdown::GetManager().OnMonkeyRecovery.Broadcast();
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(bMovePillars)
		{
			PillarCurrentLocationZ.AccelerateTo(TargetPillarLocationZ, 2, DeltaSeconds, EHazeAcceleratedValueSnapCondition::TargetLower);
			int Stage = DanceShowdown::GetManager().RhythmManager.GetCurrentStage();
			LeftPillars[Stage].SetActorLocation(FVector(LeftPillars[Stage].ActorLocation.X, LeftPillars[Stage].ActorLocation.Y, PillarCurrentLocationZ.Value));
			RightPillars[Stage].SetActorLocation(FVector(RightPillars[Stage].ActorLocation.X, RightPillars[Stage].ActorLocation.Y, PillarCurrentLocationZ.Value));

			if(TargetPillarLocationZ - PillarCurrentLocationZ.Value <= 1)
			{
				RespawnBothMonkeys();
				bMovePillars = false;
			}
		}
	}
};