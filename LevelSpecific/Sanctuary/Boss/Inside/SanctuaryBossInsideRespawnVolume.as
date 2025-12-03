class ASanctuaryBossInsideRespawnVolume : APlayerTrigger
{
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		OnPlayerEnter.AddUFunction(this, n"HandlePlayerEnter");
		OnPlayerLeave.AddUFunction(this, n"HandlePlayerLeave");
	}

	UFUNCTION()
	private void HandlePlayerEnter(AHazePlayerCharacter Player)
	{
		FOnRespawnOverride RespawnOverride;
		RespawnOverride.BindUFunction(this, n"RespawnOnOtherPlayer");
		Player.ApplyRespawnPointOverrideDelegate(this, RespawnOverride);
		UPlayerHealthSettings::SetGameOverWhenBothPlayersDead(Player, true, this);
		{
			USanctuaryBossInsidePlayerEnsureRespawnGroundedComponent Comp = USanctuaryBossInsidePlayerEnsureRespawnGroundedComponent::GetOrCreate(Player);
			Comp.EnsureRequesters.Add(this);
		}
	}

	UFUNCTION()
	private void HandlePlayerLeave(AHazePlayerCharacter Player)
	{
		Player.ClearRespawnPointOverride(this);
		UPlayerHealthSettings::ClearGameOverWhenBothPlayersDead(Player, this);
		{
			USanctuaryBossInsidePlayerEnsureRespawnGroundedComponent Comp = USanctuaryBossInsidePlayerEnsureRespawnGroundedComponent::GetOrCreate(Player);
			Comp.EnsureRequesters.Remove(this);
		}
	}

	UFUNCTION()
	private bool RespawnOnOtherPlayer(AHazePlayerCharacter Player, FRespawnLocation& OutLocation)
	{
		if (!Player.OtherPlayer.IsOnWalkableGround())
			return false;

		FHazeTraceSettings Trace = Trace::InitChannel(ECollisionChannel::WorldGeometry);
		Trace.UseLine();
		Trace.IgnorePlayers();
		FHitResult Hit = Trace.QueryTraceSingle(Player.OtherPlayer.ActorLocation + FVector::UpVector * 100, Player.OtherPlayer.ActorLocation - FVector::UpVector * 100);
		if (!Hit.bBlockingHit)
			return false;
		
		FTransform UpwardsSlightly = Player.OtherPlayer.ActorTransform;
		UpwardsSlightly.SetLocation(UpwardsSlightly.Location + FVector::UpVector * 10);
		OutLocation.RespawnTransform = UpwardsSlightly.GetRelativeTransform(Hit.Component.WorldTransform);
		OutLocation.RespawnWithVelocity = FVector();
		OutLocation.RespawnRelativeTo = Hit.Component;

		return true;
	}
};