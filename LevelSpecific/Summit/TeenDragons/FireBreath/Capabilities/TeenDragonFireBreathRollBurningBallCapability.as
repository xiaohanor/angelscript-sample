class UTeenDragonFireBreathRollBurningBallCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(TeenDragonCapabilityTags::TeenDragon);

	default TickGroup = EHazeTickGroup::Gameplay;

	UPlayerTailTeenDragonComponent DragonComp;
	UTeenDragonFireBreathComponent FireBreathComp;
	UTeenDragonRollComponent RollComp;
	UTeenDragonFireBreathSettings Settings;

	UNiagaraComponent FireEffect;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DragonComp = UPlayerTailTeenDragonComponent::Get(Player);
		FireBreathComp = UTeenDragonFireBreathComponent::Get(Player);
		RollComp = UTeenDragonRollComponent::Get(Player);
		Settings = UTeenDragonFireBreathSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		float TimeSinceFireJumped = Time::GetGameTimeSince(FireBreathComp.LastTimeFireJumped);
		if(TimeSinceFireJumped > Settings.FireJumpBurningBallDuration)
			return false;

		if(FireBreathComp.bHasBeenOnFireSinceLastFireJump)
			return false;

		if(!RollComp.IsRolling())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		float TimeSinceFireJumped = Time::GetGameTimeSince(FireBreathComp.LastTimeFireJumped);
		if(TimeSinceFireJumped > Settings.FireJumpBurningBallDuration)
			return true;

		if(!RollComp.IsRolling())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		FireEffect = Niagara::SpawnLoopingNiagaraSystemAttachedAtLocation(Settings.FireJumpBurningBallEffect, Player.AttachmentRoot, Player.ActorCenterLocation);
		FireBreathComp.bHasBeenOnFireSinceLastFireJump = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		FireEffect.Deactivate();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FHazeTraceSettings Trace;
		Trace.TraceWithChannel(ECollisionChannel::WeaponTraceZoe);
		Trace.UseSphereShape(Settings.FireJumpBurningBallRadius);
		auto Overlaps = Trace.QueryOverlaps(Player.ActorCenterLocation);
		// Debug::DrawDebugSphere(Player.ActorCenterLocation, Settings.FireJumpBurningBallRadius);
		for(auto Overlap : Overlaps)
		{
			auto ResponseComp = USummitFireBreathResponseComponent::Get(Overlap.Actor);
			if(ResponseComp == nullptr)
				continue;
			
			FSummitFireBreathHitParams HitParams;
			ResponseComp.OnHit.Broadcast(HitParams);
		}
	}
};