class USummitKnightProximityFocusBehaviour : UBasicBehaviour
{		
	AHazePlayerCharacter FocusTarget;
	USummitKnightDeprecatedSettings KnightSettings;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		FocusTarget = Game::Zoe;
		KnightSettings = USummitKnightDeprecatedSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Super::ShouldActivate())
			return false;
		if(!TargetComp.HasValidTarget())
			return false;
		if(!FocusTarget.ActorLocation.IsWithinDist(Owner.ActorLocation, KnightSettings.ProximityFocusRange))
			return false;
		if(TargetComp.Target == FocusTarget)
			return false;
		auto TeenDragon = UTeenDragonRollComponent::Get(FocusTarget);
		if(TeenDragon == nullptr)
			return false;
		if(!TeenDragon.IsRolling())
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
		if(!FocusTarget.ActorLocation.IsWithinDist(Owner.ActorLocation, KnightSettings.ProximityFocusRange))
			return true;
		auto TeenDragon = UTeenDragonRollComponent::Get(FocusTarget);
		if(TeenDragon == nullptr)
			return true;
		if(!TeenDragon.IsRolling())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		TargetComp.SetTarget(FocusTarget);
		UBasicAISettings::SetChaseMoveSpeed(Owner, KnightSettings.ProximityFocusChaseMoveSpeed, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		TargetComp.SetTarget(FocusTarget.OtherPlayer);
		UBasicAISettings::ClearChaseMoveSpeed(Owner, this);
	}
}