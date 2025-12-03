
class UIslandBuzzerCombatMoveBehaviour : UBasicBehaviour
{
	// This behaviour is movement only and movement is replicated separately
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::ActivatesOnControlOnly;

	default Requirements.Add(EBasicBehaviourRequirement::Movement);

	UIslandWalkerUnderneathComponent UnderneathComp;
	UIslandBuzzerSettings Settings;
	FVector Wobble;
	float WobbleTime;
	float CombatMoveHeight;
	float AvoidMoveHeight;
	float UnderneathMoveHeight;
	AHazePlayerCharacter PlayerTarget;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Settings = UIslandBuzzerSettings::GetSettings(Owner);
		Wobble = FVector(0,0,Settings.WobbleAmplitude);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Super::ShouldActivate())
			return false;
		if(!TargetComp.HasValidTarget())
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Super::ShouldDeactivate())
			return true;
		if(!TargetComp.HasValidTarget())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		PlayerTarget = Cast<AHazePlayerCharacter>(TargetComp.Target);
		CombatMoveHeight = Settings.CombatMoveHeight + Math::RandRange(-50, 50);
		AvoidMoveHeight = Settings.CombatMoveAvoidHeight + Math::RandRange(-50, 50);
		UnderneathMoveHeight = Settings.CombatMoveUnderneathHeight + Math::RandRange(-50, 50);

		auto RespawnComp = UHazeActorRespawnableComponent::Get(Owner);
		if(RespawnComp != nullptr && RespawnComp.Spawner != nullptr)
		{
			UnderneathComp = UIslandWalkerUnderneathComponent::Get(RespawnComp.Spawner);
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Wobble
		// TODO: Move this to a separate capability that offsets the mesh
		if(Time::GetGameTimeSince(WobbleTime) >= Settings.WobbleFrequency)
		{
			Wobble *= -1;
			WobbleTime = Time::GetGameTimeSeconds();
		}

		FVector CombatLocation = Owner.ActorLocation;
		FVector TargetLoc = PlayerTarget.FocusLocation;
		if(Owner.ActorLocation.IsWithinDist(TargetLoc, Settings.CombatMoveMinDistance))
		{
			CombatLocation += Owner.ActorForwardVector * -100;
		}

		FVector TargetDir = (TargetLoc - CombatLocation).GetSafeNormal();
		if (PlayerTarget.ViewRotation.ForwardVector.DotProduct(TargetDir) > -0.8)
		{
			// Not in front of target, circle around
			float CircleDir = 1.0;
			if (PlayerTarget.ViewRotation.RightVector.DotProduct(TargetDir) < 0.0)
				CircleDir = -1.0;
			CombatLocation = TargetLoc + (CombatLocation - TargetLoc).RotateAngleAxis(CircleDir * 30.0, FVector::UpVector);		
		}

		float MoveHeight = CombatMoveHeight;

		bool bAvoided = false;
		for(AHazePlayerCharacter Player: Game::Players)
		{
			if(Player.ActorLocation.IsWithinDist(Owner.ActorLocation, Settings.CombatMoveAvoidDistance))
			{
				bAvoided = true;
				MoveHeight = AvoidMoveHeight;
				break;
			}
		}
		
		if(UnderneathComp != nullptr)
		{
			AHazePlayerCharacter TargetPlayer = Cast<AHazePlayerCharacter>(TargetComp.Target);
			if(!bAvoided && TargetPlayer != nullptr && UnderneathComp.UnderneathPlayers.Contains(TargetPlayer))
				MoveHeight = UnderneathMoveHeight;
		}

		CombatLocation.Z = TargetComp.Target.ActorLocation.Z + MoveHeight;

		float MoveSpeed = Settings.CombatMoveSpeed * Math::Clamp(Owner.ActorLocation.Distance(CombatLocation) / 100, 0.2, 1);
		DestinationComp.MoveTowards(CombatLocation + Wobble, MoveSpeed);
	}
}