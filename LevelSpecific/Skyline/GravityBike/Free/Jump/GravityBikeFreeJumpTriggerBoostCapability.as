struct FGravityBikeFreeJumpTriggerBoostActivateParams
{
	UGravityBikeFreeJumpTriggerComponent JumpTrigger;
};

class UGravityBikeFreeJumpTriggerBoostCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::Movement);

	default TickGroup = EHazeTickGroup::BeforeMovement;

	AGravityBikeFree GravityBike;
	UGravityBikeFreeJumpComponent JumpComp;
	UGravityBikeFreeBoostComponent BoostComp;

	UGravityBikeFreeJumpTriggerComponent CurrentJumpTrigger;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		GravityBike = Cast<AGravityBikeFree>(Owner);
		JumpComp = UGravityBikeFreeJumpComponent::Get(GravityBike);
		BoostComp = UGravityBikeFreeBoostComponent::Get(GravityBike);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FGravityBikeFreeJumpTriggerBoostActivateParams& Params) const
	{
		auto JumpTriggerComp = GetFirstValidTrigger();
		if(JumpTriggerComp == nullptr)
			return false;

		Params.JumpTrigger = JumpTriggerComp;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!CurrentJumpTrigger.ShouldApplyBoost(GravityBike))
		{
			if(CurrentJumpTrigger.bDeactivateOnlyIfGrounded)
			{
				if(GravityBike.IsAirborne.Get())
					return false;
			}
		}

		if(GetFirstValidTrigger() == nullptr)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FGravityBikeFreeJumpTriggerBoostActivateParams Params)
	{
		CurrentJumpTrigger = Params.JumpTrigger;
		ApplyTriggerSettings(CurrentJumpTrigger);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		ClearTrigger(CurrentJumpTrigger);
		CurrentJumpTrigger = nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(HasControl())
		{
			if(!CurrentJumpTrigger.ShouldApplyBoost(GravityBike))
			{
				auto NewJumpTrigger = GetFirstValidTrigger();
				if(NewJumpTrigger != nullptr)
					CrumbSwapTrigger(CurrentJumpTrigger, NewJumpTrigger);
			}
		}
	}

	UGravityBikeFreeJumpTriggerComponent GetFirstValidTrigger() const
	{
		for(int i = 0; i < JumpComp.JumpTriggers.Num(); i++)
		{
			if(JumpComp.JumpTriggers[i].ShouldApplyBoost(GravityBike))
				return JumpComp.JumpTriggers[i];
		}

		return nullptr;
	}

	void ApplyTriggerSettings(const UGravityBikeFreeJumpTriggerComponent Trigger) const
	{
		BoostComp.ApplyForceBoost(true, this);
		UGravityBikeFreeBoostSettings::SetBoostScale(GravityBike, Trigger.BoostScale, this, EHazeSettingsPriority::Gameplay);
	}

	void ClearTrigger(const UGravityBikeFreeJumpTriggerComponent Trigger) const
	{
		BoostComp.ClearForceBoost(this);
		UGravityBikeFreeBoostSettings::ClearBoostScale(GravityBike, this);
	}

	UFUNCTION(CrumbFunction)
	void CrumbSwapTrigger(const UGravityBikeFreeJumpTriggerComponent Old, const UGravityBikeFreeJumpTriggerComponent New)
	{
		check(CurrentJumpTrigger == Old);
		ClearTrigger(Old);
		ApplyTriggerSettings(New);
	}
};