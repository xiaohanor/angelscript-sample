struct FGravityBikeSplineTriggerAppliedSetting
{
	private FGravityBikeSplineTriggerSetting Settings;
	private AGravityBikeSplineTrigger Trigger;
	private float StartTime;

	FGravityBikeSplineTriggerAppliedSetting(FGravityBikeSplineTriggerSetting InSettings, AGravityBikeSplineTrigger InTrigger)
	{
		devCheck(InSettings.ClearConditions.Num() > 0, f"{InSettings.Type} settings applied by {InTrigger} does not have any clear conditions set!");

		Settings = InSettings;
		Trigger = InTrigger;
		StartTime = Time::GameTimeSeconds;
	}

	void Apply(AGravityBikeSpline GravityBike)
	{
		switch(Settings.Type)
		{
			case EGravityBikeSplineTriggerSettingType::Boost:
			{
				auto BoostComp = UGravityBikeSplineBoostComponent::Get(GravityBike);
				BoostComp.ForceBoost.Add(Trigger);

				if(Settings.bBlockJump)
					UGravityBikeSplineJumpSettings::SetCanApplyJumpImpulse(GravityBike, false, Trigger);

				break;
			}

			case EGravityBikeSplineTriggerSettingType::Gravity:
				UMovementGravitySettings::SetGravityScale(GravityBike, Settings.Gravity, Trigger);
				break;

			case EGravityBikeSplineTriggerSettingType::MaxSpeed:
				GravityBike.MaxSpeedOverride.Apply(Settings.MaxSpeed, Trigger);
				break;

			case EGravityBikeSplineTriggerSettingType::NoTurnReferenceDelay:
				GravityBike.TurnReferenceDelayBlockers.AddUnique(Trigger);
				break;

			case EGravityBikeSplineTriggerSettingType::ForceThrottle:
				GravityBike.ForceThrottle.Add(Trigger);
				break;

			case EGravityBikeSplineTriggerSettingType::AutoAim:
				GravityBike.StartAutoAim(Settings.AutoAimSettings, Trigger, Settings.Priority);
				break;

			case EGravityBikeSplineTriggerSettingType::BlockEnemyRifleFire:
				GravityBike.BlockEnemyRifleFire.Add(Trigger);
				break;

			case EGravityBikeSplineTriggerSettingType::BlockEnemySlowRifleFire:
				GravityBike.BlockEnemySlowRifleFire.Add(Trigger);
				break;

			case EGravityBikeSplineTriggerSettingType::AutoSteer:
			{
				auto AutoSteerComp = UGravityBikeSplineAutoSteerComponent::Get(GravityBike);
				if(AutoSteerComp == nullptr)
					return;

				AutoSteerComp.Settings.Apply(Settings.AutoSteerSettings, Trigger, Settings.Priority);
				break;
			}

			case EGravityBikeSplineTriggerSettingType::BlockJump:
			{
				UGravityBikeSplineJumpSettings::SetCanApplyJumpImpulse(GravityBike, false, Trigger);
				break;
			}
		}
	}

	bool TickShouldBeCleared(const AGravityBikeSpline GravityBike, const UGravityBikeSplineTriggerComponent TriggerComp) const
	{
		if(TriggerComp.CurrentTriggers.Contains(Trigger))
		{
			// We are still in the trigger volume!
			return false;
		}

		for(auto Condition : Settings.ClearConditions)
		{
			switch(Condition)
			{
				case EGravityBikeSplineTriggerClearCondition::Duration:
				{
					if(Time::GetGameTimeSince(StartTime) > Settings.Duration)
						return true;

					break;
				}

				case EGravityBikeSplineTriggerClearCondition::OnLanding:
				{
					if(!GravityBike.IsAirborne.Get())
						return true;
					
					break;
				}

				case EGravityBikeSplineTriggerClearCondition::OnExit:
					return true;
			}
		}

		return false;
	}

	void Clear(AGravityBikeSpline GravityBike)
	{
		switch(Settings.Type)
		{
			case EGravityBikeSplineTriggerSettingType::Boost:
			{
				auto BoostComp = UGravityBikeSplineBoostComponent::Get(GravityBike);
				BoostComp.ForceBoost.Remove(Trigger);

				if(Settings.bBlockJump)
					UGravityBikeSplineJumpSettings::ClearCanApplyJumpImpulse(GravityBike, Trigger);

				break;
			}

			case EGravityBikeSplineTriggerSettingType::Gravity:
				UMovementGravitySettings::ClearGravityScale(GravityBike,  Trigger);
				break;

			case EGravityBikeSplineTriggerSettingType::MaxSpeed:
				GravityBike.MaxSpeedOverride.Clear(Trigger);
				break;

			case EGravityBikeSplineTriggerSettingType::NoTurnReferenceDelay:
				GravityBike.TurnReferenceDelayBlockers.RemoveSingleSwap(Trigger);
				break;

			case EGravityBikeSplineTriggerSettingType::ForceThrottle:
				GravityBike.ForceThrottle.Remove(Trigger);
				break;

			case EGravityBikeSplineTriggerSettingType::AutoAim:
				GravityBike.ClearAutoAim(Trigger);
				break;

			case EGravityBikeSplineTriggerSettingType::BlockEnemyRifleFire:
				GravityBike.BlockEnemyRifleFire.Remove(Trigger);
				break;

			case EGravityBikeSplineTriggerSettingType::BlockEnemySlowRifleFire:
				GravityBike.BlockEnemySlowRifleFire.Remove(Trigger);
				break;

			case EGravityBikeSplineTriggerSettingType::AutoSteer:
			{
				auto AutoSteerComp = UGravityBikeSplineAutoSteerComponent::Get(GravityBike);
				if(AutoSteerComp == nullptr)
					return;

				AutoSteerComp.Settings.Clear(Trigger);
				break;
			}

			case EGravityBikeSplineTriggerSettingType::BlockJump:
			{
				UGravityBikeSplineJumpSettings::ClearCanApplyJumpImpulse(GravityBike, Trigger);
				break;
			}
		}
	}
};