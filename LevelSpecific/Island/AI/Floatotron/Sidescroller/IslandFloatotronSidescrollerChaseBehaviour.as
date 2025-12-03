// Move towards enemy
class UIslandFloatotronSidescrollerChaseBehaviour : UBasicBehaviour
{
	// Movement only (which is replicated separately)
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::ActivatesOnControlOnly;

	default Requirements.Add(EBasicBehaviourRequirement::Movement);

	UIslandFloatotronSettings Settings;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Settings = UIslandFloatotronSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if (!TargetComp.HasValidTarget())
			return false;
		if (TargetComp.Target.ActorCenterLocation.IsWithinDist(Owner.ActorCenterLocation, Settings.SidescrollerChaseMinRange))
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

	float SlotOffset = 0.0;

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		
		CalculateChaseHeightOffset();
	}

	private void CalculateChaseHeightOffset()
	{		
		UHazeTeam Team = HazeTeam::GetTeam(IslandFloatotronSidescrollerTags::IslandFloatotronTeam);
		int Slot = 0;
		float SlotOffsetIncrement = Settings.SidescrollerHeightSlotOffset; 
		for (AHazeActor Member : Team.GetMembers())
		{
			if (Member == nullptr)
				continue;

			if (Member.IsActorDisabled())
				continue;
			
			if (Member != Owner)
			{
				Slot++;
				continue;
			}

			break;
		}
		SlotOffset = Slot * SlotOffsetIncrement;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector ChaseLocation = TargetComp.Target.ActorLocation;
				
		ChaseLocation.Z += Settings.SidescrollerFlyingChaseMinHeight + SlotOffset;

		if (Owner.ActorLocation.IsWithinDist(ChaseLocation, Settings.SidescrollerChaseMinRange))
		{
			Cooldown.Set(BasicSettings.ChaseMinRangeCooldown);
			return;
		}

		// Keep moving towards target!
		DestinationComp.MoveTowards(ChaseLocation, Settings.SidescrollerChaseMoveSpeed);
	}
}