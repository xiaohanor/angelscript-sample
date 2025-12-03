
// Move towards enemy
class UIslandShieldotronAggressiveChaseBehaviour : UBasicBehaviour
{
	// Movement only (which is replicated separately)
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::LocalOrCrumbNetwork;

	default Requirements.Add(EBasicBehaviourRequirement::Movement);

	UIslandShieldotronSettings Settings;
	UIslandShieldotronAggressiveTeam AggressiveTeam;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Settings = UIslandShieldotronSettings::GetSettings(Owner);
		AggressiveTeam = Cast<UIslandShieldotronAggressiveTeam>(HazeTeam::GetTeam(IslandShieldotronTags::IslandShieldotronAggressiveTeam));
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if (!TargetComp.HasValidTarget())
			return false;
		
		if (AggressiveTeam != nullptr)
		{
			TArray<AHazeActor> Members = AggressiveTeam.GetMembers();
			for (AHazeActor Member : Members)
			{
				if (Member == Owner)
					continue;

				if (AggressiveTeam.IsOtherTeamMemberChasingTarget(TargetComp.Target, Owner))
					return false;
			}
		}

		if(Owner.ActorLocation.IsWithinDist(TargetComp.Target.ActorLocation, Settings.ChaseMinRange))
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (!TargetComp.HasValidTarget())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		if (AggressiveTeam == nullptr)
			AggressiveTeam = Cast<UIslandShieldotronAggressiveTeam>(HazeTeam::GetTeam(IslandShieldotronTags::IslandShieldotronAggressiveTeam));

		if(!AggressiveTeam.TryReportChasing(TargetComp.Target, Owner))
			DeactivateBehaviour();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		AggressiveTeam.ReportStopChasing(TargetComp.Target, Owner);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (Owner.ActorLocation.IsWithinDist(TargetComp.Target.ActorLocation, Settings.ChaseMinRange))
		{
			Cooldown.Set(Settings.ChaseMinRangeCooldown);
			return;
		}

		// Keep moving towards target!
		DestinationComp.MoveTowards(TargetComp.Target.ActorLocation, Settings.ChaseMoveSpeed);
	}
}