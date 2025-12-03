class UCoastContainerTurretWeaponSetTargetBehaviour : UBasicBehaviour
{
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::ActivatesOnControlOnly;

	UCoastContainerTurretSettings Settings;
	UCoastContainerTurretWeaponMuzzleComponent MuzzleComp;

	float RetargetInterval = 0.25;
	float RetargetTime;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Settings = UCoastContainerTurretSettings::GetSettings(Owner);
		MuzzleComp = UCoastContainerTurretWeaponMuzzleComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Super::ShouldActivate())
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(RetargetTime > 0 && Time::GetGameTimeSince(RetargetTime) < RetargetInterval)
			return;

		TargetComp.Target = GetTargetPlayer();
		RetargetTime = Time::GameTimeSeconds;
	}

	AHazePlayerCharacter GetTargetPlayer()
	{
		AHazePlayerCharacter Target = nullptr;

		for(AHazePlayerCharacter Player: Game::Players)
		{
			if(Owner.GetDistanceTo(Player) > Settings.AttackMaxRange)
				continue;

			if(Target != nullptr)
			{
				if(Owner.GetDistanceTo(Player) < Owner.GetDistanceTo(Target))
					Target = Player;

				FHazeTraceSettings Trace = Trace::InitChannel(ECollisionChannel::WeaponTraceEnemy);
				Trace.UseLine();
				FHitResult Hit = Trace.QueryTraceSingle(MuzzleComp.WorldLocation, Target.ActorCenterLocation);
				FHitResult HitOther = Trace.QueryTraceSingle(MuzzleComp.WorldLocation, Target.OtherPlayer.ActorCenterLocation);

				if(Hit.Actor != Target && HitOther.Actor == Target.OtherPlayer)
					Target = Target.OtherPlayer;
			}
			else
			{
				Target = Player;
			}
		}

		return Target;
	}
}