class USummitCrystalSkullWingmanTargetingBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Perception);

	USummitCrystalSkullSettings SkullSettings;
	USummitCrystalSkullsTeam SkullsTeam;
	AHazeActor Boss;
	float CheckTargetTime;
	bool bRightSide;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		SkullSettings = USummitCrystalSkullSettings::GetSettings(Owner);
		SkullsTeam = CrystalSkullsTeam::Join(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if (SkullsTeam.Boss == nullptr)
			return false;
		if ((SkullsTeam.RightWing != Owner) && (SkullsTeam.LeftWing != Owner))
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		bRightSide = (SkullsTeam.RightWing == Owner);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector PlayerCenter = (Game::Mio.ActorLocation + Game::Zoe.ActorLocation) * 0.5;
		FVector BossLoc = SkullsTeam.Boss.ActorLocation;
		FVector ToBossDir = (BossLoc - PlayerCenter).GetSafeNormal2D();
		FVector BossRight = ToBossDir.CrossProduct(FVector::UpVector);
		AHazePlayerCharacter RightSidePlayer = (BossRight.DotProduct(Game::Mio.ActorLocation - BossLoc) > 0.0) ? Game::Mio : Game::Zoe;		
		AHazePlayerCharacter TargetPlayer = bRightSide ? RightSidePlayer : RightSidePlayer.OtherPlayer;

		if (!TargetPlayer.ActorLocation.IsWithinDist(Owner.ActorLocation, SkullSettings.TargetingRange))
			return; // Ignore target when too far away
		
		TargetComp.SetTarget(TargetPlayer);
		Cooldown.Set(SkullSettings.TargetingInterval);
	}
}

