struct FEnforcerAvoidGrenadeParams
{
	// Grenades are not networked (no need since they are deterministic enough) so send location rather than grenade over network
	FVector GrenadeLocation;
}

class UEnforcerAvoidGrenadesBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Movement);
	default Requirements.Add(EBasicBehaviourRequirement::Focus);

	UEnforcerGrenadeLauncherComponent GrenadeLauncher;
	UEnforcerGrenadeSettings Settings;
	float ReactionTime = 0.0;
	bool bCheckForGrenades = false;
	const float DangerousThreshold = 0.1;
	AEnforcerGrenade LiveGrenade;	
	bool bDangerAverted;
	float AvoidDuration;
	FVector AvoidLocation;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Settings = UEnforcerGrenadeSettings::GetSettings(Owner);
		GrenadeLauncher = UEnforcerGrenadeLauncherComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (IsActive())
			return;
		if (Settings.AIDamage < DangerousThreshold)
			return;

		// Only check for grenades every once in a while, to simulate reaction time
		float CurTime = Time::GameTimeSeconds;
		if (CurTime > ReactionTime)
		{
			bCheckForGrenades = true;
			ReactionTime = Time::GameTimeSeconds + Math::RandRange(0.5, 0.8);
		}
		else
		{
			bCheckForGrenades = false;
		}

		// When throwing a grenade ourselves, we're mindful of where it lands...
		if ((GrenadeLauncher != nullptr) && (GrenadeLauncher.LastLaunchedProjectile != nullptr) && 
			(Time::GetGameTimeSince(GrenadeLauncher.LastLaunchedProjectile.LaunchTime) < 4.0))
			bCheckForGrenades = true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FEnforcerAvoidGrenadeParams& OutParams) const
	{
		if (!Super::ShouldActivate())
			return false;
		if (!bCheckForGrenades)
			return false;
		if (Settings.AIDamage < DangerousThreshold)
			return false;
		AEnforcerGrenade DangerousGrenade = FindClosestLiveGrenade(Owner.ActorLocation, Settings.BlastRadius + 50.0);
		if (DangerousGrenade == nullptr)
			return false;
		OutParams.GrenadeLocation = DangerousGrenade.ActorLocation;
		return true;
	}

	AEnforcerGrenade FindClosestLiveGrenade(FVector Location, float MaxRange) const
	{
		float ClosestDistSqr = Math::Square(MaxRange);
		AEnforcerGrenade ClosestGrenade = nullptr;
		for (AEnforcerGrenade Grenade : TListedActors<AEnforcerGrenade>())
		{
			if (!Grenade.bLanded)
				continue;
			if (Grenade.bExploded)
				continue;
			float DistSqr = Grenade.ActorLocation.DistSquared(Location);
			if (DistSqr > ClosestDistSqr)
				continue;
			ClosestDistSqr = DistSqr;
			ClosestGrenade = Grenade;
		}
		return ClosestGrenade;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (ActiveDuration > AvoidDuration)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FEnforcerAvoidGrenadeParams Params)
	{
		Super::OnActivated();
		AvoidLocation = Params.GrenadeLocation;
		LiveGrenade = FindClosestLiveGrenade(Params.GrenadeLocation, Settings.BlastRadius + 500.0);
		AvoidDuration = Settings.LandedFuseTime + 1.0;
		bDangerAverted = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		LiveGrenade = nullptr;
		Cooldown.Set(Math::RandRange(0.7, 1.2));
	}
	
	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (!bDangerAverted && ((LiveGrenade == nullptr) || LiveGrenade.bExploded))
		{
			// Pause a while, then resume other behaviour
			bDangerAverted = true;
			AvoidDuration = ActiveDuration + Math::RandRange(0.5, 1.0);
		}

		if (TargetComp.HasValidTarget())
			DestinationComp.RotateTowards(TargetComp.Target);
		else if (!bDangerAverted)
			DestinationComp.RotateTowards(LiveGrenade);

		if (!bDangerAverted && Owner.ActorLocation.IsWithinDist(LiveGrenade.ActorLocation, Settings.BlastRadius + 100.0))
		{
			// Move away from grenade until well clear
			FVector OwnLoc = Owner.ActorLocation;
			FVector TargetLoc = LiveGrenade.ActorLocation;
			FVector AwayFromTarget = (OwnLoc - TargetLoc);
			AwayFromTarget.Z = Math::Max(0.0, AwayFromTarget.Z); // Don't try to dig a hole!
			FVector AwayLoc = OwnLoc + AwayFromTarget.GetSafeNormal() * (DestinationComp.MinMoveDistance + 80.0);
			DestinationComp.MoveTowards(AwayLoc, 400.0);
		}
	}
}